#!/bin/bash

printLogo()
{
  echo ""
  echo ""
  echo "  ██████╗   ██████╗   ██████╗ ██╗  ██╗ ███████╗ ████████╗"
  echo "  ██╔══██╗ ██╔═══██╗ ██╔════╝ ██║ ██╔╝ ██╔════╝ ╚══██╔══╝"
  echo "  ██████╔╝ ██║   ██║ ██║      █████╔╝  █████╗      ██║ "
  echo "  ██╔══██╗ ██║   ██║ ██║      ██╔═██╗  ██╔══╝      ██║ "
  echo "  ██║  ██║ ╚██████╔╝ ╚██████╗ ██║  ██╗ ███████╗    ██║ "
  echo "  ╚═╝  ╚═╝  ╚═════╝   ╚═════╝ ╚═╝  ╚═╝ ╚══════╝    ╚═╝ "
  echo ""
}

# Variables Initialization

# Yum output file
YUM_OUTPUT_FILE='/tmp/yum-out'
YUM_LOCK_FILE='/var/run/yum.pid'

# SSH
SSH_DIR="/home/$USER/.ssh"
SSH_KEYS_DIR="keys"

# WEBHOOKS
WEBHOOK_PORT=9000
WEBHOOKS_CONFIG_REPO="git@github.com:fedeiglesiasc/server-webhooks.git"
WEBHOOKS_CONFIG_KEY_NAME="webhooks_config"



# COLORS
red=$'\e[1;31m'
green=$'\e[1;32m'
yellow=$'\e[1;33m'
blue=$'\e[1;34m'
magenta=$'\e[1;35m'
cyan=$'\e[1;36m'
end=$'\e[0m'

working()
{
  printf "\r [ ${blue}WORKING${end} ] "
}

ok()
{
  printf "\r [ ${green}OK${end} ] "
}

error()
{
  printf "\r [ ${red}ERROR${end} ] "
}

warning()
{
  printf "\r [ ${yellow}WARNING${end} ] "
}

info()
{
  printf "\r [ ${cyan}INFO${end} ] "
}

nl()
{
  printf "                                \n"
} 


# When Yum output goes to a file
# YUM keep running in background and
# continue the execution. This function
# wait until yum process stopy running
# and then continue
waitYUM()
{
  RUNING=true
  while [ $RUNING == true ]
  do
    if pgrep -x "yum" > /dev/null
    then
      sleep 2
      RUNING=true
    else
      RUNING=false
    fi
  done
}

updateYUM() 
{
  # Update YUM
  working && printf "Updating YUM ..."
  sudo yum -y update >$YUM_OUTPUT_FILE && waitYUM
  ok && printf "YUM is updated" && nl

  # Upgrade YUM
  working && printf "Upgrading YUM ..."
  sudo yum -y upgrade >$YUM_OUTPUT_FILE && waitYUM
  ok && printf "YUM is upgraded" && nl

  #Remove orphan packages  
  working && printf "Clean orphan packages ..."
  sudo yum -y autoremove >$YUM_OUTPUT_FILE && waitYUM
  ok && printf "YUM is clean" && nl
}

installGolang()
{
  # Install Golang
  working && printf "Installing Golang ..."

  {
    # Get LTS version
    GOLANG_VERSION="`wget -qO- https://golang.org/VERSION?m=text`"
    # Move to tmp
    cd /tmp
    # Get installer
    wget https://dl.google.com/go/$GOLANG_VERSION.linux-amd64.tar.gz --quiet
    # decompress
    sudo tar -C /usr/local -xzf $GOLANG_VERSION.linux-amd64.tar.gz
    # install 
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    # remove tmp files
    rm -rf $GOLANG_VERSION.linux-amd64.tar.gz
    # move to home
    cd ~/
    # restart bash
    source ~/.bashrc

  } 2>/dev/null

  # All go ok
  ok && printf "Golang is installed" && nl
}

installWebhook()
{
  # Install Nginx
  installGit

  # Install Golang
  installGolang

  # Install Webhook
  working && printf "Installing Webhook ..."
  go get github.com/adnanh/webhook 2>/dev/null
  ok && printf "Webhook installed" && nl

  # Create directory structure
  mkdir -p ~/webhooks 2>/dev/null
  mkdir -p ~/webhooks/hooks 2>/dev/null

  # Check for port is used
  working && printf "Checking if port $WEBHOOK_PORT is used ..."
  if lsof -Pi :WEBHOOK_PORT -sTCP:LISTEN -t 2>/dev/null ;
  then
    error && printf "Port $WEBHOOK_PORT is used" && nl
  else
    ok && printf "Port $WEBHOOK_PORT is free" && nl
  fi

  #TODO ASK FOR OTHER PORT

  # Add webhook in crontab
  working && printf "Adding Webhook to UpStart ..."
  # Add service to UpStart
  sudo tee -a /etc/init/webhook.conf >/dev/null <<EOF
      description "A Webhook server to run with Github"
      author "Federico Iglesias Colombo"
      start on started sshd
      stop on runlevel [!2345]
      exec /home/$USER/go/bin/webhook -hooks /home/$USER/webhooks/main/hook.json -hooks /home/$USER/webhooks/hooks/*/hook.json -ip '127.0.0.1'
EOF

  
  {
    # Reload configuration
    sudo initctl reload-configuration

    # Start service
    sudo initctl start webhook

  } 2>/dev/null

  # All go ok
  ok && printf "Webhook added to UpStart" && nl
}

configWebhooksFromGit() 
{
  
  # Add configure startup webhook project
  working && printf "Installing Feature: Set Webhooks from Git ..."
  
  # Create directory structure
  mkdir -p ~/webhooks 2>/dev/null
  mkdir -p ~/webhooks/main 2>/dev/null
  mkdir -p ~/webhooks/hooks 2>/dev/null

  # Create main hook file
  cat > ~/webhooks/main/hook.json << EOF
    [
      {
        "id": "webhooks",
        "execute-command": "/home/$USER/webhooks/main/script.sh",
        "command-working-directory": "/home/$USER/webhooks/hooks/",
        "response-message": "Executing deploy script..."
      }
    ]
EOF

  # Create main shell script file
  cat > ~/webhooks/main/script.sh << EOF
    #!/bin/bash

    git fetch --all
    git checkout --force "origin/master"

    # give permission to all hooks scripts
    chmod +x ~/webhooks/hooks/*/script.sh

    # Restart service webhooks to get changes
EOF

  # set permission to execute file
  chmod +x ~/webhooks/main/script.sh

  # Set remote repo to hooks dir
  cd ~/webhooks/hooks && git init --quiet 2>/dev/null
  git remote add origin $WEBHOOKS_CONFIG_REPO 2>/dev/null && cd ~/ 2>/dev/null

  # All go ok
  ok && printf "Feature created: Set Webhooks from Git" && nl

  # Create SSH Keys for this feature
  createSSHKey $WEBHOOKS_CONFIG_KEY_NAME
}

createSSHKeysDir()
{
  
  # Create SSH KEY
  working && printf "Seting SSH dir structure and perms ..."
  
  {
    # if .ssh dir not exist create it 
    mkdir -p $SSH_DIR $SSH_DIR/$SSH_KEYS_DIR
    # Home directory on the server should not be writable by others
    chmod go-w /home/$USER
    # SSH folder on the server needs 700 permissions: 
    chmod 700 $SSH_DIR $SSH_DIR/$SSH_KEYS_DIR
    # Authorized_keys file needs 644 permissions: 
    chmod 644 $SSH_DIR/authorized_keys
    # Make sure that user owns the files/folders and not root: 
    chown $USER $SSH_DIR/authorized_keys
    chown $USER $SSH_DIR $SSH_DIR
    # Restart SSH service
    service ssh restart

  } 2>/dev/null

  # All go ok
  ok && printf "Set SSH dir structure and perms" && nl
}

createSSHKey()
{
  # Create SSH KEY
  working && printf "Generating SSH KEY ..."

  # create ssh key 
  yes y | ssh-keygen -f $SSH_DIR/$SSH_KEYS_DIR/id_$1 -N "" >/dev/null

  # Inform public key
  info && printf "SSH Keys created! here is your public key: " && nl

  # Show it
  cat $SSH_DIR/$SSH_KEYS_DIR/id_$1.pub

  # Reload keys
  loadAllKeys
}

SSHAutoloadKeys()
{
  # Create SSH KEY
  working && printf "Seting Autoload SSH Keys at login ..."

  # If file do not exit create
  touch ~/.bash_profile

  # Command to add
  COMMAND_TITLE="# Autoload SSH Keys (do not remove this comment)"
  COMMAND="{ [ -z \"\$SSH_AUTH_SOCK\" ] &&"
  COMMAND="$COMMAND eval \"\$(ssh-agent -s)\" && "
  COMMAND="$COMMAND for f in \$(ls $SSH_DIR/$SSH_KEYS_DIR --hide='*.pub'); do ssh-add $SSH_DIR/$SSH_KEYS_DIR/\$f; done } &>/dev/null"
  
  # If autoload not exist alredy
  if ! grep -q "$COMMAND_TITLE" ~/.bash_profile; then
    # Add title ;)
    echo -e "\n $COMMAND_TITLE" >> ~/.bash_profile
    # Add command
    echo $COMMAND >> ~/.bash_profile
  fi

  # If autoload not exist alredy
  if grep -q "Run" ~/.bash_profile; then
    echo "esta"
  fi

  # All go ok
  ok && printf "Set Autoload SSH Keys at login" && nl
}

loadAllKeys()
{
  # Start SSH Auth agent
  eval "$(ssh-agent -s)" &>/dev/null
  # Load All keys
  for f in $(ls $SSH_DIR/$SSH_KEYS_DIR --hide='*.pub'); do 
    ssh-add $SSH_DIR/$SSH_KEYS_DIR/$f &>/dev/null; 
  done
}


installGit()
{
  working && printf "Installing GIT ..."
  sudo yum -y install git >$YUM_OUTPUT_FILE && waitYUM
  ok && printf "GIT installed" && nl
}

installNginx()
{
  # Install Nginx
  working && printf "Installing Nginx ..."
  sudo yum -y install nginx >$YUM_OUTPUT_FILE && waitYUM
  # Add Nginx to startup
  sudo chkconfig nginx on 2>&1 >/dev/null
  # All go ok
  ok && printf "Nginx installed" && nl
}


installNVM()
{
  #Install LTS version of NVM
  working && printf "Installing NVM ..."
  
  # Support to get the latest version auto from source
  sudo yum -y install epel-release >$YUM_OUTPUT_FILE && waitYUM
  sudo yum -y install jq >$YUM_OUTPUT_FILE && waitYUM

  # LTS
  VER_LTS=$(curl -s 'https://api.github.com/repos/nvm-sh/nvm/releases/latest' | jq -r '.tag_name') 2>/dev/null

  # download installer
  curl -sS https://raw.githubusercontent.com/nvm-sh/nvm/$VER_LTS/install.sh > /tmp/install-nvm.sh 

  # run installer 
  bash /tmp/install-nvm.sh 2>&1 >/dev/null

  # delete install script
  rm -rf /tmp/install-nvm.sh

  # restart bash
  source ~/.bashrc

  # All go ok
  ok && printf "NVM installed" && nl
}

installNode()
{
  # Install LTS version of Node
  working && printf "Installing Node ..."

  nvm install --lts >/dev/null 2>&1

  # All go ok
  ok && printf "Node installed" && nl
}


printLogo

updateYUM

installNVM

installNode

createSSHKeysDir

SSHAutoloadKeys

installNginx

installWebhook

configWebhooksFromGit