#!/bin/bash

# #####################################################################
# # azd-template-search.sh
# # Scrollable interactive azd template selector (with arrow key support)
# #
# # Dependencies
# # - azd
# # - jq
# # - fzf
# #
# # This script is designed to help you select an azd template interactively.
# # It uses the Azure Developer CLI (azd) to list available templates,
# # and allows you to filter them by keyword or tag.
# #
# # Usage:
# # ./azd-template-search.sh [-q query] [-t tag]
# #
# # Options:
# # -q   Filter templates by keyword (e.g., python, ai, bicep)
# # -t   Filter templates by tag (e.g., bicep, webapps, ai)
# #
# # Example:
# # ./azd-template-search.sh -q python
# # ./azd-template-search.sh -t webapps
# #
# # Copyright (c) 2025 Build5Nines LLC
# # Licensed under the MIT License.
# # 
# # https://build5nines.com
# # Written by Chris Pietschmann
# #####################################################################

# Emoji & Style utilities
green_check="✅"
search="🔍"
spark="✨"
handshake="🤝"
red_x="❌"

bold=$(tput bold)
normal=$(tput sgr0)

cyan='\033[0;36m'
yellow='\033[0;33m'
magenta='\033[0;35m'
green='\033[0;32m'
reset='\033[0m'

# Print header
echo -e "${green}${bold}${spark} AZD Template Init Helper Script (azd-template-search.sh)${reset}"
echo -e "${cyan}Scrollable interactive azd template selector (with arrow key support)"
echo -e "${cyan}Written by Chris Pietschmann (https://build5nines.com)${reset}"
echo -e "${cyan}---------------------------------------------------------------${reset}"
echo ""

# Check for required tools
command -v azd >/dev/null 2>&1 || { echo >&2 "${bold}Error:${normal} Azure Developer CLI (azd) is not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "${bold}Error:${normal} jq is required but not installed."; exit 1; }
command -v fzf >/dev/null 2>&1 || { echo >&2 "${bold}Error:${normal} fzf is required but not installed. Please install it: https://github.com/junegunn/fzf"; exit 1; }

# Function to display usage
usage() {
  echo "Usage: $0 [-q query] [-t tag]"
  echo "  -q / --query  Filter templates by keyword or tag (e.g., python, ai, bicep)"
  echo "  -t / --tag    Filter templates by tag, comma-separated for multiple (e.g., bicep, webapps, ai)"
  echo "  -h / --help   Show this help message"
  echo ""
  exit 1
}

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -q|--query)
      query="$2"
      shift 2
      ;;
    -t|--tag)
      tag="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

if [ -z "$query" ] && [ -z "$tag" ]; then
    echo -e "${cyan}It looks like you didn't provide a keyword or tag to search for azd templates.${reset}"

    options=("Show All" "Keyword" "Tag")
    selected_option=$(printf '%s\n' "${options[@]}" | fzf --height 8 --border --ansi --prompt=">" --header="What do you want to search by? [Use arrows to move, type to filter]")
    
    # Set query or tag based on selection
    if [ "$selected_option" == "Keyword" ]; then
        echo -e "${yellow}Search Mode  :${reset} ${search_mode:-Keyword}${reset}"
        read -rp "Enter a keyword to search for azd templates: " query

        echo -e "${yellow}Selected Keyword: ${reset}${query}"

    elif [ "$selected_option" == "Tag" ]; then
        echo -e "${yellow}Search Mode  :${reset} ${search_mode:-Tag}${reset}"
        echo -e "${magenta}${search} Loading tags..."
        #read -rp "Enter a tag to search for azd templates: " tag
        tags=$(azd template list --output json | jq -r '.[].tags[]?' | sort -u)
        # Prompt tag selection using fzf
        tag=$(printf '%s\n' "${tags[@]}" | fzf --height 12 --border --ansi --prompt=">" --header="Select a tag: [Use arrows to move, type to filter]")

        echo -e "${yellow}Selected Tag: ${reset}${tag}"

    else
        echo -e "${yellow}Search Mode  :${reset} ${search_mode:-All}${reset}"
        # default show all
        query=""
        tag=""
    fi
fi


# Load all templates
echo -e "${magenta}${search} Loading azd templates...${reset}"
if [ -z "$tag" ]; then
  all_templates=$(azd template list --output json)    
else
  all_templates=$(azd template list -f "$tag" --output json)
fi

count=$(echo "$all_templates" | jq 'length')
if [ "$count" -eq 0 ]; then
  echo -e "${red}${red_x} No templates found for the specified tag '$tag'.${reset}"
  exit 0
fi

# Filter templates using jq
filtered=$(echo "$all_templates" | jq -r --arg q "$query" '
  [ .[] | select(
      (.name | test($q; "i")) or
      (.description | test($q; "i")) or
      (.tags[]? | test($q; "i"))
    ) ]')

# Check if anything matched
count=$(echo "$filtered" | jq 'length')
if [ "$count" -eq 0 ]; then
  echo -e "${red}${red_x} No templates found matching '$query'.${reset}"
  exit 0
fi

# Display options using fzf for interactive selection
selected_template=$(echo "$filtered" | jq -r '.[] | "\(.repositoryPath) - \(.name)"' | fzf --height 13 --border --ansi --prompt=">" --header="Select a template: [Use arrows to move, type to filter]")

# Validate selection
if [ -z "$selected_template" ]; then
  echo -e "${red}${red_x} No template selected.${reset}"
  exit 1
fi

# Extract the template name from the selected line
repository_path=$(echo "$selected_template" | awk -F' - ' '{print $1}')
#template_name=$(echo "$selected_template" | awk -F' - ' '{print $2}')

selected_template=$(echo "$filtered" | jq -r --arg selected "$repository_path" '.[] | select(.repositoryPath == $selected)')
template_name=$(echo "$selected_template" | jq -r '.name')
template_description=$(echo "$selected_template" | jq -r '.description')

echo -e "${cyan}---------------------------------------------------------------${reset}"
echo -e "${green}${green_check} Template Selected${reset}"
echo -e "${magenta}GitHub Repo    :${reset} $repository_path (https://github.com/${repository_path})"
echo -e "${magenta}Name           :${reset} $template_name"
echo -e "${magenta}Description    :${reset} $template_description"
echo -e "${cyan}---------------------------------------------------------------${reset}"

# ask if they want to initialize the template
echo ""
echo -e "${yellow}Do you want to initialize the template? (Y/n)${reset}"
read -r -p "[Y/n]: " response
if [ -z "$response" ]; then
  response="n"
fi
# lowercase the response
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
if [[ "$response" =~ ^(yes|y| ) ]]; then

  echo -e "${green}🚀 Initializing template...${reset}"
  azd init --template "$repository_path"

else

  echo -e "${green}You can initialize the template later using:${reset}"
  echo -e ""
  echo -e "azd init --template $repository_path"

fi

echo ""
echo -e "${cyan}---------------------------------------------------------------${reset}"
echo -e "$spark Thank you $handshake for using azd-template-search.sh to help you initialize your azd template! $spark"
echo -e "${cyan}---------------------------------------------------------------${reset}"
