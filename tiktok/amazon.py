import csv
import random
import time
from datetime import datetime, timedelta
from playwright.sync_api import sync_playwright

PROXIES = [
    # "http://username:password@proxy1.com:port",
]

def get_amazon_product_info(sku_url, proxy=None):
    with sync_playwright() as p:
        browser_args = {}
        if proxy:
            browser_args['proxy'] = {"server": proxy}
        browser = p.chromium.launch(headless=True, **browser_args)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            locale="en-US"
        )
        page = context.new_page()
        try:
            page.goto(sku_url, timeout=60000)
        except:
            browser.close()
            return {"价格": "N/A", "库存情况": "N/A", "预计到货": "N/A", "抓取失败": True}

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

def parse_price(price_str):
    if price_str in ("", None, "N/A"):
        return None
    
    try:
        return float(price_str.replace('$', '').replace(',', '').strip())
    except:
        return None

def parse_stock(stock_str):
    if stock_str in ("", None, "N/A"):
        return 0

    if stock_str.lower().startswith("only"):
        try:
            return int(stock_str.split(" ")[1])
        except:
            return 0
    elif "unavailable" in stock_str.lower():
        return 0
    return 100

def parse_eta(eta_str):
    if eta_str in ("", None, "N/A"):
        return None

    try:
        eta_date = datetime.strptime(eta_str.strip(), "%A, %B %d")
        eta_date = eta_date.replace(year=datetime.now().year)
        return eta_date
    except:
        return None

def is_problematic(item, fetched_info):
    problems = []
    if fetched_info.get("抓取失败", False):
        problems.append("抓取失败")
        return True, problems

    current_price = parse_price(fetched_info["价格"])
    local_price = parse_price(item["本地展示价"])
    stock_num = parse_stock(fetched_info["库存情况"])
    eta_date = parse_eta(fetched_info["预计到货"])
    now = datetime.now()
    late_threshold = now + timedelta(days=6)

    if stock_num < 10:
        problems.append(f"库存过低（{stock_num}）")

    if current_price and local_price:
        if current_price <= 15.99:
            if ((current_price * 1.1 + 1) * 1.5 - 5.99) * 1.1 > local_price * 0.8 + 2:
                problems.append(f"货源涨价（当前: {current_price}, 本地: {local_price}）")
        elif current_price <= 39.99:
            if ((current_price * 1.1 + 1) * 1.5 - 12.99) * 1.1 > local_price * 0.8 + 2:
                problems.append(f"货源涨价（当前: {current_price}, 本地: {local_price}）")
        else:  # current_price > 39.99
            if ((current_price * 1.1 + 1) * 1.5 - 15.99) * 1.1 > local_price * 0.8 + 2:
                problems.append(f"货源涨价（当前: {current_price}, 本地: {local_price}）")
    else:
        problems.append(f"货源价格缺失（当前: {current_price}, 本地: {local_price}）")

    if eta_date:
        if eta_date > late_threshold:
            problems.append(f"到货时间过长（{fetched_info['预计到货']}）")
    else:
        problems.append(f"货源预计到货日期缺失")
    return (len(problems) > 0), problems

def get_random_proxy():
    return random.choice(PROXIES) if PROXIES else None

def main():
    input_file = "导出#SKU_2025_07_31_17_20_52.csv"  # ← 替换CSV文件路径
    output_file = "问题sku报告.csv"
    problematic_skus = []

    with open(input_file, newline='', encoding='utf-8-sig') as csvfile:
        reader = csv.DictReader(csvfile)
        for idx, row in enumerate(reader, 1):
            platform_sku = row["平台SKU"]
            product_id = row["产品ID"]
            shop_name = row["店铺名称"]
            local_price = row["本地展示价"]
            url = f"https://www.amazon.com/dp/{platform_sku}"

            proxy = get_random_proxy()
            fetched_info = get_amazon_product_info(url, proxy)
            has_problem, reasons = is_problematic(row, fetched_info)

            # 打印状态信息
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

            time.sleep(random.uniform(3, 7))  # 随机延迟防止封IP

    if problematic_skus:
        fieldnames = list(problematic_skus[0].keys())
        with open(output_file, "w", newline='', encoding='utf-8') as outcsv:
            writer = csv.DictWriter(outcsv, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(problematic_skus)
        print(f"\n📄 已生成问题SKU报告：{output_file}")
    else:
        print("\n🎉 没有发现问题SKU。")

if __name__ == "__main__":
    main()
