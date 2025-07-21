#!/bin/bash

# 配置变量
SONAR_URL="http://your-sonarqube-server:9000"
TOKEN="your_api_token"
PROJECT_KEY="your_project_key"
BRANCH="main"

# 获取监管报告
echo "正在下载监管报告..."
curl -X GET "${SONAR_URL}/api/regulatory_reports/download" \
  -H "Authorization: Bearer ${TOKEN}" \
  -G \
  -d "project=${PROJECT_KEY}" \
  -d "branch=${BRANCH}" \
  --output "regulatory_report_$(date +%Y%m%d_%H%M%S).pdf"

# 获取治理报告
echo "正在下载治理报告..."
curl -X GET "${SONAR_URL}/api/governance_reports/download" \
  -H "Authorization: Bearer ${TOKEN}" \
  -G \
  -d "componentKey=${PROJECT_KEY}" \
  --output "governance_report_$(date +%Y%m%d_%H%M%S).pdf"

echo "报告下载完成！"
