# CentOS install in AWS

# Update yum packages
  sudo yum -y update
  sudo yum -y upgrade

# Install wget and git
  sudo yum -y install git

# Install nginx
 sudo yum -y install nginx
 sudo chkconfig nginx on
 # Must config reverse proxy to route 80 to 3000 port
 #sudo vi /etc/nginx/nginx.conf
 #location / { proxy_pass http://127.0.0.1:3000; }
 #sudo service nginx restart
 

# Install nvm and node
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash
  source ~/.bashrc
  nvm install node --lts

# Install Acme.sh
  wget -O - https://get.acme.sh | sh
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