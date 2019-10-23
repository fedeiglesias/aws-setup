
# Install AWS Lightsail webserver with SSL cert



#Route 53 API keys
echo '####################################################################'
read -p 'AWS KEY ID: ' aws_key_id
read -p 'AWS KEY PASSWORD: ' aws_key_password
read -p 'DOMAIN: ' domain
echo '####################################################################'


# Update yum packages
  sudo yum -y update
  sudo yum -y upgrade

# Install wget and git
  sudo yum -y install git

# Install nginx
 sudo yum -y install nginx
 #start nginx a startup
 sudo chkconfig nginx on
 # Must config reverse proxy to route 80 to 3000 port
 #sudo vi /etc/nginx/nginx.conf
 #location / { proxy_pass http://127.0.0.1:3000; }
 #sudo service nginx restart
 

# Install nvm and node
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash
  source ~/.bashrc
  nvm install --lts

# Install Acme.sh with sudo access
  # create crontab for sudo (is used by acme.sh to renew certificates each 80 days)
  # sudo crontab -e
  # clone repo
  cd /tmp && git clone https://github.com/Neilpang/acme.sh.git
  # get inside and install
  cd /tmp/acme.sh && sudo ./acme.sh --install
  # remove tmp dir
  rm -rf /tmp/acme.sh
  # restart bash
  source ~/.bashrc


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