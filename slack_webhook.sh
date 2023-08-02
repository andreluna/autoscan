#!/bin/bash

# Criando um webhook para o Slack
# https://api.slack.com/incoming-webhooks
# https://www.youtube.com/watch?v=sxtC40gUS2A
#
token_slack="<CHAVE-AQUI>"
#
# Verifica se foi fornecido o nome do arquivo como argumento
if [ $# -ne 1 ]; then
  echo "Uso: $0 <caminho_do_arquivo>"
  exit 1
fi

# Armazena o webhook do Slack
webhook_url="https://hooks.slack.com/services/$token_slack"

# Extrai o conteúdo do arquivo fornecido por linha e envia para o Slack
while IFS= read -r line
do
  echo $line
  # Monta o payload para enviar a mensagem no formato JSON
  payload="{\"text\":\"$line\"}"

  # Envia a mensagem para o webhook do Slack usando o curl
  curl -s -X POST -H 'Content-type: application/json' --data "$payload" "$webhook_url"
done < "$1"

