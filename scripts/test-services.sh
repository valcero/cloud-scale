#!/bin/bash
set -e

echo "============================================"
echo "  CloudScale - Service Verification"
echo "============================================"
echo ""

BASE_URL="http://localhost"

echo "--- Health Checks ---"
for svc in 3001 3002 3003 3004; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${BASE_URL}:${svc}/health/live)
  if [ "$STATUS" = "200" ]; then
    echo "  Port ${svc}: OK"
  else
    echo "  Port ${svc}: FAILED (status: ${STATUS})"
  fi
done

echo ""
echo "--- Register a test user ---"
REGISTER_RESPONSE=$(curl -s -X POST ${BASE_URL}:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@cloudscale.dev","password":"Demo123!"}')
echo "  Response: ${REGISTER_RESPONSE}"

TOKEN=$(echo $REGISTER_RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || echo "")

if [ -z "$TOKEN" ]; then
  echo ""
  echo "--- Login (user may already exist) ---"
  LOGIN_RESPONSE=$(curl -s -X POST ${BASE_URL}:3001/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"demo@cloudscale.dev","password":"Demo123!"}')
  TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null || echo "")
  echo "  Response: ${LOGIN_RESPONSE}"
fi

if [ -n "$TOKEN" ]; then
  echo ""
  echo "--- Verify token ---"
  curl -s ${BASE_URL}:3001/api/auth/verify -H "Authorization: Bearer ${TOKEN}" | python3 -m json.tool 2>/dev/null || echo "(raw response)"

  echo ""
  echo "--- Create an order ---"
  curl -s -X POST ${BASE_URL}:3002/api/orders \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d '{"items":[{"name":"Widget","qty":2,"price":14.99}],"total":29.98}' | python3 -m json.tool 2>/dev/null || echo "(raw response)"

  echo ""
  echo "--- Ingest an analytics event ---"
  curl -s -X POST ${BASE_URL}:3004/api/events \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d '{"event_type":"page_view","source":"web","payload":{"page":"/home","duration_ms":1200}}' | python3 -m json.tool 2>/dev/null || echo "(raw response)"

  echo ""
  echo "--- Get event stats ---"
  curl -s ${BASE_URL}:3004/api/events/stats \
    -H "Authorization: Bearer ${TOKEN}" | python3 -m json.tool 2>/dev/null || echo "(raw response)"
fi

echo ""
echo "--- Prometheus targets ---"
PROM_UP=$(curl -s ${BASE_URL}:9090/api/v1/targets | python3 -c "import sys,json; d=json.load(sys.stdin); print(sum(1 for t in d.get('data',{}).get('activeTargets',[]) if t['health']=='up'))" 2>/dev/null || echo "?")
echo "  Active healthy targets: ${PROM_UP}"

echo ""
echo "--- LocalStack S3 ---"
curl -s http://localhost:4566/_localstack/health | python3 -m json.tool 2>/dev/null || echo "(LocalStack not reachable)"

echo ""
echo "============================================"
echo "  Verification complete!"
echo "============================================"
