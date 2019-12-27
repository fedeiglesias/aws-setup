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

#serverx
SERVER_NAME='bambu'
MAIN_DOMAIN='fedeiglesias.com'

# git
GIT_USERNAME=$SERVER_NAME
GIT_EMAIL="server@${MAIN_DOMAIN}"

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

# NGINX Config repo
NGINX_CONFIG_REPO="git@github.com:fedeiglesiasc/server-nginx.git"
NGINX_CONFIG_KEY_NAME="nginx_config"

#SSL CERTIFICATES
SSL_CERTIFICATES_DIR="/home/$USER/.ssl_certificates"


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

todo()
{
  printf "\r [ ${magenta}TODO${end} ] "
}

nl()
{
  printf "                                \n"
}

pause() 
{
  read -p '' PAUSE
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
    # GOLANG_VERSION="`wget -qO- https://golang.org/VERSION?m=text`"
    # Webhook have problems with Golang go1.13.5
    GOLANG_VERSION="go1.12.14"

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

 # Create hook structure
 configWebhooksFromGit

 # Add Webhook to Upstart
 addWebhookToUpstart

 # Create conf for Nginx
 createNginxConfMainDomain
}

addWebhookToUpstart()
{
 # Add webhook in crontab
  working && printf "Adding Webhook to UpStart ..."
  # Add service to UpStart
  sudo tee -a /etc/init/webhook.conf >/dev/null <<EOF
description "A Webhook server to run with Github"
author "Federico Iglesias Colombo"
start on started sshd
stop on runlevel [!2345]
exec sudo -u $USER /home/$USER/go/bin/webhook -verbose -urlprefix "" -hooks /home/$USER/webhooks/main/hook.json -hooks /home/$USER/webhooks/hooks/*/hook.json -ip '127.0.0.1' 2>&1 >> /var/log/webhook.log 
EOF
 
  # Wait for conf file.
  sleep 2

  # Reload configuration
  sudo initctl reload-configuration --quiet

  # prueba
  sleep 5

  # Start service
  sudo initctl start --quiet webhook

  # All go ok
  ok && printf "Webhook added to UpStart" && nl
}


createNginxConfMainDomain()
{

  # Add proxypass to Nginx
  working && printf "Create Nginx conf for '$MAIN_DOMAIN'..."
  sudo tee -a /etc/nginx/conf.d/$MAIN_DOMAIN.conf >/dev/null <<EOF
server {
  listen 80;
  listen [::]:80;
  server_name $MAIN_DOMAIN;

  location /hooks/ {
      proxy_pass http://127.0.0.1:$WEBHOOK_PORT;
  }
}

server {
  listen 80;
  listen [::]:80;
  server_name webhook.$MAIN_DOMAIN;

  location / {
      proxy_pass http://127.0.0.1:$WEBHOOK_PORT;
  }
}

server {
  listen 80;
  server_name jenkins.$MAIN_DOMAIN;

  location / {
    proxy_pass http://127.0.0.1:8080;
  }
}
EOF


  # Relad Nginx config
  sudo nginx -s reload

  ok && printf "Nginx conf for '$MAIN_DOMAIN' created" && nl
}

configWebhooksFromGit() 
{
  
  # Add configure startup webhook project
  working && printf "Installing Feature: Set Webhooks from Git ..."
  
  # Create directory structure
  mkdir -p ~/webhooks 2>/dev/null
  mkdir -p ~/webhooks/main 2>/dev/null
  mkdir -p ~/webhooks/hooks 2>/dev/null
  mkdir -p ~/webhooks/tmp 2>/dev/null

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
  createSSHKey $WEBHOOKS_CONFIG_KEY_NAME 1
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

  # Add github to know hosts
  ssh-keyscan github.com >> ~/.ssh/known_hosts

  # All go ok
  ok && printf "Set SSH dir structure and perms" && nl
}


createSSHKey()
{
  # MODE:
  # 0: dont show anything
  # 1: show process status
  # 2: show process status & created key
  MODE=0
  if [ -n "$2" ]; then 
    MODE=$2
  fi

  # Create SSH KEY
  if [ $MODE = 1 ] || [ $MODE = 2 ]; then
    working && printf "Generating SSH KEY ..."
  fi

  # create ssh key 
  yes y | ssh-keygen -f $SSH_DIR/$SSH_KEYS_DIR/id_$1 -N "" >/dev/null

  # Show it
  if [ $MODE = 2 ]; then
    # Inform public key
    info && printf "SSH Keys created! here is your public key: " && nl
    cat $SSH_DIR/$SSH_KEYS_DIR/id_$1.pub
  fi

  if [ $MODE = 1 ] || [ $MODE = 2 ]; then
    ok && printf "SSH Keys created" && nl
  fi

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
  
  # Install GIT
  sudo yum -y install git >$YUM_OUTPUT_FILE && waitYUM
  
  # Basic config
  git config --global user.name $GIT_USERNAME
  git config --global user.email $GIT_EMAIL
  
  ok && printf "GIT installed" && nl
}

installNginx()
{
  # Install Nginx
  working && printf "Installing Nginx ..."
  sudo yum -y install nginx >$YUM_OUTPUT_FILE && waitYUM
  # Add Nginx to startup
  sudo chkconfig nginx on 2>&1 >/dev/null
  # Start Server
  sudo service nginx start 2>&1 >/dev/null
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

installAcme()
{
  working && printf "Installing Acme ..."

  git clone -q https://github.com/Neilpang/acme.sh.git
  
  cd acme.sh && ./acme.sh --install >/dev/null 2>&1
  cd ~ && rm -rf acme.sh
  source ~/.bashrc

  # Create directory for installed ssl certificates
  mkdir $SSL_CERTIFICATES_DIR

  ok && printf "Acme installed" && nl
}

setAWSCredentials()
{

  # TODO: Check if have credentials aready set.

  # Ask data to user
  read -p 'AWS Access key ID: ' SSL_CERTIFICATE_AWS_ACCESS_KEY_ID
  read -p 'AWS Secret Access key ID: ' SSL_CERTIFICATE_AWS_SECRET_ACCESS_KEY

  cat > ~/.acme.sh/account.conf << EOF
  export AWS_ACCESS_KEY_ID=$SSL_CERTIFICATE_AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$SSL_CERTIFICATE_AWS_SECRET_ACCESS_KEY
EOF
}

createWildcardCertificate()
{
  # Ask data to user
  read -p 'AWS Access key ID: ' SSL_CERTIFICATE_AWS_ACCESS_KEY_ID
  read -p 'AWS Secret Access key ID: ' SSL_CERTIFICATE_AWS_SECRET_ACCESS_KEY

  # Remove old keys
  # sed '/export AWS_ACCESS_KEY_ID=/d' -i ~/.acme.sh/account.conf
  # sed '/export AWS_SECRET_ACCESS_KEY=/d' -i ~/.acme.sh/account.conf


  cat > ~/.acme.sh/account.conf << EOF
  export AWS_ACCESS_KEY_ID=$SSL_CERTIFICATE_AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$SSL_CERTIFICATE_AWS_SECRET_ACCESS_KEY
EOF
}

installJava()
{
  working && printf "Installing Java ..."

  # Install Java
  sudo yum -y install java-1.8.0 >$YUM_OUTPUT_FILE && waitYUM

  # Select Latest Version
  sudo alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java

  ok && printf "Java 1.8.0 installed" && nl
}

installJenkins()
{
  working && printf "Installing Jenkins ..."
  
  # The repos are a bit slow, assing more timeout
  sudo sed -i 's/timeout=5/timeout=90/g' /etc/yum.conf

  # Install Jenkins repo
  sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo --quiet

  # Install Jenkins key
  sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key

  # Install Jenkins
  sudo yum -y install jenkins >$YUM_OUTPUT_FILE && waitYUM

  # Start Jenkins
  sudo service jenkins start

  ok && printf "Jenkins installed" && nl
  info && printf "Initial Admin Password: " && sudo -s cat /var/lib/jenkins/secrets/initialAdminPassword && nl 
  
}

nginxWebhook()
{
  working && printf "Installing Nginx Webhook..."

  # Create directories
  mkdir -p ~/webhooks/hooks/nginx 2>/dev/null
  mkdir -p ~/webhooks/tmp/nginx 2>/dev/null

  # Create main hook file
  cat > ~/webhooks/hooks/nginx/hook.json << EOF
[
  {
    "id": "nginx",
    "execute-command": "/home/$USER/webhooks/hooks/nginx/script.sh",
    "command-working-directory": "/home/$USER/webhooks/tmp/nginx",
    "response-message": "Executing deploy script...",
    "trigger-rule": {
      "match": {
        "type": "payload-hash-sha1",
        "secret": "pixium.io",
        "parameter": {
          "source": "header",
          "name": "X-Hub-Signature"
        }
      }
    }
  }
]
EOF

  # Create main shell script file
  cat > ~/webhooks/hooks/nginx/script.sh << EOF
#!/bin/bash

REPO="$NGINX_CONFIG_REPO"
HOME="/home/$USER"
DIR="\$HOME/webhooks/tmp/nginx"
REPO_DIR="\$DIR/repo"
LOG="\$DIR/exec.log"
# If is the first time create & clone the repo
FIRST_TIME=false && [ ! -d "\$REPO_DIR" ] && FIRST_TIME=true


###################################################################

echo "---------------------------------------------" >> exec.log
echo "CURR_USER: \$USER" >> \$LOG
echo "PWD: \$(pwd)" >> \$LOG
echo "REPO: \$REPO" >> \$LOG
echo "HOME: \$HOME" >> \$LOG
echo "DIR: \$DIR" >> \$LOG 
echo "REPO_DIR: \$REPO_DIR" >> \$LOG
echo "FIRST_TIME: \$FIRST_TIME" >> \$LOG
echo "" >> exec.log
echo "" >> exec.log

# Add keys for github
echo "Load Key for this repo" >> \$LOG
eval "\$(ssh-agent -s)" >> \$LOG
ssh-add \$HOME/.ssh/keys/id_nginx_config >> \$LOG

if [ "\$FIRST_TIME" = true ]; then
  echo "CREATE REPO DIR" >> \$LOG
  mkdir -p \$REPO_DIR
  cd \$REPO_DIR && sudo chmod ugo+rw .
  git clone \$REPO . >> \$HOME/out.log 2>&1

  # Copy initial conf
  echo "COPY INITIAL CONF" >> \$LOG
  sudo rsync -aq /etc/nginx/conf.d/ \$REPO_DIR/ --exclude .bkp

  echo "PUSH TO REPO" >> \$LOG
  git add . >> \$HOME/out.log 2>&1
  git commit -m "Initial config" >> \$HOME/out.log 2>&1
  git push >> \$HOME/out.log 2>&1
fi

# Move to repo dir
cd \$REPO_DIR

# Get latest
git reset --hard >> \$HOME/out.log 2>&1
git pull origin master >> \$HOME/out.log 2>&1

# Get last commit Author
AUTHOR=\$(git log -1 --pretty=format:'%an' | xargs)
echo "LAST_AUTHOR: \$AUTHOR" >> \$LOG


# If the author is not the server
if [ "\$AUTHOR" != "$GIT_USERNAME" ]; then

  echo "CREATE BKP DIR" >> \$LOG
  sudo mkdir -p /etc/nginx/conf.d/.bkp

  echo "MOVE CURR CONF FILES TO BKP" >> \$LOG
  sudo rsync -aq --remove-source-files /etc/nginx/conf.d/ /etc/nginx/conf.d/.bkp/ --exclude .bkp
  sudo rsync -aq --delete `mktemp -d`/ /etc/nginx/conf.d/ --exclude .bkp

  echo "MOVE NEW CONF FILES TO NGINX" >> \$LOG
  sudo rsync -av -q --progress \$REPO_DIR/ /etc/nginx/conf.d/ --exclude .git --exclude .gitignore --exclude log

  OK=false && sudo nginx -t && OK=true
  echo "CONFIG TEST: \$OK" >> \$LOG

  echo "-------------------------------------------------------------" >> log
  echo "DATE: $(date +%D)" >> log
  echo "TIME: $(date +%T)" >> log

  if [ "\$OK" = true ]; then
    
    echo "REMOVE BKP DIR" >> \$LOG
    sudo rm -rf /etc/nginx/conf.d/.bkp/
    
    echo "RELOAD NGINX" >> \$LOG
    sudo nginx -s reload
    
    echo "WRITE RESULTS TO LOG" >> \$LOG
    echo "RESULT: OK" >> log
    echo "DUMP:" >> log
    sudo nginx -t &>> log

  else

    echo "WRITE RESULTS TO LOG" >> \$LOG
    echo "RESULT: ERROR (PREV CONFIG IS RUNING NOW, FIX IT AND PUSH AGAIN)" >> log
    echo "DUMP:" >> log
    sudo nginx -t &>> log

    echo "REMOVE CORRUPT CONF" >> \$LOG
    sudo rsync -aq --delete `mktemp -d`/ /etc/nginx/conf.d/ --exclude .bkp
    
    echo "RESTORE PREV CONF" >> \$LOG
    sudo rsync -aq --remove-source-files /etc/nginx/conf.d/.bkp/ /etc/nginx/conf.d --exclude .bkp
    
    echo "REMOVE BKP DIR" >> \$LOG
    sudo rm -rf /etc/nginx/conf.d/.bkp/

    echo "RELOAD NGINX" >> \$LOG
    sudo nginx -s reload

  fi

  echo "PUSH TO REPO" >> \$LOG
  git add . && git commit -m "NGINX new config result"
  git push origin master
fi

if [ "\$AUTHOR" = "$GIT_USERNAME" ]; then
  echo "LAST AUTHOR IS SELF SERVER > ABORT" >> \$LOG
fi

EOF

  # set permission to execute file
  chmod +x ~/webhooks/hooks/nginx/script.sh

  # Create SSH Keys for this feature
  createSSHKey $NGINX_CONFIG_KEY_NAME 0

  # Restart Webhook
  sudo initctl restart webhook

  ok && printf "Nginx Webhook installed." && nl
}


printLogo

updateYUM

installNVM

installNode

installJava

installJenkins

createSSHKeysDir

SSHAutoloadKeys

installNginx

installWebhook

nginxWebhook

installAcme

# Temp to show keys
cd ~/.ssh/keys && cat id_nginx_config.pub && cd ~/