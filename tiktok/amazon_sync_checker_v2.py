import csv
import requests
import time
import re
from datetime import datetime
from bs4 import BeautifulSoup

# 配置参数
DELAY = 2  # 每个请求之间的延迟(秒)
MAX_PRICE_MULTIPLIER = 2  # 价格容忍倍数
MAX_SHIPPING_DAYS = 5     # 最大可接受发货天数

def parse_shipping_time(shipping_text):
    """解析发货时间文本，返回预计天数"""
    shipping_text = shipping_text.lower()
    
    # 匹配具体日期格式 (e.g., "Friday, July 25")
    date_match = re.search(r'([a-z]+),\s*([a-z]+)\s*(\d{1,2})', shipping_text)
    if date_match:
        try:
            month_str, day_str = date_match.group(2), date_match.group(3)
            current_year = datetime.now().year
            shipping_date = datetime.strptime(f"{month_str} {day_str} {current_year}", "%B %d %Y")
            days_diff = (shipping_date - datetime.now()).days
            return max(days_diff, 0)  # 返回非负数
        except:
            pass
    
    # 匹配相对天数 (e.g., "within 3 days")
    days_match = re.search(r'within\s+(\d+)\s+day', shipping_text)
    if days_match:
        return int(days_match.group(1))
    
    # 匹配关键词
    if 'same day' in shipping_text:
        return 0
    if 'next day' in shipping_text or 'tomorrow' in shipping_text:
        return 1
    
    return None  # 无法解析

def get_amazon_product_data(asin):
    """获取亚马逊商品数据"""
    url = f"https://www.amazon.com/dp/{asin}"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # 提取价格 - 多种选择器增强兼容性
        price_selectors = [
            'span.a-price[data-a-size="xl"] span.a-offscreen',  # 主价格
            'span.a-price.a-text-price span.a-offscreen',      # 原价
            'span.a-price span.a-offscreen',                    # 通用选择器
            '.a-price-whole'                                   # 整数部分
        ]
        
        price = None
        for selector in price_selectors:
            price_element = soup.select_one(selector)
            if price_element:
                price_text = price_element.get_text().strip()
                price_match = re.search(r'\$?([\d,]+\.\d{1,2})', price_text)
                if price_match:
                    price = float(price_match.group(1).replace(',', ''))
                    break
        
        # 检查库存 - 多种检测方式
        in_stock = False
        stock_selectors = [
            '#availability',                       # 库存状态
            '#outOfStock',                         # 缺货标识
            '.a-color-success',                     # 绿色库存状态
            '#add-to-cart-button',                 # 加入购物车按钮
            '#buy-now-button'                      # 立即购买按钮
        ]
        
        for selector in stock_selectors:
            element = soup.select_one(selector)
            if element:
                element_text = element.get_text().strip().lower()
                if 'in stock' in element_text or 'add to cart' in element_text or 'buy now' in element_text:
                    in_stock = True
                if 'currently unavailable' in element_text or 'out of stock' in element_text:
                    in_stock = False
                    break
        
        # 提取发货时间 - 多种选择器
        shipping_days = None
        shipping_selectors = [
            '#ddmDeliveryMessage',                # 发货信息
            'span[data-csa-c-delivery-time]',     # 发货时间属性
            '.a-color-success.a-text-bold',        # 绿色发货信息
            'div.delivery-block-message'           # 发货块信息
        ]
        
        for selector in shipping_selectors:
            element = soup.select_one(selector)
            if element:
                shipping_text = element.get_text().strip()
                parsed_days = parse_shipping_time(shipping_text)
                if parsed_days is not None:
                    shipping_days = parsed_days
                    break
        
        # 如果发货时间未找到，尝试在促销信息中查找
        if shipping_days is None:
            promotion_element = soup.select_one('#mir-layout-DELIVERY_BLOCK')
            if promotion_element:
                shipping_text = promotion_element.get_text().strip()
                parsed_days = parse_shipping_time(shipping_text)
                if parsed_days is not None:
                    shipping_days = parsed_days
        
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
        
        row_count = 0
        processed_count = 0
        problem_count = 0
        
        for row in reader:
            row_count += 1
            asin = row['平台sku'].strip()
            
            # 跳过无效ASIN
            if not asin or len(asin) < 5:
                print(f"跳过无效ASIN: {asin}")
                continue
            
            print(f"处理 {row_count}/{row_count} - ASIN: {asin}...")
            
            # 获取亚马逊数据
            product_data = get_amazon_product_data(asin)
            if not product_data:
                continue
                
            processed_count += 1
            time.sleep(DELAY)  # 请求延迟
            
            # 检查问题
            issues = []
            
            # 库存检查
            if not product_data['in_stock']:
                issues.append('缺货')
            
            # 价格检查
            if product_data['price'] is not None:
                local_price = float(row['本地展示价'])
                if product_data['price'] * MAX_PRICE_MULTIPLIER > local_price:
                    issues.append('价格上涨')
            else:
                issues.append('价格获取失败')
            
            # 发货时间检查
            if product_data['shipping_days'] is not None:
                if product_data['shipping_days'] > MAX_SHIPPING_DAYS:
                    issues.append('发货延迟')
            else:
                issues.append('发货时间未知')
            
            # 如果有问题，写入报告
            if issues:
                problem_count += 1
                writer.writerow({
                    'SKU ID': row['SKU ID'],
                    '店铺名称': row['店铺名称'],
                    '平台SKU': asin,
                    '问题类型': '; '.join(issues),
                    '本地价格': row['本地展示价'],
                    '亚马逊价格': product_data['price'],
                    '库存状态': '有货' if product_data['in_stock'] else '缺货',
                    '发货天数': product_data['shipping_days'] if product_data['shipping_days'] is not None else '未知'
                })
                print(f"  ! 发现问题: {', '.join(issues)}")
    
    print(f"\n处理完成! 共处理 {processed_count}/{row_count} 个产品")
    print(f"发现问题产品: {problem_count} 个")
    print(f"报告已保存至: {output_file}")

if __name__ == "__main__":
    # 配置输入输出文件
    INPUT_CSV = 'tiktok_products.csv' 
    OUTPUT_CSV = 'problem_products.csv'  # 输出文件名
    
    print("=" * 60)
    print("TikTok店铺产品监控程序")
    print(f"开始处理: {INPUT_CSV}")
    print("=" * 60)
    
    start_time = time.time()
    process_products(INPUT_CSV, OUTPUT_CSV)
    
    elapsed = time.time() - start_time
    print(f"\n总耗时: {elapsed:.2f}秒")
    print("程序执行完毕")