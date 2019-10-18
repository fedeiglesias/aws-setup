# CentOS install in AWS

# Update yum packages
  sudo yum -y update
  sudo yum -y upgrade

# Install wget and git
  sudo yum -y install git

# Install ZSH from source
  sudo yum -y install gcc
  sudo yum -y install ncurses-devel
  sudo yum -y install wget
  
  wget http://www.zsh.org/pub/zsh-5.7.1.tar.xz -P ~/ && tar xf ~/zsh-5.7.1.tar.xz && cd ~/zsh-5.7.1
  ./configure && make && sudo make install
  sudo chsh -s /usr/local/bin/zsh

  rm -rf ~/zsh-5.7.1
  rm ~/zsh-5.7.1.tar.xz