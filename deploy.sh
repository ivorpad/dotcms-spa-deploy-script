#!/bin/bash

read_var() {
    VAR=$(grep $1 $2 | xargs)
    IFS="=" read -ra VAR <<< "$VAR"
    echo ${VAR[1]}
}

DEPLOY_ENDPOINT=$(read_var DEPLOY_ENDPOINT .env)

echo "Cloning the SPA repository"
git clone https://github.com/dotCMS/dotcms-spa.git
cd dotcms-spa

echo "Removing existing Vercel environment variable"
expect <<- DONE
  set timeout -1

  spawn vercel env rm BEARER_TOKEN
  sleep 1
  send "a"
  send -- "\n"
  sleep 1
  expect "Removing Environment Variable*"
  send "y"
  send "\n"
  expect eof
DONE

echo "Fetching new access token"
token=$(curl -k -H "Content-Type:application/json" -X POST -d  '{ "user":"admin@dotcms.com", "password":"admin", "expirationDays": 10 }' https://demo.dotcms.com/api/v1/authentication/api-token | jq -r '.entity.token')

echo "Setting Vercel environment variable"
expect <<- DONE
 set timeout -1

 spawn vercel env add BEARER_TOKEN 
 expect "*the value of BEARER_TOKEN?"
 send -- "$token\r"
 expect "Add BEARER_TOKEN to which*"
 sleep 1
 send "a"
 send "\n"
 expect eof
DONE


touch .env
cat <<EOT >> .env
  BEARER_TOKEN="${token}"
  NEXT_PUBLIC_DOTCMS_HOST="https://starter.dotcms.com:8443"
EOT

echo "Preparing deploy"
vercel --prod

echo "Cleaning the files"
cd -
rm -rf ./dotcms-spa