rm -f out
mkfifo out
trap "rm -f out" EXIT
while true
do
  cat out | nc -l 1500 > >( # parse the netcat output, to build the answer redirected to the pipe "out".
    export REQUEST=
    while read -r line
    do
      line=$(echo "$line" | tr -d '\r\n')
      
      if echo "$line" | grep -qE '^GET /' # if line starts with "GET /"
      then
        REQUEST=$(echo "$line" | cut -d ' ' -f2) # extract the request

      elif [ -z "$line" ] # empty line / end of request
      then
        # call a script here
        # Note: REQUEST is exported, so the script can parse it (to answer 200/403/404 status code + content)
        # ./a_script.sh > out
        echo "${REQUEST:1}"

        if echo "$REQUEST" | grep -qE '^favicon' # if line starts with "GET /"
        then
          #do nothing - no favicon to display
          DATA=""
        elif echo "$REQUEST" | grep -qE '^quoteImport.url' # if line starts with "GET /"
        then
          DATA=$(cat /..path../application.properties | grep "^paramName" | cut -d '=' -f2)
          #additional custom processing
        else
          DATA=$(cat /..path../application.properties | grep "^${REQUEST:1}" | cut -d '=' -f2)     
        fi  

        HDATA="<html><head></head><body>${DATA}</body></html>"
        LENGTH=$(echo $HDATA | wc -c);
        #echo "Content-type: text/html" 
        echo -e "HTTP/1.1 200 OK\nContent-type: text/html\nContent-Length: ${LENGTH}\n\n${HDATA}" > out
        
      fi
    done
  )
done
