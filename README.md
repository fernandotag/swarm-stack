# Swarm Stack

Kit de ferramentas para gerenciamento, monitoramento, alertas e proxy reverso em clusters Docker Swarm. 

Ferramentas que permitirão:
* Monitorar uso de CPU, Memória, Disco e etc.
* Métricas por instancias, por serviço e por container.
* Controlar o cluster swarm através de uma ferramenta visual.
* Gerenciar acesso a serviços através de proxy reverso.
* Geração automática de certificado HTTPS.
* Definir regras em serviços e container para alertas via e-mail, slack, etc).  

Ferramentas para proxy reverso:
* [Traefik2](https://docs.traefik.io/)

Ferramentas para monitoramento:
* [Prometheus](https://prometheus.io/)
* [Grafana](http://grafana.org/)
* [cAdvisor](https://github.com/google/cadvisor)
* [Node Exporter](https://github.com/prometheus/node_exporter)
* [Alert Manager](https://github.com/prometheus/alertmanager)
* [Unsee](https://github.com/cloudflare/unsee)


Ferramenta para controle do Swarm
* [Portainer](https://www.portainer.io/)

Pré-requisitos:
* Docker CE 19.03 or Docker EE 19.03
* Cluster Swarm instalado 

## Instalação

Por padrão não é possível obter métricas através dos nós do cluster, é preciso especificar o `metrics-address`.
E a melhor maneira segundo a documentação oficial do Docker é criando o editando o arquivo `/etc/docker/daemon.json`.

Se o arquivo estiver vazio cole o json abaixo:
```bash
{
  "metrics-addr" : "127.0.0.1:9323",
  "experimental" : true
}
```
Caso já exista conteúdo, cole as duas chaves no json já existente.
Mais informações, acesse a [documentação oficial](https://docs.docker.com/config/daemon/prometheus/).

Para iniciar a instalação do kit, clone esse repositório:

```bash
$ git clone https://github.com/fernandotag/swarm-stack.git
$ cd swarm-stack
```

Crie as variáveis de ambiente:

```bash
$ vi .env

DOMAINNAME=seudominio.com.br
PUID=1000
PGID=140
TZ="America/Sao_paulo"
USERDIR="/home/seu-usuario"
```

### Proxy Reverso

Crie uma senha criptografada para utilizar de acesso nas páginas protegidas pelos middlewares do traefik2:

```bash
$ sudo apt-get install apache2-utils
$ htpasswd -nb admin senha-segura
```

A saída sera algo parecido com isso:
```
admin:$89eqM5Ro$CxaFELthUKV21DpI3UTQO.
```

Utilize a saída no arquivo .htpasswd que será utilizado para gerar uma secret
```bash
$ cd proxy-reverso/secrets
$ vi .htpasswd

cole a saída do comando htpasswd: admin:token
```
Caso esteja utilizando um ambiente de testes, configure a obtenção automática de certificado através do LetsEncrypt descomente e comente as seguintes linhas no arquivo `reverse-proxy/stack-reverse-proxy.yml`:
```bash
  - --certificatesResolvers.dns-cloudflare.acme.caServer=https://acme-staging-v02.api.letsencrypt.org/directory 

# - --certificatesResolvers.dns-cloudflare.acme.email=/run/secrets/cf_api_email
# - --certificatesResolvers.dns-cloudflare.acme.storage=/acme.json
# - --certificatesResolvers.dns-cloudflare.acme.dnsChallenge.provider=cloudflare
# - --certificatesResolvers.dns-cloudflare.acme.dnsChallenge.resolvers=1.1.1.1:53,1.0.0.1:53
```

Para obter certificado SSL via DNS Cloudflare insira os dados no arquivos que serão utilizados para gerar secrets do swarm.
```bash
$ cd proxy-reverso/secrets
$ vi cf_api_email.txt

cole seu email cadastrado no cloudflare

$ cd proxy-reverso/secrets
$ vi cf_api_key.txt

cole sua api key no cloudflare
```
E também descomente e comente as linhas no arquivo `reverse-proxy/stack-reverse-proxy.yml`:
```bash
# - --certificatesResolvers.dns-cloudflare.acme.caServer=https://acme-staging-v02.api.letsencrypt.org/directory  
  
  - --certificatesResolvers.dns-cloudflare.acme.email=/run/secrets/cf_api_email
  - --certificatesResolvers.dns-cloudflare.acme.storage=/acme.json
  - --certificatesResolvers.dns-cloudflare.acme.dnsChallenge.provider=cloudflare
  - --certificatesResolvers.dns-cloudflare.acme.dnsChallenge.resolvers=1.1.1.1:53,1.0.0.1:53
```

Parar realizar o deploy do proxy reverso (Traefik2) execute o comando baixo:
```bash
$ sh reverse-proxy/deploy.sh
```

### Portainer

Parar realizar o deploy da stack do Portainer execute o comando baixo:
```bash
$ sh portainer/deploy.sh
```

### Monitoramento e alertas

Crie um arquivo de configuração do AlertManager para o deploy utilizar na criação de uma secret do swarm:
```bash
$ cd metrics/alertmanager/secrets
$ vi alertmanager_config.yml

route:
  group_by: [alertname, severity]
  receiver: slack

receivers:
  - name: 'slack'
    slack_configs:
    - api_url: 'https://hooks.slack.com/services/<sua_token>'
      username: 'Alertmanager'
      channel: '#prometheus-alerts'
      title: |-
        [{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .CommonLabels.alertname }} for {{ .CommonLabels.job }}
        {{- if gt (len .CommonLabels) (len .GroupLabels) -}}
          {{" "}}(
          {{- with .CommonLabels.Remove .GroupLabels.Names }}
            {{- range $index, $label := .SortedPairs -}}
              {{ if $index }}, {{ end }}
              {{- $label.Name }}="{{ $label.Value -}}"
            {{- end }}
          {{- end -}}
          )
        {{- end }}
      text: >-
        {{ with index .Alerts 0 -}}
          :chart_with_upwards_trend: *<{{ .GeneratorURL }}|Graph>*
          {{- if .Annotations.runbook }}   :notebook: *<{{ .Annotations.runbook }}|Runbook>*{{ end }}
        {{ end }}

        *Alert details*:

        {{ range .Alerts -}}
          *Alert:* {{ .Annotations.title }}{{ if .Labels.severity }} - `{{ .Labels.severity }}`{{ end }}
        *Description:* {{ .Annotations.description }}
        *Details:*
          {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
          {{ end }}
        {{ end }}
```

Outros modelos de mensagem a ser enviada podem ser criados nesse site:
https://juliusv.com/promslack/


Para criar uma token no slack, basta seguir esse tutorial oficial do Slack:
https://api.slack.com/tutorials/slack-apps-hello-world

Parar realizar o deploy da stack das ferramentas de monitoramento execute o comando baixo:
```bash
$ sh metrics/deploy.sh
```

## Acesso as ferramentas

* `https://portainer.seu-dominio.com`
* `https://grafana.seu-dominio.com`
* `https://unsee.seu-dominio.com`
* `https://prometheus.seu-dominio.com`


## Referências

* https://docs.docker.com/
* https://github.com/stefanprodan/swarmprom
* https://www.smarthomebeginner.com/traefik-2-docker-tutorial/#Portainer_with_Traefik_2_and_OAuth






