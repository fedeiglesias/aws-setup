# aws-setup

run `source <(curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/fedeiglesiasc/aws-setup/master/setup.sh)`


# Install wildcard SSL certificate with Acme.sh and Letsencrypt

## Test for wildcards
`acme.sh --test --issue --log --dns dns_aws -d *.fedeiglesias.com -d fedeiglesias.com` 

## Delete test folders
`rm -rf ~/.acme.sh/*fedeiglesias.com`

## Now run the issuing command twice (it will fail on the first run) just changing –test to –force
`acme.sh --force --issue --log --dns dns_aws -d *.fedeiglesias.com -d fedeiglesias.com`

## Install the certificate in some sensible place as the directory structure of ~/.acme.sh may change in the future.
`sudo mkdir /etc/nginx/acme.sh`
`sudo rm -rf /etc/nginx/*fedeiglesias.com`
`sudo mkdir /etc/nginx/acme.sh/*fedeiglesias.com`

`acme.sh --install-cert -d *.fedeiglesias.com --cert-file /etc/nginx/acme.sh/*fedeiglesias.com/*.fedeiglesias.com.cer --key-file /etc/nginx/acme.sh/*fedeiglesias.com/*.fedeiglesias.com.key --fullchain-file /etc/nginx/acme.sh/*fedeiglesias.com/fullchain.cer`

`service nginx reload`
