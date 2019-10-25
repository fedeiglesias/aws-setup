# aws-setup

run `source <(curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/fedeiglesiasc/aws-setup/master/setup.sh)`

Github have a nice feature called webhooks. With this feature you can send a 
message to our server when your project have changes, so you can trigger a 
script that pull automatically from your repo and re run your app with the 
new changes. To start using webhooks, we need to do some things. Let get's started!
First, we need to create a PRIVATE repo that will contain our webhooks configuraration.
Copy the SSL key and paste it here (git@github.com:username/repo-name.git): 


# Pasos para instalar webhooks
  1. Instalar Golang
  2. Instalar Webhook
  3. Crear directorios nescesarios para webhooks
  4. Instalar python tools & arrancador al inicio
  5. Agregar Webook al inicio
  6. Agregar un proxypass al nginx del puerto 9001 al 9000


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
  echo "@reboot echo hello" >> mycron
  # install new cron file
  crontab mycron
  rm mycron