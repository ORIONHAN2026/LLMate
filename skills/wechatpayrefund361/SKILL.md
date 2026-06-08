---
name: wechatpayrefund361
description: This skill should be used when the user wants to process WeChat Pay
  refunds using API v3 with the official wechatpayv3 Python SDK. It handles
  refund requests based on merchant order numbers with specified refund amounts.
disable: true
---

# WeChat Pay Refund (API v3 + wechatpayv3 SDK)

## Overview

This skill enables automated WeChat Pay refund processing using **API v3** with the official [wechatpayv3](https://github.com/minibear2021/wechatpayv3) Python SDK.

## Prerequisites

```bash
pip install wechatpayv3
```

## 退款订单格式
样例如下：
1020260402019706182801010471	11.00 

前面的是out_trade_no，后面的金额是退款金额也是订单金额，单位为元，后面调用退款时候要转化为分后传入函数的参数里

## 退款函数

调用脚本函数 `refund(out_trade_no,amount, reason)` 来执行退款，其中 out_trade_no 是订单号，amount 是退款金额，reason 是退款原因



## 执行规则

根据对话框中的订单和退款进行，直接执行退款脚本wechat_refund.py，不要创建任何中间脚本。按照订单号逐个执行，并打印成功或者失败原因，直到所有订单都执行完成。
