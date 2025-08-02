import csv
import random
import time
from datetime import datetime, timedelta
from playwright.sync_api import sync_playwright

# ========== 可选代理（如你启用住宅代理）==========
PROXIES = [
    # "http://username:password@proxy1.com:port"
]

# ========== 模拟设置ZIP（地区） ==========
# def set_zip_code(page, zipcode="10001"):
#     try:
#         page.goto("https://www.amazon.com/", timeout=60000, wait_until="networkidle")
#         page.click("#nav-global-location-popover-link", timeout=10000)
#         page.fill("#GLUXZipUpdateInput", zipcode, timeout=10000)
#         page.click("#GLUXZipUpdate")
#         page.wait_for_timeout(5000)
#         print(f"✅ ZIP Code 已设置为 {zipcode}")
#     except Exception as e:
#         print(f"⚠️ 设置ZIP失败: {e}")
def set_zip_code(page, zipcode="10001"):
    try:
        page.goto("https://www.amazon.com/", timeout=60000, wait_until="domcontentloaded")
        page.wait_for_selector("#nav-global-location-popover-link", timeout=15000)
        page.click("#nav-global-location-popover-link", timeout=10000)

        page.wait_for_selector("#GLUXZipUpdateInput", timeout=10000)
        page.fill("#GLUXZipUpdateInput", zipcode)
        page.click("#GLUXZipUpdate", timeout=5000)

        # 有时会弹出确认按钮
        try:
            page.wait_for_selector("input[name='glowDoneButton']", timeout=5000)
            page.click("input[name='glowDoneButton']")
        except:
            pass

        page.wait_for_timeout(5000)
        print(f"✅ ZIP Code 已设置为 {zipcode}")
    except Exception as e:
        print(f"⚠️ 设置ZIP失败: {e}")


# ========== 抓取商品信息 ==========
def get_amazon_product_info(sku_url, proxy=None):
    with sync_playwright() as p:
        browser_args = {}
        if proxy:
            browser_args['proxy'] = {"server": proxy}
        # browser = p.chromium.launch(headless=True, **browser_args)
        browser = p.chromium.launch(headless=False, slow_mo=100)

        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            locale="en-US",
            extra_http_headers={
                "Accept-Language": "en-US,en;q=0.9"
            }
        )

        page = context.new_page()

        try:
            set_zip_code(page, zipcode="10001")  # 设置地区为纽约
            page.goto(sku_url, timeout=60000, wait_until="domcontentloaded")
        except Exception as e:
            browser.close()
            return {"价格": "N/A", "库存情况": "N/A", "预计到货": "N/A", "抓取失败": True, "错误信息": str(e)}

        try:
            price = page.query_selector('span.a-price span.a-offscreen').inner_text()
        except:
            price = "N/A"

        try:
            stock = page.query_selector('#availability span').inner_text()
        except:
            stock = "N/A"

        try:
            eta = page.query_selector('#mir-layout-DELIVERY_BLOCK span.a-text-bold').inner_text()
        except:
            eta = "N/A"

        browser.close()
        return {
            "价格": price,
            "库存情况": stock,
            "预计到货": eta,
            "抓取失败": False
        }

# ========== 辅助解析 ==========
def parse_price(price_str):
    try:
        return float(price_str.replace('$', '').replace(',', '').strip())
    except:
        return None

def parse_stock(stock_str):
    if stock_str.lower().startswith("only"):
        try:
            return int(stock_str.split(" ")[1])
        except:
            return 0
    elif "unavailable" in stock_str.lower():
        return 0
    return 100

def parse_eta(eta_str):
    try:
        eta_date = datetime.strptime(eta_str.strip(), "%A, %B %d")
        eta_date = eta_date.replace(year=datetime.now().year)
        return eta_date
    except:
        return None

# ========== 判断是否问题SKU ==========
def is_problematic(item, fetched_info):
    problems = []
    if fetched_info.get("抓取失败", False):
        problems.append(f"抓取失败: {fetched_info.get('错误信息', '未知错误')}")
        return True, problems

    current_price = parse_price(fetched_info["价格"])
    local_price = parse_price(item["本地展示价"])
    stock_num = parse_stock(fetched_info["库存情况"])
    eta_date = parse_eta(fetched_info["预计到货"])
    now = datetime.now()
    late_threshold = now + timedelta(days=6)

    if !stock_num or stock_num < 10:
        problems.append(f"库存过低（{stock_num}）")
    if current_price and local_price and (current_price * 2 > local_price):
        problems.append(f"货源涨价（当前: {current_price}, 本地: {local_price}）")
    if eta_date and eta_date > late_threshold:
        problems.append(f"到货时间过长（{fetched_info['预计到货']}）")
    return len(problems) > 0, problems

# ========== 主程序 ==========
def main():
    input_file = "导出#SKU_2025_07_31_17_20_52.csv"
    output_file = "问题sku报告.csv"
    problematic_skus = []

    with open(input_file, newline='', encoding='utf-8-sig') as csvfile:
        reader = csv.DictReader(csvfile)
        print("\n📋 检测到CSV列名：", reader.fieldnames)

        required_fields = ["产品ID", "平台SKU", "店铺名称", "本地展示价"]
        for field in required_fields:
            if field not in reader.fieldnames:
                raise KeyError(f"❌ 缺少字段：'{field}'，请确认列名是否完全一致")

        for idx, row in enumerate(reader, 1):
            platform_sku = row["平台SKU"]
            product_id = row["产品ID"]
            shop_name = row["店铺名称"]
            local_price = row["本地展示价"]
            url = f"https://www.amazon.com/dp/{platform_sku}"

            proxy = random.choice(PROXIES) if PROXIES else None
            fetched_info = get_amazon_product_info(url, proxy)
            has_problem, reasons = is_problematic(row, fetched_info)

            # 打印详细抓取日志
            status = "❌ 有问题" if has_problem else "✅ 正常"
            print(f"\n[{idx}] {status} - SKU: {platform_sku}")
            if has_problem:
                print("  ➤ 原因: " + "；".join(reasons))
            print(f"  ➤ 价格: {fetched_info['价格']}")
            print(f"  ➤ 库存: {fetched_info['库存情况']}")
            print(f"  ➤ 到货: {fetched_info['预计到货']}")

            if has_problem:
                problematic_skus.append({
                    "SKU": platform_sku,
                    "产品ID": product_id,
                    "店铺名称": shop_name,
                    "价格": fetched_info["价格"],
                    "库存情况": fetched_info["库存情况"],
                    "预计到货": fetched_info["预计到货"],
                    "本地展示价": local_price,
                    "问题原因": "；".join(reasons)
                })

            time.sleep(random.uniform(3, 7))  # 避免风控

    if problematic_skus:
        with open(output_file, "w", newline='', encoding='utf-8-sig') as outcsv:
            writer = csv.DictWriter(outcsv, fieldnames=problematic_skus[0].keys())
            writer.writeheader()
            writer.writerows(problematic_skus)
        print(f"\n📄 报告已生成：{output_file}")
    else:
        print("\n✅ 没有发现问题SKU。")

if __name__ == "__main__":
    main()
