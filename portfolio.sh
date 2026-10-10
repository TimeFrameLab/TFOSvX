#!/bin/bash
# ============================================================
# portfolio.sh — แสดง Portfolio จาก Bitkub wallet + ราคาล่าสุด + P/L
# Usage: ./portfolio.sh
# ============================================================
set -e

SCRIPT_DIR="$(dirname "$0")"
ENV_FILE="$SCRIPT_DIR/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ ไม่พบไฟล์ .env"
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

sign() {
  echo -n "$1" | openssl dgst -sha256 -hmac "$API_SECRET" | awk '{print $NF}'
}

TMPDIR_PF=$(mktemp -d)
trap "rm -rf $TMPDIR_PF" EXIT

# ดึง wallet balances
TS=$(curl -s "$BASE_URL/api/v3/servertime")
QUERY="?symbol=ALL"
SIGN=$(sign "${TS}GET/api/v4/wallet/balances${QUERY}")
curl -s "$BASE_URL/api/v4/wallet/balances${QUERY}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "X-BTK-APIKEY: $API_KEY" \
  -H "X-BTK-TIMESTAMP: $TS" \
  -H "X-BTK-SIGN: $SIGN" > "$TMPDIR_PF/balances.json"

# ดึง ticker ทุกคู่
curl -s "$BASE_URL/api/v3/market/ticker" > "$TMPDIR_PF/tickers.json"

# หาเหรียญที่มีใน wallet (ไม่รวม THB)
COINS=$(python3 -c "
import json
with open('$TMPDIR_PF/balances.json') as f:
    d = json.load(f)
coins = [x['currency'].lower() for x in d.get('data',[]) if x['currency'].upper() != 'THB' and float(x.get('total',0)) > 0]
print(' '.join(coins))
")

# ดึง order history ทุกเหรียญ — เก็บเป็น JSON array
echo "{}" > "$TMPDIR_PF/histories.json"
for COIN in $COINS; do
  SYM="${COIN}_thb"
  CURSOR=""
  ALL_ORDERS="[]"
  while true; do
    TS=$(curl -s "$BASE_URL/api/v3/servertime")
    if [[ -z "$CURSOR" ]]; then
      QUERY="?sym=${SYM}&lmt=100"
    else
      QUERY="?sym=${SYM}&lmt=100&cursor=${CURSOR}"
    fi
    SIGN=$(sign "${TS}GET/api/v3/market/my-order-history${QUERY}")
    RESP=$(curl -s "$BASE_URL/api/v3/market/my-order-history${QUERY}" \
      -H "X-BTK-APIKEY: $API_KEY" \
      -H "X-BTK-TIMESTAMP: $TS" \
      -H "X-BTK-SIGN: $SIGN")
    ALL_ORDERS=$(python3 -c "
import json, sys
existing = json.loads('$ALL_ORDERS'.replace(\"'\", \"'\"))
resp = json.loads(sys.stdin.read())
existing.extend(resp.get('result', []))
print(json.dumps(existing))
" <<< "$RESP")
    HAS_NEXT=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('pagination',{}).get('has_next', False))")
    if [[ "$HAS_NEXT" != "True" ]]; then break; fi
    CURSOR=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('pagination',{}).get('cursor',''))")
  done
  # บันทึก orders ของเหรียญนี้
  python3 -c "
import json
with open('$TMPDIR_PF/histories.json') as f:
    h = json.load(f)
h['${COIN}'.upper()] = json.loads('''$ALL_ORDERS''')
with open('$TMPDIR_PF/histories.json', 'w') as f:
    json.dump(h, f)
"
done

# สร้าง python script
cat > "$TMPDIR_PF/portfolio.py" << 'PYEOF'
import sys, json

with open(sys.argv[1]) as f:
    balances_raw = json.load(f)
with open(sys.argv[2]) as f:
    tickers_list = json.load(f)
with open(sys.argv[3]) as f:
    histories = json.load(f)

tickers = {t['symbol']: t for t in tickers_list if isinstance(t, dict)}
data    = balances_raw.get('data', [])

def avg_buy_price(orders, total_held):
    """คำนวณราคาซื้อเฉลี่ย (FIFO-like weighted avg จาก buy orders)"""
    buys  = [(float(o['rate']), float(o['amount']) / float(o['rate'])) for o in orders if o.get('side') == 'buy' and float(o.get('rate', 0)) > 0]
    sells = [float(o['amount']) for o in orders if o.get('side') == 'sell']
    if not buys:
        return None
    total_qty   = sum(q for _, q in buys)
    total_cost  = sum(r * q for r, q in buys)
    total_sold  = sum(sells)
    # ถ้าขายไปบางส่วน ใช้ weighted avg ทั้งหมด
    if total_qty <= 0:
        return None
    return total_cost / total_qty

rows = []
thb_total = 0.0
for item in data:
    cur   = str(item.get('currency', '')).upper()
    total = float(item.get('total', 0))
    if cur == 'THB':
        thb_total = total
        continue
    if total <= 0:
        continue
    sym    = f'{cur}_THB'
    ticker = tickers.get(sym, {})
    last   = float(ticker.get('last', 0))
    value  = total * last if last > 0 else 0

    orders   = histories.get(cur, [])
    avg_cost = avg_buy_price(orders, total)

    if avg_cost and avg_cost > 0 and last > 0:
        cost_basis = avg_cost * total
        pnl        = value - cost_basis
        pnl_pct    = (pnl / cost_basis) * 100
    else:
        avg_cost = None
        pnl      = None
        pnl_pct  = None

    rows.append((cur, total, avg_cost, last, value, pnl, pnl_pct))

rows.sort(key=lambda x: x[4], reverse=True)
total_value = sum(r[4] for r in rows) + thb_total
total_pnl   = sum(r[5] for r in rows if r[5] is not None)

print(f'## 💼 Portfolio ({len(rows)} เหรียญ)\n')
print(f'| Currency | Total | ราคาซื้อเฉลี่ย | ราคาล่าสุด | มูลค่า (THB) | กำไร/ขาดทุน | %P/L |')
print(f'|:---|---:|---:|---:|---:|---:|---:|')
for cur, total, avg_cost, last, val, pnl, pnl_pct in rows:
    avg_str  = f'{avg_cost:,.4f}'  if avg_cost else 'N/A'
    last_str = f'{last:,.4f}'      if last > 0  else 'N/A'
    val_str  = f'{val:,.2f}'       if val  > 0  else 'N/A'
    if pnl is not None:
        pnl_str  = f'+{pnl:,.2f}' if pnl >= 0 else f'{pnl:,.2f}'
        pct_str  = f'+{pnl_pct:.2f}%' if pnl_pct >= 0 else f'{pnl_pct:.2f}%'
    else:
        pnl_str = 'N/A'
        pct_str = 'N/A'
    print(f'| **{cur}** | {total:,.4f} | {avg_str} | {last_str} | {val_str} | {pnl_str} | {pct_str} |')
if thb_total > 0:
    print(f'| **THB** | {thb_total:,.2f} | — | 1.0000 | {thb_total:,.2f} | — | — |')

pnl_sign = '+' if total_pnl >= 0 else ''
print(f'\n**รวมมูลค่าพอร์ต: {total_value:,.2f} THB** | **กำไร/ขาดทุนรวม: {pnl_sign}{total_pnl:,.2f} THB**')
PYEOF

python3 "$TMPDIR_PF/portfolio.py" "$TMPDIR_PF/balances.json" "$TMPDIR_PF/tickers.json" "$TMPDIR_PF/histories.json"
