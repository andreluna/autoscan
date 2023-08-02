#!/bin/bash

# bash param: -exu

# Verifica se foi fornecido o nome do arquivo como argumento
if [ $# -ne 1 ]
then
  echo "Uso: $0 <caminho_do_arquivo>"
  exit 1
fi
# 
# arquivo txt com a lista dos domínios
domains_list=$(cat $1)
#
date_now=$(date '+%d-%m-%Y')
#
# ###########################################################################
# ###########################################################################
#
# Uso do script:
# ./autoscan.sh /targets/sites.txt
#
# ###########################################################################
# ###########################################################################
# link do binário dos softwares
# https://github.com/projectdiscovery/subfinder
# https://github.com/projectdiscovery/httpx
# https://github.com/projectdiscovery/nuclei
#
version_subfinder="2.6.1"
version_httpx="1.3.4"
version_nuclei="2.9.10"
projectdiscovery_url="https://github.com/projectdiscovery"
# ###########################################################################
# ###########################################################################
# Configurações do Nuclei
#
#
# Apenas as tags selecionadas
# Referência: https://github.com/projectdiscovery/nuclei-templates/blob/main/TEMPLATES-STATS.md
# 
# nuclei_tags="cve,xss,lfi,misconfig,rce,wpscan,wp,sqli,config,default-login,ssrf,auth-bypass,jira,injection,sap,log4j,api,manageengine,stored-xss,zoho,tomcat,weblogic,jenkins,xxe,nginx,citrix,mail,jboss,login-check,git,graphql,dashboard,phpmyadmin,glpi"
# 
nuclei_tags="cve,xss,lfi,rce,sqli,default-login,ssrf,injection,stored-xss,xxe"
# nuclei_tags="cve"
#
# Apenas as tags selecionadas
#
#
# user-agent select
# 
# nuclei_user_agent="bug-bounty program - hackerone.com platform/2023"
# nuclei_user_agent="bug-bounty program - intigriti.com platform/2023"
# nuclei_user_agent="bug-bounty program - bughunt.com.br platform/2023"
nuclei_user_agent="Opera/9.80 (Windows NT 6.1; Twitterbot) Presto/2.12.388 Version/12.15"
# nuclei_user_agent="Mozilla/5.0 (Linux; Android 13; SM-S901B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36"
# 
#
# Configurações do Nuclei
# ###########################################################################
# ###########################################################################
os_system="$(uname -s)" # Darwin ou Linux

if [ $os_system == "Darwin" ]
    then 
    project_subfinder="$projectdiscovery_url/subfinder/releases/download/v${version_subfinder}/subfinder_${version_subfinder}_macOS_amd64.zip"
    project_httpx="$projectdiscovery_url/httpx/releases/download/v${version_httpx}/httpx_${version_httpx}_macOS_amd64.zip"
    project_nuclei="$projectdiscovery_url/nuclei/releases/download/v${version_nuclei}/nuclei_${version_nuclei}_macOS_amd64.zip"
else
    project_subfinder="$projectdiscovery_url/subfinder/releases/download/v${version_subfinder}/subfinder_${version_subfinder}_linux_amd64.zip"
    project_httpx="$projectdiscovery_url/httpx/releases/download/v${version_httpx}/httpx_${version_httpx}_linux_amd64.zip"
    project_nuclei="$projectdiscovery_url/nuclei/releases/download/v${version_nuclei}/nuclei_${version_nuclei}_linux_amd64.zip"
fi

donwload_subfinder(){
    wget -q $project_subfinder
    version=$(echo $project_subfinder | cut -d "/" -f9)
    unzip $version
    chmod +x subfinder
}

donwload_httpx(){
    wget -q $project_httpx
    version=$(echo $project_httpx | cut -d "/" -f9)
    unzip $version
    chmod +x httpx
}

donwload_nuclei(){
    wget -q $project_nuclei
    version=$(echo $project_nuclei | cut -d "/" -f9)
    unzip $version
    chmod +x nuclei
    #./nuclei -up
    ./nuclei -update-templates
    rm *.zip && rm *.md
}

remove_binarys(){
    # deletando os binários
    rm subfinder
    rm httpx
    rm nuclei
    rm -rf wget*
}

scan_start_alert(){
    time_now_start=$(date +"%T")
    echo "========================================================================" > /tmp/start
    echo "[+] scan iniciado | $date_now | $time_now_start" >> /tmp/start
    echo "$domains_list " >> /tmp/start
    echo "========================================================================" >> /tmp/start
    ./slack_webhook.sh /tmp/start
    rm /tmp/start
}

# chamando as funções para download
donwload_subfinder
donwload_httpx
donwload_nuclei
# chamando as funções para download

# criando os diretórios para receber os outputs
#mkdir subfinder_outputs
mkdir -p subfinder_outputs/archive-$date_now
#mkdir httpx_outputs
mkdir -p httpx_outputs/archive-$date_now
#mkdir nuclei_outputs
mkdir -p nuclei_outputs/archive-$date_now
# criando os diretórios para receber os outputs

# chamando função para enviar alerta ao Slack
scan_start_alert
# chamando função para enviar alerta ao Slack

# ###########################################################################
# ###########################################################################
# lendo a lista de domínios em txt e passando seu valor para $line
#
for line in $domains_list
do
    ./subfinder -d $line -silent -o subfinder_outputs/archive-$date_now/$line.txt

    ./httpx -mc 200,201,202,203,204,205,206,207,208,307 -silent -list subfinder_outputs/archive-$date_now/$line.txt -o httpx_outputs/archive-$date_now/$line.txt

    ./nuclei -list httpx_outputs/archive-$date_now/$line.txt -rl 55 -c 26 -hbs 8 -fhr -etags ssl -tags $nuclei_tags -s high,critical,medium -H $nuclei_user_agent -o nuclei_outputs/archive-$date_now/$line.txt
# fim do loop
done
# ###########################################################################
# ###########################################################################

# chamando função para deletar os binários
remove_binarys
# chamando função para deletar os binários

# salvando todos os finds no arquivo check-results-*.txt
cd nuclei_outputs/archive-$date_now
for i in $(ls -1); do cat $i >> check-result-$date_now.txt; done
# salvando todos os finds no arquivo check-results-*.txt

# verificando se o arquivo de checagem não está vazio, caso não, envia push para o bot
if [ -s check-result-$date_now.txt ]
    then 
        cd ../..
        ./slack_webhook.sh nuclei_outputs/archive-$date_now/check-result-$date_now.txt
    else
        time_now_finish=$(date +"%T")
        echo "[+] scan finalizado | $date_now | $time_now_finish"  > /tmp/finish
        echo "========================================================================" >> /tmp/finish
        cd ../..
        ./slack_webhook.sh /tmp/finish
        rm /tmp/finish
fi
# verificando se o arquivo de checagem não está vazio, caso não, envia push para o bot
