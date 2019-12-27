#!/bin/bash

REPO="${NGINX_CONFIG_REPO}"
USER_="${USER}"
HOME="/home/$USER_"
DIR="$HOME/webhooks/tmp/nginx"
REPO_DIR="$DIR/repo"
LOG="$DIR/exec.log"
GIT_USERNAME=$(git config user.name)

# If is the first time create & clone the repo
FIRST_TIME=false && [ -f "$DIR/first_time" ] && FIRST_TIME=true


###################################################################

echo "---------------------------------------------" >> exec.log
echo "CURR_USER: $USER" >> $LOG
echo "PWD: $(pwd)" >> $LOG
echo "REPO: $REPO" >> $LOG
echo "HOME: $HOME" >> $LOG
echo "DIR: $DIR" >> $LOG 
echo "REPO_DIR: $REPO_DIR" >> $LOG
echo "FIRST_TIME: $FIRST_TIME" >> $LOG
echo "" >> exec.log
echo "" >> exec.log

# Add keys for github
echo "Load Key for this repo" >> $LOG
eval "$(ssh-agent -s)" >> $LOG
ssh-add $HOME/.ssh/keys/id_nginx_config >> $LOG

if [ "$FIRST_TIME" = true ]; then
  echo "CREATE REPO DIR" >> $LOG
  mkdir -p $REPO_DIR
  cd $REPO_DIR && sudo chmod ugo+rw .
  git clone $REPO . >> $HOME/out.log 2>&1

  # Copy initial conf
  echo "COPY INITIAL CONF" >> $LOG
  sudo rsync -aq /etc/nginx/conf.d/ $REPO_DIR/ --exclude .bkp

  echo "PUSH TO REPO" >> $LOG
  git add . >> $HOME/out.log 2>&1
  git commit -m "Initial config" >> $HOME/out.log 2>&1
  git push >> $HOME/out.log 2>&1
fi

# Move to repo dir
cd $REPO_DIR

# Get latest
git reset --hard >> $HOME/out.log 2>&1
git pull origin master >> $HOME/out.log 2>&1

# Get last commit Author
AUTHOR=$(git log -1 --pretty=format:'%an' | xargs)
echo "LAST_AUTHOR: $AUTHOR" >> $LOG


# If the author is not the server
if [ "$AUTHOR" != "$GIT_USERNAME" ]; then

  echo "CREATE BKP DIR" >> $LOG
  sudo mkdir -p /etc/nginx/conf.d/.bkp

  echo "MOVE CURR CONF FILES TO BKP" >> $LOG
  sudo rsync -aq --remove-source-files /etc/nginx/conf.d/ /etc/nginx/conf.d/.bkp/ --exclude .bkp
  sudo rsync -aq --delete `mktemp -d`/ /etc/nginx/conf.d/ --exclude .bkp

  echo "MOVE NEW CONF FILES TO NGINX" >> $LOG
  sudo rsync -av -q --progress $REPO_DIR/ /etc/nginx/conf.d/ --exclude .git --exclude .gitignore --exclude log

  OK=false && sudo nginx -t && OK=true
  echo "CONFIG TEST: $OK" >> $LOG

  echo "-------------------------------------------------------------" >> log
  echo "DATE: $(date +%D)" >> log
  echo "TIME: $(date +%T)" >> log

  if [ "$OK" = true ]; then
    
    echo "REMOVE BKP DIR" >> $LOG
    sudo rm -rf /etc/nginx/conf.d/.bkp/
    
    echo "RELOAD NGINX" >> $LOG
    sudo nginx -s reload
    
    echo "WRITE RESULTS TO LOG" >> $LOG
    echo "RESULT: OK" >> log
    echo "DUMP:" >> log
    sudo nginx -t &>> log

  else

    echo "WRITE RESULTS TO LOG" >> $LOG
    echo "RESULT: ERROR (PREV CONFIG IS RUNING NOW, FIX IT AND PUSH AGAIN)" >> log
    echo "DUMP:" >> log
    sudo nginx -t &>> log

    echo "REMOVE CORRUPT CONF" >> $LOG
    sudo rsync -aq --delete `mktemp -d`/ /etc/nginx/conf.d/ --exclude .bkp
    
    echo "RESTORE PREV CONF" >> $LOG
    sudo rsync -aq --remove-source-files /etc/nginx/conf.d/.bkp/ /etc/nginx/conf.d --exclude .bkp
    
    echo "REMOVE BKP DIR" >> $LOG
    sudo rm -rf /etc/nginx/conf.d/.bkp/

    echo "RELOAD NGINX" >> $LOG
    sudo nginx -s reload

  fi

  echo "PUSH TO REPO" >> $LOG
  git add . && git commit -m "NGINX new config result"
  git push origin master
fi

if [ "$AUTHOR" = "$GIT_USERNAME" ]; then
  echo "LAST AUTHOR IS SELF SERVER > ABORT" >> $LOG
fi