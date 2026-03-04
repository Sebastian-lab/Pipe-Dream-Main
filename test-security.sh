#!/bin/bash

API_KEY="dev_weather_api_key_secure_change_me_later_2024"
BASE_URL="http://localhost:8000"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    PASS=$((PASS + 1))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    FAIL=$((FAIL + 1))
}

echo "🔐 Security Implementation Test"
echo "================================"
echo

echo "Testing API..."
echo

# Test 1: Health endpoint
echo "1. Health endpoint (no API key)..."
http_code=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/health")
if [ "$http_code" = "200" ]; then
    test_pass "Health endpoint accessible"
else
    test_fail "Health endpoint returned $http_code"
fi

# Test 2: Weather without API key
echo "2. Weather endpoint without API key..."
http_code=$(curl -s -w "%{http_code}" -o /dev/null "$BASE_URL/api/weather")
if [ "$http_code" = "401" ]; then
    test_pass "Blocked without API key"
else
    test_fail "Expected 401, got $http_code"
fi

# Test 3: Weather with wrong API key
echo "3. Weather endpoint with wrong API key..."
http_code=$(curl -s -w "%{http_code}" -o /dev/null -H "X-API-Key: wrong_key" "$BASE_URL/api/weather")
if [ "$http_code" = "403" ]; then
    test_pass "Blocked with wrong API key"
else
    test_fail "Expected 403, got $http_code"
fi

# Test 4: Weather with correct API key
echo "4. Weather endpoint with correct API key..."
http_code=$(curl -s -w "%{http_code}" -o /dev/null -H "X-API-Key: $API_KEY" "$BASE_URL/api/weather")
if [ "$http_code" = "200" ]; then
    test_pass "Accessible with correct API key"
else
    test_fail "Expected 200, got $http_code"
fi

# Test 5: Security headers
echo "5. Security headers..."
headers=$(curl -s -D - -H "X-API-Key: $API_KEY" "$BASE_URL/api/weather" -o /dev/null 2>&1)

echo "$headers" | grep -qi "x-content-type-options" && test_pass "X-Content-Type-Options" || test_fail "X-Content-Type-Options"
echo "$headers" | grep -qi "x-frame-options" && test_pass "X-Frame-Options" || test_fail "X-Frame-Options"
echo "$headers" | grep -qi "x-xss-protection" && test_pass "X-XSS-Protection" || test_fail "X-XSS-Protection"
echo "$headers" | grep -qi "referrer-policy" && test_pass "Referrer-Policy" || test_fail "Referrer-Policy"

# Test 6: CORS
echo "6. CORS configuration..."
http_code=$(curl -s -w "%{http_code}" -o /dev/null -H "Origin: http://localhost:5173" -H "X-API-Key: $API_KEY" -H "Access-Control-Request-Method: GET" -X OPTIONS "$BASE_URL/api/weather")
if [ "$http_code" = "200" ]; then
    test_pass "CORS preflight"
else
    test_fail "CORS preflight got $http_code"
fi

# Test 7: Method restrictions
echo "7. HTTP method restrictions..."
http_code=$(curl -s -w "%{http_code}" -o /dev/null -X POST -H "X-API-Key: $API_KEY" "$BASE_URL/api/weather")
if [ "$http_code" = "405" ] || [ "$http_code" = "422" ]; then
    test_pass "POST blocked"
else
    test_fail "POST should be blocked, got $http_code"
fi

echo
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
echo "================================"
echo

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "${RED}❌ TESTS FAILED${NC}"
    exit 1
fi
