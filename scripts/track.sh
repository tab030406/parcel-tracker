#!/bin/bash
# 查詢 parcels.json 內每一筆執據號碼，把結果整理成 results.json
set -euo pipefail

INPUT="parcels.json"
OUTPUT="results.json"
API_URL="https://postserv.post.gov.tw/pstmail/EsoafDispatcher"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

tmp_results="[]"

while IFS= read -r row; do
  number=$(echo "$row" | jq -r '.number')
  label=$(echo "$row" | jq -r '.label // ""')

  payload=$(jq -n --arg mailNO "$number" '{
    header: {
      InputVOClass: "com.systex.jbranch.app.server.post.vo.EB500100InputVO",
      TxnCode: "EB500100",
      BizCode: "query2",
      StampTime: true,
      SupvPwd: "",
      TXN_DATA: {},
      SupvID: "",
      CustID: "",
      REQUEST_ID: "",
      ClientTransaction: true,
      DevMode: false,
      SectionID: "esoaf"
    },
    body: { MAILNO: $mailNO, pageCount: 10 }
  }')

  echo "查詢中：$number ($label)"

  http_status=0
  resp=$(curl -sSL -w "\n%{http_code}" \
    -H "Content-Type: application/json" \
    --data "$payload" \
    "$API_URL" || echo -e "\n000")

  http_status=$(echo "$resp" | tail -n1)
  body=$(echo "$resp" | sed '$d')

  if [ "$http_status" != "200" ]; then
    entry=$(jq -n --arg number "$number" --arg label "$label" --arg err "HTTP $http_status" \
      '{number: $number, label: $label, updated: null, events: [], error: $err}')
  else
    items=$(echo "$body" | jq -c '.[0].body.host_rs.ITEM // []')
    if echo "$items" | jq -e 'type == "object"' > /dev/null 2>&1; then
      items=$(echo "$items" | jq -c '[.]')
    fi

    events=$(echo "$items" | jq -c '[.[] | {
      time: (.DATIME // ""),
      status: (.STATUS // "" | gsub("^\\s+|\\s+$";"")),
      station: (.BRHNC // "" | gsub("^\\s+|\\s+$";""))
    }]')

    err="null"
    if [ "$(echo "$events" | jq 'length')" = "0" ]; then
      err='"查無軌跡資料，請確認號碼是否正確"'
    fi

    entry=$(jq -n --arg number "$number" --arg label "$label" --argjson events "$events" --argjson err "$err" \
      '{number: $number, label: $label, updated: (now | strftime("%Y-%m-%dT%H:%M:%SZ")), events: $events, error: $err}')
  fi

  tmp_results=$(echo "$tmp_results" | jq --argjson entry "$entry" '. + [$entry]')

  sleep 1
done < <(jq -c '.[]' "$INPUT")

jq -n --argjson parcels "$tmp_results" --arg generated "$NOW" \
  '{generated_at: $generated, parcels: $parcels}' > "$OUTPUT"

echo "完成，結果已寫入 $OUTPUT"
