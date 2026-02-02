#!/bin/bash
# discord-watcher/update.sh
# Usage: ./update.sh [token]

# 1. Try environment variable
TOKEN=${DISCORD_TOKEN}

# 2. Try argument
if [ -z "$TOKEN" ]; then
  TOKEN=$1
fi

# 3. Try to fetch from browser (if running in Clawdbot with browser access)
if [ -z "$TOKEN" ]; then
  echo "Attempting to grab token from browser..."
  
  # JS to extract token via webpack
  JS_PAYLOAD='(function(){try{var t=null;window.webpackChunkdiscord_app.push([[Math.random()],{},function(e){for(var k in e.c){var m=e.c[k].exports;if(m&&m.default&&m.default.getToken){t=m.default.getToken();break;}if(m&&m.getToken){t=m.getToken();break;}}}]);return t;}catch(e){return null;}})()'
  
  # Call browser tool via CLI
  # We use a raw JSON request to the tool to avoid quoting hell
  TOKEN_JSON=$(openclaw tool browser "{\"action\":\"act\",\"kind\":\"evaluate\",\"request\":{\"fn\":\"$JS_PAYLOAD\"}}")
  
  # Extract result value using grep/sed (simple JSON parsing)
  # Expected format: {"result": "TOKEN_STRING", ...}
  TOKEN=$(echo "$TOKEN_JSON" | grep -oP '(?<="result":")[^"]+')
  
  if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo "Success! Token found in browser."
  else
    echo "Could not find token in browser."
    echo "Debug: $TOKEN_JSON"
  fi
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "Error: DISCORD_TOKEN not found in env, args, or browser."
  exit 1
fi

# Set output directory
OUTPUT_DIR="exports/updates/$(date +%Y-%m-%d_%H-%M)"
mkdir -p "$OUTPUT_DIR"

# Get yesterday's date for "recent" updates
AFTER_DATE=$(date -d "24 hours ago" +%Y-%m-%dT%H:%M:%S)

echo "Fetching all messages since $AFTER_DATE..."

# Ensure executable
chmod +x ./dce/DiscordChatExporter.Cli

# Run exportall
./dce/DiscordChatExporter.Cli exportall \
  --token "$TOKEN" \
  --after "$AFTER_DATE" \
  --format PlainText \
  --output "$OUTPUT_DIR/%g/%C - %c.txt" \
  --parallel 1

echo "Done. Updates saved to $OUTPUT_DIR"
