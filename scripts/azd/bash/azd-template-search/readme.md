# azd-template-search.sh

Scrollable interactive Azure Developer CLI (`azd`) template selector (with arrow key support).

This script is designed to help you select an azd template interactively.
It uses the Azure Developer CLI (azd) to list available templates, and allows you to filter them by keyword or tag.

**Examples:**

```bash
./azd-template-search.sh -q litellm
./azd-template-search.sh -t mcp
./azd-template-search.sh -t ai,mcp
```

## Download Script

```bash
```

## Dependencies

This is a Bash / shell script that will work on macOS, Linux, or WSL. You will need to have the following installed to use this script:

- Azure Developer CLI
- `jq`
- `fzf`

## Usage

```text
# Usage:
# ./azd-template-search.sh [-q query] [-t tag]
#
# Options:
# -q   Filter templates by keyword (e.g., python, ai, bicep)
# -t   Filter templates by tag (e.g., bicep, webapps, ai)
```
