HOST_URL="demo.dotcms.com"

echo "Creating dotcms-spa dir"
mkdir dotcms-spa
cd dotcms-spa
mkdir .vercel
cd .vercel
touch project.json
cat <<EOT >> project.json
  {"orgId":"redacted","projectId":"redacted"}
EOT
cd -

echo "Removing existing Vercel environment variable"
expect <<- DONE
  set timeout -1

  spawn vercel --token redacted env rm BEARER_TOKEN
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
token=$(curl -H "Content-Type:application/json" -s  -X POST -d  '{ "user":"admin@dotcms.com", "password":"admin", "expirationDays": 10 }' https://${HOST_URL}/api/v1/authentication/api-token | python -c 'import json,sys; print(json.load(sys.stdin)["entity"]["token"])')

echo "Setting Vercel environment variable"
expect <<- DONE
 set timeout -1

 spawn vercel --token redacted env add BEARER_TOKEN
 expect "*the value of BEARER_TOKEN?"
 send -- "$token\r"
 expect "Add BEARER_TOKEN to which*"
 sleep 1
 send "a"
 send "\n"
 expect eof
DONE

echo "Cleaning up the files"
cd ~/deploy
rm -rf dotcms-spa/