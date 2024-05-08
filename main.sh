if [[ -n $ZSH_NAME ]]; then
  source "${0:A:h}/prompt.sh"
else
  source "$(dirname ${BASH_SOURCE[0]})/colors.sh"
  source "$(dirname ${BASH_SOURCE[0]})/prompt.sh"
fi
