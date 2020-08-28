HOST_URL="demo.dotcms.com"

set -o allexport; source .env; set +o allexport

echo ${TEAM_ID}

echo "Creating dotcms-spa dir"
mkdir dotcms-spa
cd dotcms-spa
mkdir .vercel
cd .vercel
touch project.json
cat <<EOT >> project.json
  {"orgId":"${TEAM_ID}","projectId":"${PROJECT_ID}"}
EOT
cd -

echo "Removing existing Vercel environment variable"
expect <<- DONE
  set timeout -1

  spawn vercel --token ${VERCEL_TOKEN} env rm BEARER_TOKEN
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

 spawn vercel --token ${VERCEL_TOKEN} env add BEARER_TOKEN
 expect "*the value of BEARER_TOKEN?"
 send -- "$token\r"
 expect "Add BEARER_TOKEN to which*"
 sleep 1
 send "a"
 send "\n"
 expect eof
DONE

echo "Triggering a build in Vercel"
curl -X POST ${DEPLOY_HOOK}
echo "\n"
echo "🧹 Cleaning up the files"
cd ~/development/deploy_script
rm -rf dotcms-spa/