#!/bin/bash

printLogo()
{
  echo ""
  echo ""
  echo "  ██████╗  ██████╗  ██████╗██╗  ██╗███████╗████████╗"
  echo "  ██╔══██╗██╔═══██╗██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝"
  echo "  ██████╔╝██║   ██║██║     █████╔╝ █████╗     ██║ "
  echo "  ██╔══██╗██║   ██║██║     ██╔═██╗ ██╔══╝     ██║ "
  echo "  ██║  ██║╚██████╔╝╚██████╗██║  ██╗███████╗   ██║ "
  echo "  ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝ "
  echo ""
}


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

nl()
{
  printf "                                \n"
} 


updateYUM() 
{
  # Update YUM
  working && printf "Updating YUM ..."
  sudo yum -y update 2>&1 >/dev/null
  ok && printf "YUM is updated" && nl

  # Upgrade YUM
  working && printf "Upgrading YUM ..."
  sudo yum -y upgrade 2>&1 >/dev/null
  ok && printf "YUM is upgraded" && nl

  #Remove orphan packages  
  working && printf "Clean orphan packages ..."
  sudo yum -y autoremove 2>&1 >/dev/null
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

  } 2>/dev/null

  # All go ok
  ok && printf "Golang is installed" && nl
}

installWebhook4()
{

  # Install Nginx
  installGit()

  # Install Golang
  installGolang()

  # Install Webhook
  working && printf "Installing Webhook ..."
  go get github.com/adnanh/webhook 2>/dev/null
  ok && printf "Webhook installed successfull" && nl

  # Add webhook in crontab
  #working && printf "Adding Webhook to Crontab ..."
  # Command to add to crontab
  #CRON_WEBHOOK_COMMAND="@reboot /home/$USER/go/bin/webhook -hooks /home/$USER/webhooks/hooks.json -ip '127.0.0.1'"
  # Add to Crontab ONLY if not exist alredy and without show errors
  #! (crontab -l 2>/dev/null | grep -q "$ND") && (crontab -l 2>/dev/null; echo $ND) | crontab -
  # All go ok
  #ok && printf "Webhook added to Crontab" && nl

  # Add webhook in crontab
  working && printf "Adding Webhook to UpStart ..."
  # Add service to UpStart
  sudo tee -a /etc/init/webhook.conf >/dev/null <<'EOF'
      description "A Webhook server to run with Github"
      author "Federico Iglesias Colombo"
      start on runlevel [2345]
      exec /home/$USER/go/bin/webhook -hooks /home/$USER/webhooks/main/hook.json -hooks /home/$USER/webhooks/hooks/*/hook.json -ip '127.0.0.1'
EOF

  # Start service
  sudo initctl start webhook
  # All go ok
  ok && printf "Webhook added to UpStart" && nl

  # Check for port 9000
  working && printf "Checking if port 9000 is used ..."
  if lsof -Pi :9000 -sTCP:LISTEN -t 2>/dev/null ;
  then
    error && printf "Port 9000 is used" && nl
  else
    ok && printf "Port 9000 is free" && nl
  fi
}

configWebhooks() 
{
  
  # Add configure startup webhook project
  working && printf "Config Webhooks main project ..."
  
  # Create directory structure
  mkdir -p ~/webhooks 2>/dev/null
  mkdir -p ~/webhooks/main 2>/dev/null
  mkdir -p ~/webhooks/hooks 2>/dev/null

  # Create main hook file
  
  cat > ~/webhooks/main/hook.json << EOF
    [
      {
        "id": "webhooks", dsfsdf
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

  # All go ok
  ok && printf "Webhook main project configured" && nl
}

configSSHKeys1()
{
  # Add configure startup webhook project
  working && printf "Config SSH Public Keys ..."
  # Create keys dir
  mkdir -p ~/.ssh/keys
  # Add webhook in crontab
  #CC="@reboot eval \"\$(ssh-agent -s)\" && for f in \$(ls ~/.ssh/keys/ --hide='*.pub'); do ssh-add ~/.ssh/keys/\$f; done"
  #CC1="@reboot eval \" \$(ssh-agent -s)\" "
  # Add to Crontab ONLY if not exist alredy and without show errors
  #! (crontab -l 2>/dev/null | grep -q "$CC1") && (crontab -l 2>/dev/null; echo $CC1) | crontab -
  # All go ok
  ok && printf "SSH Public Keys configured" && nl
}


installGit()
{
  working && printf "Installing GIT ..."
  sudo yum -y install git 2>/dev/null
  ok && printf "GIT installed successfull" && nl
}

installNginx()
{
  # Install Nginx
  working && printf "Installing Nginx ..."
  sudo yum -y install nginx 2>/dev/null
  # Add Nginx to startup
  sudo chkconfig nginx on 2>/dev/null
  # All go ok
  ok && printf "Nginx installed successfull" && nl
}

configureWebhook()
{
}

printLogo()

# Show menu prompt
echo '####################################################################'

read -e -p "MAIN PROJECT NAME: " -i "home" main_project_name
read -e -p "IS MAIN PROJECT LINKED TO GIT REPO ? " -i "y" main_project_linked_to_git

if [ $main_project_linked_to_git == "y" ]
then
  install_git="y"
  read -e -p "MAIN PROJECT GIT (http for git clone): " -i "y" main_project_git_repo
fi

# If user dont want to link main project to a git repo
# ask him anyway if want to install git alone
if [ $main_project_linked_to_git == "n" ] 
then
  read -e -p "INSTALL GIT [n/y]: " -i "y" install_git
fi

# Golang & Webhook
read -e -p "YOU NEED SUPPORT FOR GITHUB HOOKS? [n/y]: " -i "y" webhooks_support
if [ $webhooks_support == "y" ] 
then
  echo "----------------------------------------------------------------------------------------"
  echo "  Github have a nice feature called webhooks. With this feature you can send a"
  echo "  message to your server when your git project have changes, so you can trigger a"
  echo "  script that pull automatically from your repo and re run your app with the"
  echo "  new changes. To start using webhooks, we need to do some things. Let get's started!"
  echo "----------------------------------------------------------------------------------------"
  echo ""
  echo "    | First, we need to create a PRIVATE repo that will contain our webhooks config."
  echo "    | Go to your Github account, create a new repo, for example 'server-webhooks-config'."
  echo "    | Copy the SSL key and paste it here (git@github.com:username/repo-name.git): "
  read -e -p "    > " -i "" webhooks_config_repo
  echo ""
  echo ""
  echo "    | Nice! ok, now we need a ssh key to connect with this repo from server."
  echo "    | Go to Github > Settings tab > Deploy keys and click button 'Add Key'."
  echo "    | Add a name, for example 'server-webhooks' and check 'Allow write access'"
  echo "    | Copy and paste the key in the textarea: "
  echo ""

  install_golang='y'
fi

read -e -p "INSTALL NGINX [n/y]: " -i "y" install_nginx
read -e -p "INSTALL ACME.SH [n/y]: " -i "y" install_acmesh

read -e -p "INSTALL LET'S ENCRIPT WILDCARD SSL (W/AWS)? [n/y]: " -i "n" install_letsencript_ssl
if [ $install_letsencript_ssl == "y" ] 
then
  read -p 'AWS KEY ID: ' aws_key_id
  read -p 'AWS KEY PASSWORD: ' aws_key_password
  read -e -p "DOMAIN: " -i "fedeiglesias.com" domain
  read -e -p "CERT DIRECTORY: " -i "~/ssl" certs_dir
fi

echo '####################################################################'

# create folder for projects
mkdir ~/projects

# create folder for main project
mkdir ~/projects/$main_project_name

#update & upgrade yum
updateYum()

# Install wget and git
if [ $install_git == "y" ] 
then
  sudo yum -y install git

  #link main project to git repo
  if [ $main_project_linked_to_git == "y" ] 
  then
    # move to project dir
    cd ~/projects/$main_project_name
    # init git repo & add remote origin
    git init && git remote add origin $main_project_git_repo
    #move to home
    cd ~/
  fi
fi



# git init
# git remote add origin git@github.com:fedeiglesiasc/fedeiglesias.com.git

#install Golang
if [ $webhooks_support == "y" ] 
then
  installGolang

  #install Webhooks
  if [ $install_webhook == "y" ] 
  then
    installWebhook
  fi
fi






# If nginx installed restart it
if [ $install_nginx == "y" ] 
then
  # Install nginx
  sudo yum -y install nginx
  #start nginx a startup
  sudo chkconfig nginx on
  # Must config reverse proxy to route 80 to 3000 port
  #sudo vi /etc/nginx/nginx.conf
  #location / { proxy_pass http://127.0.0.1:3000; }
  #sudo service nginx restart
fi


# Install nvm and node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash
source ~/.bashrc
nvm install --lts

# Install Acme.sh
if [ $install_acmesh == "y" ]
then
  # clone repo
  cd /tmp && git clone https://github.com/Neilpang/acme.sh.git
  # get inside and install
  cd /tmp/acme.sh && ./acme.sh --install
  # remove tmp dir
  cd ~/ && rm -rf /tmp/acme.sh
  # restart bash
  source ~/.bashrc
fi

# Install Let's encrypt certificate
if [ $install_letsencript_ssl == "y" ]
then
  # Create config file with keys
  cd ~/.acme.sh && rm account.conf
  cat > account.conf << EOF
    export AWS_ACCESS_KEY_ID=$aws_key_id
    export AWS_SECRET_ACCESS_KEY=$aws_key_password
EOF
  cd ~/

  # Install the certificate in some sensible place as the directory structure of ~/.acme.sh may change in the future.
  mkdir $certs_dir && mkdir $certs_dir/*.$domain

  # Test Letsencript wilcard issue
  acme.sh --test --issue --log --dns dns_aws -d "*.$domain" -d $domain

  # Delete test folders
  # rm -rf ~/.acme.sh/*$domain

  # Now run the issuing command twice (it will fail on the first run) just changing –test to –force
  # acme.sh --force --issue --log --dns dns_aws -d *.$domain -d $domain


  #SSL files
  cert_file=$certs_dir/*.$domain/*.$domain.cer
  key_file=$certs_dir/*.$domain/*.$domain.key
  fullchain_file=$certs_dir/*.$domain/fullchain.cer

  # Install certs
  acme.sh --install-cert -d *.$domain --cert-file $cert_file --key-file $key_file --fullchain-file $fullchain_file

  # If nginx installed restart it
  if [ $install_nginx == "y" ] 
  then
    service nginx reload
  fi
fi



# Install ZSH from source
#  sudo yum -y install gcc
#  sudo yum -y install ncurses-devel
#  sudo yum -y install wget
  
#  wget http://www.zsh.org/pub/zsh-5.7.1.tar.xz -P ~/ && tar xf ~/zsh-5.7.1.tar.xz && cd ~/zsh-5.7.1
#  ./configure && make && sudo make install
#  sudo chsh -s /usr/local/bin/zsh

#  rm -rf ~/zsh-5.7.1
#  rm ~/zsh-5.7.1.tar.xz

# Install Oh my ZSH
#  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
#  cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
#  cp ~/.zshrc ~/.zshrc.orig

# Install PowerLevel10K
#  git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k


