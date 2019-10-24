
# Install AWS Lightsail webserver with SSL cert



#Route 53 API keys
echo '####################################################################'
read -e -p "INSTALL NGINX [n/y]: " -i "y" install_nginx
read -e -p "INSTALL ACME.SH [n/y]: " -i "y" install_acmesh

read -e -p "INSTALL LET'S ENCRIPT WILDCARD SSL (W/AWS)? [n/y]: " -i "n" install_letsencript_ssl
if install_letsencript_ssl == 'y' 
then
  read -p 'AWS KEY ID: ' aws_key_id
  read -p 'AWS KEY PASSWORD: ' aws_key_password
  read -e -p "DOMAIN: " -i "fedeiglesias.com" domain
  read -e -p "CERT DIRECTORY: " -i "~/ssl" certs_dir
fi

echo '####################################################################'

# Update yum packages
sudo yum -y update
sudo yum -y upgrade

# Install wget and git
sudo yum -y install git

# If nginx installed restart it
if install_nginx == 'y' 
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
if install_acmesh == 'y'
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
if install_letsencript_ssl == 'y'
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
  if install_nginx == 'y' 
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