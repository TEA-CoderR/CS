from playwright.sync_api import sync_playwright

def get_amazon_product_info(sku_url):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        # browser = p.chromium.launch(headless=False, slow_mo=100)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)...",
            locale="en-US"
        )
        page = context.new_page()
        page.goto(sku_url, timeout=60000)

        # 价格
        try:
            price = page.query_selector('span.a-price span.a-offscreen').inner_text()
        except:
            price = "N/A"

        # # 打折价格
        # try:
        #     deal_price = page.query_selector('#priceblock_dealprice').inner_text()
        # except:
        #     deal_price = None

        # 库存情况
        try:
            stock = page.query_selector('#availability span').inner_text()
        except:
            stock = "N/A"

        # 预计送达时间（不是所有商品都有）
        try:
            eta = page.query_selector('#mir-layout-DELIVERY_BLOCK span.a-text-bold').inner_text()
        except:
            eta = "N/A"

        browser.close()

        return {
            "价格": price,
            # "折扣价": deal_price,
            "库存情况": stock,
            "预计到货": eta
        }

if __name__ == "__main__":
    sku = "B0BVQXZC26"
    url = f"https://www.amazon.com/dp/{sku}"
    info = get_amazon_product_info(url)
    print(info)
