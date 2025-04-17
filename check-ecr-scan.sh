#!/bin/bash

set -e

ECR_REPO=$1
IMAGE_TAG=$2
REGION=$3

echo "🕵️ Starting ECR Vulnerability Scan Check for: $ECR_REPO:$IMAGE_TAG ($REGION)"

aws ecr wait image-scan-complete \
    --region "$REGION" \
    --repository-name "$ECR_REPO" \
    --image-id imageTag="$IMAGE_TAG"

echo "✅ Scan completed. Fetching findings..."

SCAN_FINDINGS=$(aws ecr describe-image-scan-findings \
    --region "$REGION" \
    --repository-name "$ECR_REPO" \
    --image-id imageTag="$IMAGE_TAG" | jq '.imageScanFindings.findingSeverityCounts')

CRITICAL=$(echo "$SCAN_FINDINGS" | jq '.CRITICAL // 0')
HIGH=$(echo "$SCAN_FINDINGS" | jq '.HIGH // 0')

echo "=== Vulnerabilities Summary ==="
echo "CRITICAL: $CRITICAL"
echo "HIGH: $HIGH"
echo "==============================="

if [[ "$CRITICAL" -gt 0 ]]; then
  echo "❌ Image has $CRITICAL CRITICAL vulnerabilities! Failing pipeline."
  exit 1
fi

if [[ "$HIGH" -gt 30 ]]; then
  echo "❌ Image has more than 30 HIGH vulnerabilities ($HIGH found). Failing pipeline."
  exit 1
fi

echo "🎉 Image passed vulnerability check."

