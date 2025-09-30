#!/bin/bash
echo "上传"
git add .
git commit -m "更新$1"
git push origin main
 