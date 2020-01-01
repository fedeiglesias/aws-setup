# aws-setup

1- run `source <(curl -s https://raw.githubusercontent.com/fedeiglesiasc/aws-setup/master/setup.sh?$(date + %s))`

* bambu
* fedeiglesias.com
* git@github.com:fedeiglesiasc/server-nginx.git
* pixium.io 

Github have a nice feature called webhooks. With this feature you can send a 
message to our server when your project have changes, so you can trigger a 
script that pull automatically from your repo and re run your app with the 
new changes. To start using webhooks, we need to do some things. Let get's started!
First, we need to create a PRIVATE repo that will contain our webhooks configuraration.
Copy the SSL key and paste it here (git@github.com:username/repo-name.git): 


# Crear y dar permisos a la configuracion de ssh
cat > ~/.ssh/config << EOF
  Host *
    AddKeysToAgent yes
EOF

# Set permissions for config
chmod 600 ~/.ssh/config

# Crear directorio para las keys
mkdir ~/.ssh/keys

# Crea una nueva llave nombre id_server_webhooks y passphrase "holaa"
ssh-keygen -f /home/ec2-user/.ssh/keys/id_server_webhooks -q -N ""

# registrar la llave en el agent
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_server_webhooks

# Falta registrar las llaves cada vez que bootea la maquina
cat ~/.ssh/id_server_webhooks.pub

# Fetch from repo
git fetch --all
git checkout --force "origin/master"

# Para cada archivo
for f in ~/.ssh/keys ; do [[ $f == *.pub ]] && continue echo $f ; done

# Añadimos todas las keys
for f in $(ls ~/.ssh/keys/ --hide="*.pub")
do
  ssh-add ~/.ssh/keys/$f
done

# Create scripts dir
mkdir ~/.scripts

# Create boot stript
cat > ~/.scripts/onReboot << EOF
  #!/bin/bash

  # Load all keys
  for f in $(ls ~/.ssh/keys/ --hide="*.pub")
  do
    ssh-add ~/.ssh/keys/$f
  done
EOF

# Add crontab shellscript on reboot
  # write out current crontab
  crontab -l > mycron
  # echo new cron into cron file
  echo "@reboot /home/ec2-user/go/bin/webhook -hooks /home/ec2-user/webhooks/hooks.json -ip "127.0.0.1" -verbose" >> mycron
  # install new cron file
  crontab mycron
  rm mycron


wget https://github.com/emcrisostomo/fswatch/releases/download/1.9.3/fswatch-1.9.3.tar.gz
tar -xvzf fswatch-1.9.3.tar.gz
cd fswatch-1.9.3
./configure
make
sudo make install 

  # Add webhook in crontab
  #working && printf "Adding Webhook to Crontab ..."
  # Command to add to crontab
  CC="@reboot eval \$(ssh-agent -s) && for f in $(ls ~/.ssh/keys/ --hide='*.pub'); do ssh-add ~/.ssh/keys/$f; done"
  # Add to Crontab ONLY if not exist alredy and without show errors
  #! (crontab -l 2>/dev/null | grep -q "$CC") && (crontab -l 2>/dev/null; echo $CC) | crontab -
  # All go ok
  #ok && printf "Webhook added to Crontab" && nl


# Lets Encript wilcard certificate with acme.sh & Route53
 1 - Go to AWS admin panel > My security credentials > Users
 2 - Create new user
 3 - Go to 'Security credentials' tab and create a Access key
 3 - Add perm with this data: 

`{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "route53:GetHostedZone",
                  "route53:ListHostedZones",
                  "route53:ListHostedZonesByName",
                  "route53:GetHostedZoneCount",
                  "route53:ChangeResourceRecordSets",
                  "route53:ListResourceRecordSets"
              ],
              "Resource": "*"
          }
      ]
  }`

  4 - Save Access Keys 
  `export  AWS_ACCESS_KEY_ID=
  export  AWS_SECRET_ACCESS_KEY=`

  5 - Issue a new wildcard domain (fedeiglesias.com)
  `acme.sh --staging --force --issue -d fedeiglesias.com -d *.fedeiglesias.com --dns dns_aws`

  6- Install the certificate
  `mkdir ~/.ssl_certificates`
  `acme.sh --install-cert 
    -d fedeiglesias.com 
    --cert-file ~/.ssl_certificates/fedeiglesias.com/cert.pem 
    --key-file ~/.ssl_certificates/fedeiglesias.com/key.pem 
    --fullchain-file ~/.ssl_certificates/fedeiglesias.com/fullchain.pem 
    --reloadcmd "sudo service nginx restart"`



acme.sh --install-cert -d fedeiglesias.com --cert-file ~/.ssl_certificates/fedeiglesias.com/cert.pem --key-file ~/.ssl_certificates/fedeiglesias.com/key.pem --fullchain-file ~/.ssl_certificates/fedeiglesias.com/fullchain.pem --reloadcmd "sudo service nginx restart"



## NGINX

cd ~/.ssh/keys && cat id_nginx_config.pub && cd ~/


git branch --set-upstream-to=origin/master master


### The service (initctl)
 * Webhook run as a service in initctl
 * The Job generates logs in /var/log/webhook.log
 * Usefull commands to manage (upstart) webhook service: 
   - status: sudo initctl status webhook
   - start: sudo initctl start webhook
   - stop: sudo initctl stop webhook


## Webhooks

Webhooks help us to run shell scripts using an endpoint.
* The service default port is: 9000
* The default endpoint is /hooks

### The service (initctl)
 * Webhook run as a service in initctl
 * The Job generates logs in /var/log/webhook.log
 * Usefull commands to manage (upstart) webhook service: 
   - status: sudo initctl status webhook
   - start: sudo initctl start webhook
   - stop: sudo initctl stop webhook