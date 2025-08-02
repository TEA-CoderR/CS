import csv
import requests
import time
from bs4 import BeautifulSoup

# 配置参数
DELAY = 2  # 每个请求之间的延迟(秒)，避免被封IP
MAX_PRICE_MULTIPLIER = 2  # 价格容忍倍数
MAX_SHIPPING_DAYS = 5     # 最大可接受发货天数

def get_amazon_product_data(asin):
    """获取亚马逊商品数据"""
    url = f"https://www.amazon.com/dp/{asin}"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # 提取价格
        price_element = soup.select_one('span.a-price[data-a-size="xl"] span.a-offscreen')
        price = float(price_element.text.replace('$', '').replace(',', '')) if price_element else None
        
        # 检查库存
        stock_element = soup.select_one('#availability')
        in_stock = stock_element and 'in stock' in stock_element.text.lower()
        
        # 提取发货时间
        shipping_element = soup.select_one('#ddmDeliveryMessage')
        shipping_days = None
        
        if shipping_element:
            shipping_text = shipping_element.get_text().lower()
            if 'ships within' in shipping_text:
                # 尝试提取发货天数
                words = shipping_text.split()
                for i, word in enumerate(words):
                    if word.isdigit():
                        shipping_days = int(word)
                        break
        
        return {
            'price': price,
            'in_stock': in_stock,
            'shipping_days': shipping_days
        }
    except Exception as e:
        print(f"Error fetching data for ASIN {asin}: {str(e)}")
        return None

def process_products(input_file, output_file):
    """处理产品数据并生成报告"""
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', newline='', encoding='utf-8') as outfile:
        
        reader = csv.DictReader(infile)
        fieldnames = ['SKU ID', '店铺名称', '平台SKU', '问题类型', '本地价格', '亚马逊价格', '库存状态', '发货天数']
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in reader:
            asin = row['平台sku'].strip()
            local_price = float(row['本地展示价'])
            
            print(f"Processing ASIN: {asin}...")
            
            # 获取亚马逊数据
            product_data = get_amazon_product_data(asin)
            if not product_data:
                continue
                
            time.sleep(DELAY)  # 礼貌延迟
            
            # 检查问题
            issues = []
            
            # 库存检查
            if not product_data['in_stock']:
                issues.append('缺货')
            
            # 价格检查
            if product_data['price'] and product_data['price'] * MAX_PRICE_MULTIPLIER > local_price:
                issues.append('价格上涨')
            
            # 发货时间检查
            if product_data['shipping_days'] and product_data['shipping_days'] > MAX_SHIPPING_DAYS:
                issues.append('发货延迟')
            
            # 如果有问题，写入报告
            if issues:
                writer.writerow({
                    'SKU ID': row['SKU ID'],
                    '店铺名称': row['店铺名称'],
                    '平台SKU': asin,
                    '问题类型': '; '.join(issues),
                    '本地价格': local_price,
                    '亚马逊价格': product_data['price'],
                    '库存状态': '有货' if product_data['in_stock'] else '缺货',
                    '发货天数': product_data['shipping_days'] or '未知'
                })
                print(f"  ! 发现问题: {', '.join(issues)}")
    
    print(f"处理完成! 报告已保存至: {output_file}")

if __name__ == "__main__":
    # 配置输入输出文件
    INPUT_CSV = 'test.csv' 
    OUTPUT_CSV = 'problem_products.csv'  # 输出文件名
    
    process_products(INPUT_CSV, OUTPUT_CSV)