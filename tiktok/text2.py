from playwright.sync_api import sync_playwright

def get_amazon_product_info(sku_url, zip_code="10001"):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)...",
            locale="en-US"
        )
        page = context.new_page()
        page.goto(sku_url, timeout=60000)

        # 点击“Deliver to”按钮（右上角小地图图标）
        try:
            page.click("#nav-global-location-popover-link", timeout=5000)
            page.wait_for_selector("input#GLUXZipUpdateInput", timeout=5000)

            # 输入邮编
            page.fill("input#GLUXZipUpdateInput", zip_code)
            page.click("input#GLUXZipUpdate")  # 点击“Apply”
            page.wait_for_timeout(3000)  # 等待弹窗刷新
            page.reload()  # 重新加载页面
        except Exception as e:
            print("无法设置邮编，跳过。", e)

        # 获取价格
        try:
            price = page.locator("span.a-price span.a-offscreen").first.inner_text()
        except:
            price = "N/A"

        # 库存情况
        try:
            stock = page.query_selector('#availability span').inner_text()
        except:
            stock = "N/A"

        # 获取预计送达时间
        try:
            eta = page.locator("#mir-layout-DELIVERY_BLOCK span.a-text-bold").first.inner_text()
        except:
            eta = "N/A"

        browser.close()

        return {
            "价格": price,
            "库存": stock,
            "预计到货": eta,
        }

if __name__ == "__main__":
    url = "https://www.amazon.com/dp/B0DPL7DK75"
    info = get_amazon_product_info(url, zip_code="77845")  # 例如旧金山的邮编
    print(info)
