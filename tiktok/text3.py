from playwright.sync_api import sync_playwright

def set_zip_code(page, zip_code="10001"):  # 默认使用纽约邮编
    try:
        # 点击配送地址入口
        page.click("#glow-ingress-block")
        page.wait_for_timeout(2000)  # 等待弹出层加载
        
        # 尝试定位并填写邮编（两种可能的界面）
        try:
            # 新界面：直接输入邮编
            page.fill("#GLUXZipUpdateInput", zip_code)
            page.click("#GLUXZipUpdate")
        except:
            # 旧界面：需要点击"配送至"再输入
            page.click("#GLUXChangePostalCodeLink")
            page.fill("#GLUXZipUpdateInput", zip_code)
            page.click("#GLUXZipUpdate")
        
        # 处理可能的地址确认页
        if page.query_selector("#a-popover-content-1"):
            page.click("#GLUXConfirmClose")
        
        # 等待地址更新完成（最多等待5秒）
        page.wait_for_timeout(5000)
        return True
    except Exception as e:
        print(f"设置邮编失败: {str(e)}")
        return False

def get_amazon_product_info(sku_url, zip_code="10001"):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            locale="en-US"
        )
        page = context.new_page()
        page.goto(sku_url, timeout=60000)
        page.wait_for_load_state("networkidle")
        
        # 设置邮编
        if not set_zip_code(page, zip_code):
            print("警告: 使用默认邮编信息")

        # 刷新页面确保显示最新信息
        page.reload()
        page.wait_for_selector("#availability", timeout=10000)

        # 价格
        try:
            price_element = page.wait_for_selector('span.a-price span.a-offscreen', timeout=5000)
            price = price_element.inner_text()
        except:
            price = "N/A"

        # 库存情况
        try:
            stock_element = page.wait_for_selector('#availability span', timeout=5000)
            stock = stock_element.inner_text()
        except:
            stock = "N/A"

        # 预计送达时间（使用更稳定的选择器）
        try:
            delivery_block = page.wait_for_selector('#deliveryBlockMessage', timeout=5000)
            eta = delivery_block.inner_text().split(":")[-1].strip()
        except:
            try:
                eta_element = page.wait_for_selector('#mir-layout-DELIVERY_BLOCK span.a-text-bold', timeout=3000)
                eta = eta_element.inner_text()
            except:
                eta = "N/A"

        browser.close()

        return {
            "价格": price,
            "库存情况": stock,
            "预计到货": eta,
            "使用邮编": zip_code
        }

if __name__ == "__main__":
    sku = "B0DPL7DK75"
    zip_code = "77845"  # 洛杉矶邮编
    url = f"https://www.amazon.com/dp/{sku}"
    info = get_amazon_product_info(url, zip_code)
    print(info)