#!/bin/bash

# determine when dotcms finishes deploy
# fetch a new access token from instance
# set environment variable in vercel
# trigger deploy hook in vercel

echo "Fetching access token"
# token=$(curl -k -H "Content-Type:application/json" -X POST -d  '{ "user":"admin@dotcms.com", "password":"admin", "expirationDays": 10 }' https://demo.dotcms.com/api/v1/authentication/api-token | ./jq -r '.entity.token')
 
echo "Setting Vercel environment variable"

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

expect <<- DONE
 set timeout -1

 spawn vercel env add BEARER_TOKEN 
 expect "What’s the value of BEARER_TOKEN?"
 send -- "123\r"
 sleep 1
 send "a"
 send -- "\n"
 expect eof
DONE