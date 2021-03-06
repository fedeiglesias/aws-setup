#!/bin/bash

printLogo()
{
  echo -e ""
  echo -e ""
  echo -e "  ${fg_blue}██████${fg_d_gray}╗   ${fg_blue}██████${fg_d_gray}╗   ${fg_blue}██████${fg_d_gray}╗ ${fg_blue}██${fg_d_gray}╗  ${fg_blue}██${fg_d_gray}╗ ${fg_blue}███████${fg_d_gray}╗ ${fg_blue}████████${fg_d_gray}╗ "
  echo -e "  ${fg_blue}██${fg_d_gray}╔══${fg_blue}██${fg_d_gray}╗ ${fg_blue}██${fg_d_gray}╔═══${fg_blue}██${fg_d_gray}╗ ${fg_blue}██${fg_d_gray}╔════╝ ${fg_blue}██${fg_d_gray}║ ${fg_blue}██${fg_d_gray}╔╝ ${fg_blue}██${fg_d_gray}╔════╝ ╚══${fg_blue}██${fg_d_gray}╔══╝"
  echo -e "  ${fg_blue}██████${fg_d_gray}╔╝ ${fg_blue}██${fg_d_gray}║   ${fg_blue}██${fg_d_gray}║ ${fg_blue}██${fg_d_gray}║      ${fg_blue}█████${fg_d_gray}╔╝  ${fg_blue}█████${fg_d_gray}╗      ${fg_blue}██${fg_d_gray}║ "
  echo -e "  ${fg_blue}██${fg_d_gray}╔══${fg_blue}██${fg_d_gray}╗ ${fg_blue}██${fg_d_gray}║   ${fg_blue}██${fg_d_gray}║ ${fg_blue}██${fg_d_gray}║      ${fg_blue}██${fg_d_gray}╔═${fg_blue}██${fg_d_gray}╗  ${fg_blue}██${fg_d_gray}╔══╝      ${fg_blue}██${fg_d_gray}║ "
  echo -e "  ${fg_blue}██${fg_d_gray}║  ${fg_blue}██${fg_d_gray}║ ╚${fg_blue}██████${fg_d_gray}╔╝ ╚${fg_blue}██████${fg_d_gray}╗ ${fg_blue}██${fg_d_gray}║  ${fg_blue}██${fg_d_gray}╗ ${fg_blue}███████${fg_d_gray}╗    ${fg_blue}██${fg_d_gray}║ "
  echo -e "  ${fg_d_gray}╚═╝  ╚═╝  ╚═════╝   ╚═════╝ ╚═╝  ╚═╝ ╚══════╝    ╚═╝ "
  echo -e ""
}

# Rocket
ROCKET_REPO='https://raw.githubusercontent.com/fedeiglesiasc/aws-setup/master'

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

#SSL CERTIFICATES
SSL_CERTIFICATES_DIR="/home/$USER/.ssl_certificates"


# COLORS
dim=$'\001\e[2m\002'
no_dim=$'\001\e[22m\002'
white=$'\001\e[97m\002'
dark_gray=$'\001\e[90m\002'
red=$'\001\e[31m\002'
green=$'\001\e[32m\002'
yellow=$'\001\e[93m\002'
l_yellow=$'\001\e[93m\002'
blue=$'\001\e[34m\002'
magenta=$'\001\e[35m\002'
cyan=$'\001\e[36m\002'
end=$'\001\e[0m\002'

#FOREGROUND
fg_default=$'\001\e[39m\002'
fg_white=$'\001\e[97m\002'
fg_black=$'\001\e[30m\002'
fg_red=$'\001\e[31m\002'
fg_green=$'\001\e[32m\002'
fg_yellow=$'\001\e[33m\002'
fg_blue=$'\001\e[34m\002'
fg_magenta=$'\001\e[35m\002'
fg_cyan=$'\001\e[36m\002'
fg_d_gray=$'\001\e[90m\002'
fg_l_gray=$'\001\e[37m\002'
fg_l_red=$'\001\e[91m\002'
fg_l_green=$'\001\e[92m\002'
fg_l_yellow=$'\001\e[93m\002'
fg_l_blue=$'\001\e[94m\002'
fg_l_magenta=$'\001\e[95m\002'
fg_l_cyan=$'\001\e[96m\002'

# BACKGROUNDS
bg_default=$'\001\e[49m\002'
bg_black=$'\001\e[40m\002'
bg_red=$'\001\e[41m\002'
bg_green=$'\001\e[42m\002'
bg_yellow=$'\001\e[43m\002'
bg_blue=$'\001\e[44m\002'
bg_magenta=$'\001\e[45m\002'
bg_cyan=$'\001\e[46m\002'
bg_d_gray=$'\001\e[100m\002'
bg_l_gray=$'\001\e[47m\002'
bg_l_red=$'\001\e[101m\002'
bg_l_green=$'\001\e[102m\002'
bg_l_yellow=$'\001\e[103m\002'
bg_l_blue=$'\001\e[104m\002'
bg_l_magenta=$'\001\e[105m\002'
bg_l_cyan=$'\001\e[106m\002'
bg_l_white=$'\001\e[107m\002'


sed_scape_slash='s/\//\\\//g'

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

config_title()
{
  printf "\n ${fg_l_yellow}┌──${fg_black}${bg_l_yellow} SETUP ${bg_default}${fg_l_yellow}──┤${fg_white}$1 ${end}\n"
}

config_item()
{
  LAST=false
  if [ -n "$2" ]; then 
    LAST=$2
  fi

  PIPECHAR="├"
  if [ $LAST = true ]; then
    PIPECHAR="└"
  fi

  printf " ${fg_l_yellow}${PIPECHAR} ${fg_default}${dim}$1 ${no_dim}${fg_l_yellow}›${end} "
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
  sudo yum --nogpgcheck -y update 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM
  ok && printf "YUM is updated" && nl

  # Upgrade YUM
  working && printf "Upgrading YUM ..."
  sudo yum --nogpgcheck -y upgrade 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM
  ok && printf "YUM is upgraded" && nl

  #Remove orphan packages  
  working && printf "Clean orphan packages ..."
  sudo yum --nogpgcheck -y autoremove 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM
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
    curl -o $GOLANG_VERSION.linux-amd64.tar.gz https://dl.google.com/go/$GOLANG_VERSION.linux-amd64.tar.gz --silent
    
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
 addWebhookToSystemd
 # Create conf for Nginx
 createNginxConfMainDomain
}

addWebhookToSystemd()
{
  # Add webhook in crontab
  working && printf "Adding Webhook to startup ..."
  sudo curl -o /etc/systemd/system/webhook.service $ROCKET_REPO/startup/systemd/webhook.service --silent
  # Replace Placeholders
  SCAPED_USER=$(echo $USER | sed $sed_scape_slash)
  sudo sed -i "s/\${USER}/$SCAPED_USER/g" /etc/systemd/system/webhook.service
  # Enable command to ensure that the service starts whenever the system boots
  sudo systemctl enable webhook --quiet 2>&1 >/dev/null
  sudo systemctl restart webhook --quiet 2>&1 >/dev/null
  ok && printf "Webhook added to startup" && nl
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
    sudo systemctl restart sshd

  } 2>/dev/null

  # Add github to know hosts
  # ssh-keyscan github.com >> ~/.ssh/known_hosts

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
  sudo yum -y install git 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM
  git config --global user.name $GIT_USERNAME
  git config --global user.email $GIT_EMAIL
  ok && printf "GIT installed" && nl
}

installNginx()
{
  # Install Nginx
  working && printf "Installing Nginx ..."
  sudo yum -y install epel-release 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM
  sudo yum -y install nginx 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM

  sudo systemctl enable nginx --quiet 2>&1 >/dev/null
  sudo systemctl start nginx --quiet 2>&1 >/dev/null

  # All go ok
  ok && printf "Nginx installed" && nl
}


installNVM()
{
  #Install LTS version of NVM
  working && printf "Installing NVM ..."
  
  # Support to get the latest version auto from source
  sudo yum -y install epel-release 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM
  sudo yum -y install jq 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM

  # LTS
  VER_LTS=$(curl -s 'https://api.github.com/repos/nvm-sh/nvm/releases/latest' | jq -r '.tag_name') 2>/dev/null

  # download installer
  curl -sS https://raw.githubusercontent.com/nvm-sh/nvm/$VER_LTS/install.sh > /tmp/install-nvm.sh 
  bash /tmp/install-nvm.sh 2>&1 >/dev/null
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
  sudo yum -y install java-1.8.0 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM

  # Select Latest Version
  # sudo alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java

  ok && printf "Java 1.8.0 installed" && nl
}

installJenkins()
{
  working && printf "Installing Jenkins ..."
  
  # The repos are a bit slow, assing more timeout
  sudo sed -i 's/timeout=5/timeout=90/g' /etc/yum.conf

  # Install Jenkins repo
  sudo curl -o /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo --silent

  # Install Jenkins key
  sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key

  # Install Jenkins
  sudo yum -y install jenkins 1> /dev/null 2>> $YUM_OUTPUT_FILE && waitYUM

  # Start Jenkins
  sudo service jenkins start 2>&1 >/dev/null

  # Admin password
  INITIALADMINPASSWORD=$(sudo -s cat /var/lib/jenkins/secrets/initialAdminPassword)

  ok && printf "Jenkins installed" && nl
  info && printf "Initial Admin Password: $INITIALADMINPASSWORD" && nl
}

nginxWebhook()
{
  # NGINX Config repo
  NGINX_CONFIG_KEY_NAME="nginx"

  working && printf "Installing Nginx Webhook..."

  # Create directories
  mkdir -p ~/webhooks/hooks/nginx 2>/dev/null
  mkdir -p ~/webhooks/tmp/nginx 2>/dev/null
  mkdir -p ~/webhooks/tmp/nginx/repo 2>/dev/null
  sudo chmod ugo+rw ~/webhooks/tmp/nginx/repo
  touch ~/webhooks/tmp/nginx/first_time
  
  # Get Hook
  curl -o ~/webhooks/hooks/nginx/hook.json $ROCKET_REPO/webhooks/nginx/hook.json --silent

  # Replace placeholders
  SCAPED_SECRET=$(echo $WEBHOOK_NGINX_CONFIG_SECRET | sed $sed_scape_slash)
  sed -i "s/\${SECRET}/$SCAPED_SECRET/g" ~/webhooks/hooks/nginx/hook.json

  SCAPED_USER=$(echo $USER | sed $sed_scape_slash)
  sed -i "s/\${USER}/$SCAPED_USER/g" ~/webhooks/hooks/nginx/hook.json

  # Get Script
  curl -o ~/webhooks/hooks/nginx/script.sh $ROCKET_REPO/webhooks/nginx/script.sh --silent

  # Replace Script Placeholders
  SCAPED_REPO=$(echo $WEBHOOK_NGINX_CONFIG_REPO | sed $sed_scape_slash)
  sed -i "s/\${NGINX_CONFIG_REPO}/$SCAPED_REPO/g" ~/webhooks/hooks/nginx/script.sh

  # set permission to execute file
  chmod +x ~/webhooks/hooks/nginx/script.sh

  # Create SSH Keys for this feature
  createSSHKey $NGINX_CONFIG_KEY_NAME 0

  # Restart Webhook
  sudo systemctl restart webhook --quiet


  ok && printf "Nginx Webhook installed." && nl
}

clear && printLogo

config_title "General"
read -p "$(config_item "Server name")" -e -i "rocket" SERVER_NAME
read -p "$(config_item "Main domain" true)" -e -i "pixium.io" MAIN_DOMAIN

config_title "GIT"
read -p "$(config_item "Username")" -e -i "$SERVER_NAME" GIT_USERNAME
read -p "$(config_item "Email" true)" -e -i "$GIT_USERNAME@$MAIN_DOMAIN" GIT_EMAIL

config_title "NGINX Webhook"
read -p "$(config_item "Git repo (SSH)")" -e -i "rocket" WEBHOOK_NGINX_CONFIG_REPO
read -p "$(config_item "Webhook secret word" true)" -e -i "SeCrET" WEBHOOK_NGINX_CONFIG_SECRET

echo -e ""
echo -e ""
echo -e ""

updateYUM
installNVM
installNode
# installJava
# installJenkins
createSSHKeysDir
SSHAutoloadKeys
installNginx
installWebhook
installAcme
nginxWebhook



# Temp to show keys
cd ~/.ssh/keys && cat id_nginx.pub && cd ~/