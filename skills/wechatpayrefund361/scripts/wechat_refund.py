#!/usr/bin/env python3
"""
WeChat Pay Refund Utility using wechatpayv3 SDK
Process refunds based on transaction IDs or merchant order numbers
"""

import json
import sys
from pathlib import Path

# Check if wechatpayv3 is installed
try:
    from wechatpayv3 import WeChatPay, WeChatPayType
except ImportError:
    print("Error: wechatpayv3 SDK is not installed.")
    print("Please install it with: pip install wechatpayv3")
    sys.exit(1)

# Merchant Configuration - Replace with your own credentials
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
cert_dir = os.path.join(script_dir, "1724427361_20250808_cert")

# Read private key content from file
with open(os.path.join(cert_dir, "apiclient_key.pem"), 'r') as f:
    PRIVATE_KEY = f.read()

MCHID = "1724427361"                    # Merchant ID
# PRIVATE_KEY is already set above (private key content as string)
CERT_SERIAL_NO = "42C12E90C8801CE0EAC847C4E74D22EFFA9D4CC6"          # Certificate serial number
APIV3_KEY = "5ccb7JKD89idyb66ekLL0h34bb5mmnn7"               # API v3 key
APPID = "wxd473eed19a07a13c"                    # Application ID
CERT_DIR = cert_dir                # Certificate cache directory

def init_wechat_pay():
    """Initialize WeChat Pay client"""
    wxpay = WeChatPay(
        wechatpay_type=WeChatPayType.NATIVE,
        mchid=MCHID,
        private_key=PRIVATE_KEY,
        cert_serial_no=CERT_SERIAL_NO,
        apiv3_key=APIV3_KEY,
        appid=APPID,
        cert_dir=CERT_DIR if CERT_DIR else None
    )
    return wxpay

def refund(out_trade_no, amount, reason=None):
    """
    Process WeChat Pay refund using wechatpayv3 SDK

    Args:
        out_trade_no: Merchant order number
        amount: Refund amount in fen (also used as total amount for full refund)
        reason: Refund reason (optional)

    Returns:
        Dictionary with refund result
    """
    if not out_trade_no:
        raise ValueError("out_trade_no must be provided")

    from datetime import datetime
    import random
    import string
    timestamp_str = datetime.now().strftime('%Y%m%d%H%M%S')
    out_refund_no = f"R{timestamp_str}{''.join(random.choice(string.ascii_letters + string.digits) for _ in range(8))}"

    wxpay = init_wechat_pay()

    code, message = wxpay.refund(
        out_trade_no=out_trade_no,
        out_refund_no=out_refund_no,
        amount={
            "refund": amount,
            "total": amount,
            "currency": "CNY"
        },
        reason=reason
    )

    if code == 200:
        return {"success": True, "data": message}
    else:
        return {"success": False, "error": message}

def query_refund(out_refund_no):
    """
    Query refund status

    Args:
        out_refund_no: Merchant refund order number

    Returns:
        Dictionary with refund status
    """
    wxpay = init_wechat_pay()
    code, message = wxpay.query_refund(out_refund_no=out_refund_no)

    if code == 200:
        return {"success": True, "data": message}
    else:
        return {"success": False, "error": message}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ["--help", "-h"]:
        print("WeChat Pay Refund Tool")
        print("Usage: python wechat_refund.py <command> [args]")
        print("Commands:")
        print("  refund <out_trade_no> <amount>")
        print("  query <out_refund_no>")
        sys.exit(0)

    command = sys.argv[1]

    if command == "refund":
        if len(sys.argv) < 4:
            print("Usage: python wechat_refund.py refund <out_trade_no> <amount>")
            sys.exit(1)

        out_trade_no = sys.argv[2]
        amount = int(sys.argv[3])
        reason = sys.argv[4] if len(sys.argv) > 4 else None

        print(f"Processing refund...")
        result = refund(
            out_trade_no=out_trade_no,
            amount=amount,
            reason=reason
        )
        print(json.dumps(result, indent=2, ensure_ascii=False))

    elif command == "query":
        if len(sys.argv) < 3:
            print("Usage: python wechat_refund.py query <out_refund_no>")
            sys.exit(1)

        out_refund_no = sys.argv[2]
        result = query_refund(out_refund_no)
        print(json.dumps(result, indent=2, ensure_ascii=False))

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
