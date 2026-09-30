set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

source "$SCRIPT_DIR/lib/i18n.sh"

i18n_init

sudo bash "$SCRIPT_DIR/setup.sh"
read -r -p "$(t __press_enter)"
