#!/bin/bash

# Show menu prompt
echo '####################################################################'

read -e -p "MAIN PROJECT NAME: " -i "home" main_project_name
read -e -p "IS MAIN PROJECT LINKED TO GIT REPO ? " -i "y" main_project_linked_to_git

if [ $main_project_linked_to_git == "y" ] then
  install_git="y"
  read -e -p "MAIN PROJECT GIT (http for git clone): " -i "" main_project_git_repo
fi

# If user dont want to link main project to a git repo
# ask him anyway if want to install git alone
if [ $main_project_linked_to_git == "n" ] then
  read -e -p "INSTALL GIT [n/y]: " -i "y" install_git
fi

# Golang & Webhook
read -e -p "YOU NEED SUPPORT FOR GITHUB HOOKS? [n/y]: " -i "y" webhooks_support
if [ $webhooks_support == "y" ] then
  echo "----------------------------------------------------------------------------------------"
  echo "  Github have a nice feature called webhooks. With this feature you can send a"
  echo "  message to your server when your git project have changes, so you can trigger a"
  echo "  script that pull automatically from your repo and re run your app with the"
  echo "  new changes. To start using webhooks, we need to do some things. Let get's started!"
  echo "----------------------------------------------------------------------------------------"
  echo ""
  echo "    First, we need to create a PRIVATE repo that will contain our webhooks configuraration."
  echo "    Go to your Github account, create a new repo, for example 'server-webhooks-config'."
  echo "    Copy the SSL key and paste it here (git@github.com:username/repo-name.git): "
  read -e -p "    > " -i "" webhooks_config_repo
  echo ""
  echo ""
  echo "    Nice! ok, now we need a ssh key to connect with this repo from the server. To do it"
  echo "    go to Github > Settings tab > Deploy keys and click to button 'Add Key'. It will appear"
  echo "    a form, add a name, for example 'server-webhooks-config', make sure the checkbox"
  echo "    is checked and in KEY textarea paste the next ssh key: "
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

# Update yum packages
sudo yum -y update
sudo yum -y upgrade

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
  # Get LTS version
  GOLANG_VERSION="`wget -qO- https://golang.org/VERSION?m=text`"
  # Move to tmp
  cd /tmp
  # Get installer
  wget https://dl.google.com/go/$GOLANG_VERSION.linux-amd64.tar.gz
  # decompress
  sudo tar -C /usr/local -xzf $GOLANG_VERSION.linux-amd64.tar.gz
  # install
  export PATH=$PATH:/usr/local/go/bin
  # remove tmp files
  rm -rf $GOLANG_VERSION.linux-amd64.tar.gz
  # move to home
  cd ~/

  #install Golang
  if [ $install_webhook == "y" ] 
  then
    # install webhook
    go get github.com/adnanh/webhook
    # create dir for webhooks
    mkdir ~/webhooks
    touch ~/webhooks/hooks.json
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