#!/bin/bash

# do ". acd_func.sh"
# acd_func 1.0.5, 10-nov-2004
# petar marinov, http:/geocities.com/h2428, this is public domain

cd_func ()
{
  local x2 the_new_dir adir index
  local -i cnt

  if [[ $1 ==  "--" ]]; then
    dirs -v
    return 0
  fi

  the_new_dir=$1
  [[ -z $1 ]] && the_new_dir=$HOME

  if [[ ${the_new_dir:0:1} == '-' ]]; then
    #
    # Extract dir N from dirs
    index=${the_new_dir:1}
    [[ -z $index ]] && index=1
    adir=$(dirs +$index)
    [[ -z $adir ]] && return 1
    the_new_dir=$adir
  fi

  #
  # '~' has to be substituted by ${HOME}
  [[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

  #
  # Now change to the new dir and add to the top of the stack
  pushd "${the_new_dir}" > /dev/null
  [[ $? -ne 0 ]] && return 1
  the_new_dir=$(pwd)

  #
  # Trim down everything beyond 11th entry
  popd -n +11 2>/dev/null 1>/dev/null

  #
  # Remove any other occurence of this dir, skipping the top of the stack
  for ((cnt=1; cnt <= 10; cnt++)); do
    x2=$(dirs +${cnt} 2>/dev/null)
    [[ $? -ne 0 ]] && return 0
    [[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
    if [[ "${x2}" == "${the_new_dir}" ]]; then
      popd -n +$cnt 2>/dev/null 1>/dev/null
      cnt=cnt-1
    fi
  done

  return 0
}

alias cd=cd_func

if [[ $BASH_VERSION > "2.05a" ]]; then
  # ctrl+w shows the menu
  bind -x "\"\C-w\":cd_func -- ;"
fi

# END of cd_func util

echo "Cloning the SPA repository"
git clone https://github.com/dotCMS/dotcms-spa.git
cd dotcms-spa
mkdir .vercel
cd .vercel
touch project.json
cat <<EOT >> project.json
  {"orgId":"<team_id>","projectId":"<token_id>"}
EOT
cd -

echo "Removing existing Vercel environment variable"
expect <<- DONE
  set timeout -1

  spawn vercel --token <vercel_token> env rm BEARER_TOKEN
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
token=$(curl -H "Content-Type:application/json" -s  -X POST -d  '{ "user":"admin@dotcms.com", "password":"admin", "expirationDays": 10 }' https://demo.dotcms.com/api/v1/authentication/api-token | python -c 'import json,sys; print(json.load(sys.stdin)["entity"]["token"])')

echo "Setting Vercel environment variable"
expect <<- DONE
 set timeout -1

 spawn vercel --token <vercel_token> env add BEARER_TOKEN
 expect "*the value of BEARER_TOKEN?"
 send -- "$token\r"
 expect "Add BEARER_TOKEN to which*"
 sleep 1
 send "a"
 send "\n"
 expect eof
DONE

echo "Setting up local env variables"
touch .env
cat <<EOT >> .env
  BEARER_TOKEN="${token}"
  NEXT_PUBLIC_DOTCMS_HOST="https://starter.dotcms.com:8443"
EOT

echo "Preparing deploy"
vercel --token <vercel_token> --prod

echo "Cleaning up the files"
cd -2
rm -rf dotcms-spa/