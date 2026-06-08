#!/usr/bin/env python3
"""
Get certificate information from WeChat Pay certificates
"""

import os
from cryptography import x509
from cryptography.hazmat.backends import default_backend

script_dir = os.path.dirname(os.path.abspath(__file__))
cert_dir = os.path.join(script_dir, "1723934636_20250807_cert")

cert_path = os.path.join(cert_dir, "apiclient_cert.pem")
key_path = os.path.join(cert_dir, "apiclient_key.pem")

print("🔍 检查证书信息...")
print()

# Check if files exist
print("📁 文件检查:")
print(f"证书文件: {cert_path}")
print(f"存在: {'✅ 是' if os.path.exists(cert_path) else '❌ 否'}")
print(f"私钥文件: {key_path}")
print(f"存在: {'✅ 是' if os.path.exists(key_path) else '❌ 否'}")
print()

try:
    # Read and parse certificate
    with open(cert_path, 'rb') as f:
        cert_data = f.read()
    
    cert = x509.load_pem_x509_certificate(cert_data, default_backend())
    
    print("📄 证书信息:")
    print(f"序列号: {cert.serial_number}")
    print(f"序列号(十六进制): {hex(cert.serial_number).upper().replace('0X', '').upper()}")
    print(f"颁发者: {cert.issuer.rfc4514_string()}")
    print(f"主体: {cert.subject.rfc4514_string()}")
    print(f"有效期从: {cert.not_valid_before}")
    print(f"有效期至: {cert.not_valid_after}")
    
    # 检查证书是否在有效期内
    import datetime
    now = datetime.datetime.now()
    if cert.not_valid_before <= now <= cert.not_valid_after:
        print(f"证书状态: ✅ 有效期内")
    else:
        print(f"证书状态: ⚠️ 有效期外")
        
    print()
    print("🔑 关于序列号:")
    print("微信支付API v3要求使用证书序列号进行签名验证。")
    print("序列号通常是一个40位的十六进制字符串。")
    print(f"当前脚本中配置的序列号: 1D75C6CBF969878753DC2595E6C1DA049AD34EFE")
    print(f"从证书中读取的序列号: {hex(cert.serial_number).upper().replace('0X', '').upper()}")
    
except Exception as e:
    print(f"❌ 读取证书时出错: {e}")
    import traceback
    traceback.print_exc()

print()
print("📝 提示:")
print("如果序列号不匹配，需要更新脚本中的CERT_SERIAL_NO变量")
print("使用从证书中读取的十六进制序列号")