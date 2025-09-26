#!/bin/bash

echo Starting Llama server on port $1
ml ollama
ml genai
set -x
#export OLPORT=`ruby -e 'require "socket"; puts Addrinfo.tcp("", 0).bind {|s| s.local_address.ip_port }'`
export OLPORT=$1
echo $OLPORT
export OLLAMA_HOST=127.0.0.1:$OLPORT
export OLLAMA_BASE_URL="http://localhost:$OLPORT"
rm -f ollama.log
ollama serve >& ollama.log &
while [ $(wc -l ollama.log | cut -d' ' -f1 ) -lt 4 ]; do
       sleep 1;
done       
ollama run $2
#ollama serve >& ollama.log
