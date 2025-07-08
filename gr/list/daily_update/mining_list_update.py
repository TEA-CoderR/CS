import os
import requests
import re
from datetime import datetime
import time

# Configuration
URL = "https://minerstat.com/mining-pool-whitelist.txt"
DOMAIN_LIST_PATH = "../lists/protocols/42_Mining_domain.list"
IP_LIST_PATH = "../lists/protocols/42_Mining_ip.list"
TEMP_FILE = "minerstat_temp.txt"

def download_file():

    print(f"Downloading from {URL}...")
    start_time = time.time()
    
    try:
        response = requests.get(URL, timeout=30)
        response.raise_for_status()
        
        with open(TEMP_FILE, "w") as f:
            f.write(response.text)
            
        dl_time = time.time() - start_time
        print(f"Download completed in {dl_time:.2f}s, saved to {TEMP_FILE}")
        return True
        
    except Exception as e:
        print(f"Download failed: {str(e)}")
        return False

def process_file():
    
    domains = []  
    ips = set()   # IP deduplication
    domain_count = 0
    ip_count = 0
    skip_count = 0

    # Precompiled regular expressions improve efficiency
    ip_pattern = re.compile(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')
    
    start_time = time.time()
    
    with open(TEMP_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                skip_count += 1
                continue
                
            parts = line.split(maxsplit=1)
            if len(parts) < 2:
                skip_count += 1
                continue
                
            ip, domain = parts[0], parts[1]
            
            # IP deduplication
            if ip_pattern.match(ip):
                ips.add(f"{ip}/32")
                ip_count += 1
            
            domains.append(domain)
            domain_count += 1
    
    proc_time = time.time() - start_time
    print(f"Processed {domain_count} domains and {ip_count} IPs in {proc_time:.4f}s")
    print(f"Skipped {skip_count} invalid lines")
    
    return domains, ips

def save_lists(domains, ips):
    
    os.makedirs(os.path.dirname(DOMAIN_LIST_PATH), exist_ok=True)
    os.makedirs(os.path.dirname(IP_LIST_PATH), exist_ok=True)
    
    # Write to DOMAIN_LIST
    start_time = time.time()
    with open(DOMAIN_LIST_PATH, "w") as f:
        f.write(f"# Generated at {datetime.now().isoformat()}\n")
        f.write("\n".join(domains))
    domain_time = time.time() - start_time
    
    # Write to IP_LIST
    start_time = time.time()
    with open(IP_LIST_PATH, "w") as f:
        f.write(f"# Generated at {datetime.now().isoformat()}\n")
        f.write("\n".join(ips))
    ip_time = time.time() - start_time
    
    print(f"Saved {len(domains)} domains in {domain_time:.4f}s")
    print(f"Saved {len(ips)} IPs in {ip_time:.4f}s")

def main():
    total_start = time.time()
    print(f"Starting update at {datetime.now().isoformat()}")
    
    try:
        if not download_file():
            return
            
        domains, ips = process_file()
        save_lists(domains, ips)
        
        # Clean up TEMP_FILE
        if os.path.exists(TEMP_FILE):
            os.remove(TEMP_FILE)
        
        total_time = time.time() - total_start
        print(f"Update completed in {total_time:.2f} seconds")
        
    except Exception as e:
        print(f"Error occurred: {str(e)}")

if __name__ == "__main__":
    main()