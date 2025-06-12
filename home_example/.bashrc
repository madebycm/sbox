# @author madebycm (2025)
# Enable bash completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Load custom inputrc
export INPUTRC=/home/sBOX/.inputrc

# Aliases
alias 'p'='ping majn.com'
