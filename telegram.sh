#!/bin/bash

# Bot credentials (replace with your actual values)
token='YOUR_BOT_TOKEN'
chat_id='YOUR_CHAT_ID'
base_url="https://api.telegram.org/bot$token"

# Function to send messages
send_message() {
  local message="$1"
  local parse_mode="${2:-MarkdownV2}"
  local disable_notification="${3:-false}"

  local response=$(curl -s -X POST "$base_url/sendMessage" \
    -d chat_id="$chat_id" \
    -d text="$message" \
    -d parse_mode="$parse_mode" \
    -d disable_notification="$disable_notification")
  echo "$response" # Return the response for error handling
}

# Function to send documents
send_document() {
  local document_path="$1"
  local caption="${2:-}" # Optional caption
  curl -s -X POST "$base_url/sendDocument" \
    -F chat_id="$chat_id" \
    -F document=@"$document_path" \
    -F caption="$caption"
}

# Function to get and validate message/document from user
get_input() {
  local input=""
  while [ -z "$input" ]; do
    read -p "Enter message, document path (starting with '/'), 'q' to quit, or 's' for silent mode: " input

    case "$input" in
      s)
        read -p "Enter message to send silently: " input
        send_message "$input" "MarkdownV2" true # Send silently
        echo "Silent message sent!"
        ;;
      q)
        echo "Exiting..."
        exit 0
        ;;
      /*) # Check if it starts with a slash (likely a document path)
        if [ -f "$input" ]; then
          send_document "$input"
          echo "Document sent!"
        else
          echo "Invalid document path!"
        fi
        ;;
      *)
        echo "$input" # Return the message for normal sending
        ;;
    esac
  done
}

# Function to handle errors (expanded)
handle_error() {
  local error_response="$1"
  local error_description=$(echo "$error_response" | jq -r '.description') 
  echo "Error sending: $error_description" >&2 

  # More specific error handling examples:
  if [[ "$error_description" == *"Bad Request: wrong file identifier"* ]]; then
    echo "The document you're trying to send is invalid or inaccessible."
  fi

  # Add more specific error handling logic as needed...
}

# Main script logic
while true; do
  user_input=$(get_input)
  if [[ "$user_input" =~ ^/ ]]; then  # If input starts with '/', it's a document path
    continue # Skip sending a message, as we've already handled the document
  fi

  if ! response=$(send_message "$user_input"); then
    handle_error "$response"
  else
    echo "Message sent successfully!"
  fi
done
