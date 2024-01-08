NUM_CONNECTIONS=1
endpoint_list=$(ansible-inventory -i hosts --export --list | jq '[.[] | .hostvars][0]' | grep name -B 1  | grep internal_ip | sed 's/\"//g' | cut -w -f3 | sed 's/,//' | sed 's/\(.*\)/ws:\/\/\1:26657\/websocket/')

IFS='
'
set -f
endpoints=()
for line in $endpoint_list; do
  endpoints+=($line)
done
set +f
unset IFS

finalEndpoints=()
for((i=0;i < ${#endpoints[*]} && i < NUM_CONNECTIONS; i++)); do
   finalEndpoints+=(${endpoints[$i]})
done

endpoints_string="${finalEndpoints[*]}"
echo "${endpoints_string// /,}"
