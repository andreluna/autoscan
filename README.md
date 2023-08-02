# Autoscan (Linux/MacOS)

Scan de vulnerabilidade, utiliza basicamente os projetos Subfinder, Httpx e Nuclei.

Subfinder tem por objetivo enumerar todos os domínios relacionadas. É uma boa dica colocar suas chaves de API no arquivo ```$HOME/.config/subfinder/provider-config.yaml``` para conseguir melhores resultados.

HTTPX vai pegar a lista gerada pelo Subfinder e verificar quais urls tem algum serviço rodando. 

E o Nuclei vai de fato executar um scan de vulnerabilidades nos domínios localizados pelo HTTPX. 

Todo o resultado será enviado via WebHook (API Slack) para um canal configurado.
O script que faz isso é o ```slack_webhook.sh```.
Será preciso colocar o TOKEN gerado para que o Bot consiga enviar a mensagem para o canal.

Referências:

```
https://api.slack.com/incoming-webhooks
https://www.youtube.com/watch?v=sxtC40gUS2A
```

**variável: token_slack**

``` 
#!/bin/bash

# Criando um webhook para o Slack
(...)

token_slack="PhKPGCh/3mmussuQrsLypua-08u9QrVCvDfrczC"
#

fi (...)
```

O ```autoscan.sh``` é o script principal. Seu uso é muito simples: 

Utilização:
```
./autscan.sh targets/websites.txt
```

No arquivo com os sites, cada um deve ser inserido linha por linha, exemplo:

```
hackerone.com
intigriti.com
meusite.com
seusite.net
```

## Resultados:

Todos os resultados ficam salvos em arquivos com a data.

Saída Subfinder:
```
root@ec2-server:/opt/autoscan/subfinder_outputs/archive-28-07-2023# ls -1
intigriti.com.txt
hackerone.com.txt
```

Saída Httpx:

```
root@ec2-server:/opt/autoscan/httpx_outputs/archive-28-07-2023# ls -1
intigriti.com.txt
hackerone.com.txt
```

Saída Nuclei:

```
root@ec2-server:/opt/autoscan//nuclei_outputs/archive-01-08-2023# ls -ls che*
4 -rw-r--r-- 1 root root 2469 Aug  1 17:47 check-result-01-08-2023.txt
```

**Observação:**

O Nuclei localizando vulnerabilidades, eles vão ficar salvas em um arquivo chamado **check-results-DIA-MÊS-ANO.txt** e o resultado será enviado linha por linha para o canal no Slack.


## Alterando a versão:

Para modificar a versão de alguns dos software, basta alterar o número da versão no arquivo.

```
(...)
#
version_subfinder="2.6.1"
version_httpx="1.3.4"
version_nuclei="2.9.10"
projectdiscovery_url="https://github.com/projectdiscovery"
(...)
```


## Ferramentas utilizadas

[Subfinder](https://github.com/projectdiscovery/subfinder)
[Httpx](https://github.com/projectdiscovery/httpx)
[Nuclei](https://github.com/projectdiscovery/nuclei)
