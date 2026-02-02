#!/bin/bash
# discord-watcher/update.sh
# Usage: ./update.sh [token] [--period "24 hours ago"] [extra_exporter_flags...]

TOKEN=${DISCORD_TOKEN}
PERIOD="24 hours ago"
EXTRA_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --period)
      PERIOD="$2"
      shift 2
      ;;
    --token)
      TOKEN="$2"
      shift 2
      ;;
    -*)
      EXTRA_ARGS+=("$1")
      shift
      ;;
    *)
      if [ -z "$TOKEN" ]; then
        TOKEN="$1"
      else
        EXTRA_ARGS+=("$1")
      fi
      shift
      ;;
  esac
done

# Try to fetch from browser if still missing
if [ -z "$TOKEN" ]; then
  echo "Attempting to grab token from browser..."
  JS_PAYLOAD='(function(){try{var t=null;window.webpackChunkdiscord_app.push([[Math.random()],{},function(e){for(var k in e.c){var m=e.c[k].exports;if(m&&m.default&&m.default.getToken){t=m.default.getToken();break;}if(m&&m.getToken){t=m.getToken();break;}}}]);return t;}catch(e){return null;}})()'
  TOKEN_JSON=$(openclaw tool browser "{\"action\":\"act\",\"kind\":\"evaluate\",\"request\":{\"fn\":\"$JS_PAYLOAD\"}}")
  TOKEN=$(echo "$TOKEN_JSON" | grep -oP '(?<="result":")[^"]+')
  
  if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo "Success! Token found in browser."
  else
    echo "Could not find token in browser."
  fi
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "Error: DISCORD_TOKEN not found."
  echo "Usage: $0 [token] [--period \"24 hours ago\"] [extra_exporter_flags...]"
  exit 1
fi

# Set output directory
TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
OUTPUT_DIR="exports/updates/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"

# Calculate --after date
AFTER_DATE=$(date -d "$PERIOD" +%Y-%m-%dT%H:%M:%S)
echo "Fetching messages since $AFTER_DATE ($PERIOD)..."
echo "Extra flags: ${EXTRA_ARGS[@]}"

# Ensure executable
chmod +x ./dce/DiscordChatExporter.Cli

# Run exportall
./dce/DiscordChatExporter.Cli exportall \
  --token "$TOKEN" \
  --after "$AFTER_DATE" \
  --format PlainText \
  --output "$OUTPUT_DIR/%g/%C - %c.txt" \
  --parallel 1 \
  "${EXTRA_ARGS[@]}"

echo "Done. Updates saved to $OUTPUT_DIR"
