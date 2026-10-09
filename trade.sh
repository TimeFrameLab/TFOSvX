#!/bin/bash
# ============================================================
# trade.sh — Bitkub Order CLI
# Usage:
#   BUY  market : ./trade.sh "BUY/BTC/L=M/1000"
#   BUY  limit  : ./trade.sh "BUY/BTC/L=2000000/1000"
#   SELL market : ./trade.sh "SELL/BTC/L=M/100%"
#   SELL limit  : ./trade.sh "SELL/BTC/L=2000000/100%"
#   Balance     : ./trade.sh "MONEY"
# ============================================================
set -e

# โหลด .env
ENV_FILE="$(dirname "$0")/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ ไม่พบไฟล์ .env"
  echo ""
  echo "� ตัวอย่างเนื้อหาในไฟล์ .env:"
  echo "# Reference Sheet URL (Google Sheets)"
  echo "REF_SHEET_URL=https://..."
  echo ""
  echo "# Bitkub API Credentials (สำหรับฟีเจอร์การซื้อขาย)"
  echo "BITKUB_API_KEY=your_api_key_here"
  echo "BITKUB_API_SECRET=your_api_secret_here"
  echo ""
  echo "�💡 กำลังสร้างไฟล์ .env จาก .env.example..."
  cp "$(dirname "$0")/.env.example" "$ENV_FILE"
  echo "✅ สร้างไฟล์ .env เรียบร้อยแล้ว"
  echo "� ไฟล์: $ENV_FILE"
  echo "�💡 กรุณาแก้ไขไฟล์ .env และใส่ค่าจริงก่อนรันใหม่"
  exit 1
fi
export $(grep -v '^#' "$ENV_FILE" | xargs)

API_KEY="${BITKUB_API_KEY}"
API_SECRET="${BITKUB_API_SECRET}"
BASE_URL="https://api.bitkub.com"

if [[ -z "$API_KEY" || -z "$API_SECRET" ]]; then
  echo "❌ กรุณาตั้งค่า BITKUB_API_KEY และ BITKUB_API_SECRET ใน .env"
  exit 1
fi

CMD="$1"
if [[ -z "$CMD" ]]; then
  echo "Usage: ./trade.sh \"BUY/BTC/L=M/1000\""
  echo "       ./trade.sh \"BUY/BTC/L=2000000/1000\""
  echo "       ./trade.sh \"SELL/BTC/L=M/100%\""
  echo "       ./trade.sh \"SELL/BTC/L=2000000/100%\""
  echo "       ./trade.sh \"MONEY\""
  exit 1
fi

# --- Signature helper ---
sign() {
  echo -n "$1" | openssl dgst -sha256 -hmac "$API_SECRET" | awk '{print $NF}'
}

# ============================================================
# MONEY — ตรวจยอดเงินบาทคงเหลือ
# ============================================================
CMD_UPPER=$(echo "$CMD" | tr '[:lower:]' '[:upper:]')
if [[ "$CMD_UPPER" == "MONEY" ]]; then
  TS=$(curl -s "$BASE_URL/api/v3/servertime")
  QUERY="?symbol=THB"
  SIGN=$(sign "${TS}GET/api/v4/wallet/balances${QUERY}")
  RESP=$(curl -s "$BASE_URL/api/v4/wallet/balances${QUERY}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-BTK-APIKEY: $API_KEY" \
    -H "X-BTK-TIMESTAMP: $TS" \
    -H "X-BTK-SIGN: $SIGN")
  echo "$RESP" | python3 -c "
import sys, json
r = json.load(sys.stdin)
data = r.get('data', r.get('result', []))
thb = next((x for x in data if x.get('currency','').upper() == 'THB'), None)
if thb:
    avail    = float(thb.get('available', 0))
    reserved = float(thb.get('reserved', 0))
    total    = float(thb.get('total', 0))
    print(f'💰 THB Balance')
    print(f'   Available : {avail:>15,.2f} THB')
    print(f'   Reserved  : {reserved:>15,.2f} THB')
    print(f'   Total     : {total:>15,.2f} THB')
else:
    print(f'❌ ไม่พบข้อมูล THB: {r}')
"
  exit 0
fi

# --- Parse BUY/SELL command ---
IFS='/' read -r SIDE COIN RATE_PART AMOUNT_PART <<< "$CMD"
SIDE=$(echo "$SIDE" | tr '[:lower:]' '[:upper:]')
COIN=$(echo "$COIN" | tr '[:lower:]' '[:upper:]')
SYM_LOWER=$(echo "$COIN" | tr '[:upper:]' '[:lower:]')_thb

RATE_VAL=$(echo "$RATE_PART" | sed 's/[Ll]=//')
if [[ "$(echo "$RATE_VAL" | tr '[:lower:]' '[:upper:]')" == "M" ]]; then
  RAT=0; TYP="market"
else
  RAT="$RATE_VAL"; TYP="limit"
fi

TIMESTAMP=$(curl -s "$BASE_URL/api/v3/servertime")

# ============================================================
# BUY
# ============================================================
if [[ "$SIDE" == "BUY" ]]; then
  AMT="$AMOUNT_PART"
  BODY="{\"sym\":\"${SYM_LOWER}\",\"amt\":${AMT},\"rat\":${RAT},\"typ\":\"${TYP}\"}"
  SIGN=$(sign "${TIMESTAMP}POST/api/v3/market/place-bid${BODY}")

  echo "📤 BUY ${COIN} | typ:${TYP} | rat:${RAT} | amt:${AMT} THB"
  RESP=$(curl -s -X POST "$BASE_URL/api/v3/market/place-bid" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-BTK-APIKEY: $API_KEY" \
    -H "X-BTK-TIMESTAMP: $TIMESTAMP" \
    -H "X-BTK-SIGN: $SIGN" \
    -d "$BODY")
  echo "$RESP" | python3 -c "
import sys, json
r = json.load(sys.stdin)
if r.get('error') == 0:
    o = r.get('result',{})
    print(f\"✅ Order placed | id:{o.get('id')} | sym:{o.get('sym')} | typ:{o.get('typ')} | rat:{o.get('rat')} | amt:{o.get('amt')} | ts:{o.get('ts')}\")
else:
    print(f\"❌ Error {r.get('error')}: {r}\")
"

# ============================================================
# SELL
# ============================================================
elif [[ "$SIDE" == "SELL" ]]; then
  PCT=$(echo "$AMOUNT_PART" | tr -d '%')
  TS2=$(curl -s "$BASE_URL/api/v3/servertime")
  QUERY="?symbol=${COIN}"
  SIGN2=$(sign "${TS2}GET/api/v4/wallet/balances${QUERY}")
  BAL_RESP=$(curl -s "$BASE_URL/api/v4/wallet/balances${QUERY}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-BTK-APIKEY: $API_KEY" \
    -H "X-BTK-TIMESTAMP: $TS2" \
    -H "X-BTK-SIGN: $SIGN2")

  AVAILABLE=$(echo "$BAL_RESP" | python3 -c "
import sys, json
r = json.load(sys.stdin)
data = r.get('data', r.get('result', []))
for x in data:
    if x.get('currency','').upper() == '${COIN}':
        print(x.get('available', 0))
        sys.exit()
print(0)
" 2>/dev/null || echo "0")

  QTY=$(python3 -c "
avail = float('${AVAILABLE}')
qty   = avail * float('${PCT}') / 100
print(f'{qty:.2f}' if qty >= 1 else f'{qty:.8f}')
")

  if [[ "$QTY" == "0" || "$QTY" == "0.00000000" ]]; then
    echo "❌ ไม่พบยอด ${COIN} ในพอร์ต หรือ balance = 0"
    exit 1
  fi

  BODY="{\"sym\":\"${SYM_LOWER}\",\"amt\":${QTY},\"rat\":${RAT},\"typ\":\"${TYP}\"}"
  TS3=$(curl -s "$BASE_URL/api/v3/servertime")
  SIGN3=$(sign "${TS3}POST/api/v3/market/place-ask${BODY}")

  echo "📤 SELL ${COIN} | typ:${TYP} | rat:${RAT} | qty:${QTY} (${PCT}% of ${AVAILABLE})"
  RESP=$(curl -s -X POST "$BASE_URL/api/v3/market/place-ask" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-BTK-APIKEY: $API_KEY" \
    -H "X-BTK-TIMESTAMP: $TS3" \
    -H "X-BTK-SIGN: $SIGN3" \
    -d "$BODY")
  echo "$RESP" | python3 -c "
import sys, json
r = json.load(sys.stdin)
if r.get('error') == 0:
    o = r.get('result',{})
    print(f\"✅ Order placed | id:{o.get('id')} | sym:{o.get('sym')} | typ:{o.get('typ')} | rat:{o.get('rat')} | amt:{o.get('amt')} | ts:{o.get('ts')}\")
else:
    print(f\"❌ Error {r.get('error')}: {r}\")
"

else
  echo "❌ ไม่รู้จักคำสั่ง: $CMD"
  exit 1
fi
