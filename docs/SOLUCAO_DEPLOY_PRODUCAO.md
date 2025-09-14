# Solução para Deploy em Produção - Ticketz

## Problemas Identificados

### 1. **Erro Principal**: Hostname "backend" não encontrado
```
nginx: [emerg] host not found in upstream "backend" in /etc/nginx/sites.d/frontend.conf:12
```

### 2. **Warnings**: Extensões duplicadas no mimetypes.conf
Múltiplos warnings sobre extensões duplicadas (não crítico, mas pode ser limpo).

## Soluções

### Solução 1: Corrigir Configuração do Nginx Frontend

O problema está no arquivo `/etc/nginx/sites.d/frontend.conf` que está tentando resolver o hostname "backend", mas no seu ambiente de produção o container se chama "helpdesk-api-prd-latest".

#### Arquivo: `frontend/nginx/sites.d/frontend.conf` (Corrigido)

```nginx
location / {
    try_files $uri $uri/ /index.html;
    include include.d/nocache.conf;
}

location /static {
   alias /var/www/public/static/;
   include include.d/allcache.conf;
}

location /manifest.json {
    proxy_pass http://helpdesk-api-prd-latest:3000/manifest.json;
}

location /socket.io/ {
    proxy_pass http://helpdesk-api-prd-latest:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host $host;
}

location /backend/public/ {
    add_header Content-Disposition 'attachment';
    alias /var/www/backend-public/;
    include include.d/allcache.conf;
}

location /backend/ {
    rewrite ^/backend/(.*) /$1 break;
    proxy_pass http://helpdesk-api-prd-latest:3000;
}

include ticketz.d/*.conf;
include "include.d/spa.conf";
```

### Solução 2: Docker Compose Otimizado para Produção

```yaml
networks:
  nebula-net:
    external: true

services:
  helpdesk-latest:
    image: nebulasistemas/helpdesk-frontend:prd-latest
    container_name: helpdesk-latest
    hostname: helpdesk-latest
    restart: always
    ports:
      - 127.0.0.1:48080:80
    env_file:
      - ./env/.env-frontend
    environment:
      BACKEND_HOST: api-helpdesk.sistemasnebula.com.br
      BACKEND_SERVICE: helpdesk-api-prd-latest  # Adicionar esta variável
    networks:
      - nebula-net

  helpdesk-api-prd-latest:
    image: nebulasistemas/helpdesk-backend:prd-latest
    container_name: helpdesk-api-prd-latest
    hostname: helpdesk-api-prd-latest
    restart: always
    ports:
      - 127.0.0.1:48081:3000
    env_file:
      - ./env/.env-backend
    environment:
      BACKEND_URL: https://api-helpdesk.sistemasnebula.com.br
      FRONTEND_URL: https://helpdesk.sistemasnebula.com.br
      TZ: America/Sao_Paulo
      USER_LIMIT: 10000
      CONNECTIONS_LIMIT: 100000
      CLOSED_SEND_BY_ME: "true"
      VERIFY_TOKEN: ticketz
      SOCKET_ADMIN: "true"
    networks:
      - nebula-net
    depends_on:
      - helpdesk-latest
```

### Solução 3: Configuração Nginx Dinâmica

Criar um arquivo de configuração que use variáveis de ambiente:

#### Arquivo: `frontend/nginx/sites.d/frontend-dynamic.conf`

```nginx
location / {
    try_files $uri $uri/ /index.html;
    include include.d/nocache.conf;
}

location /static {
   alias /var/www/public/static/;
   include include.d/allcache.conf;
}

location /manifest.json {
    proxy_pass http://${BACKEND_SERVICE:-backend}:3000/manifest.json;
}

location /socket.io/ {
    proxy_pass http://${BACKEND_SERVICE:-backend}:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host $host;
}

location /backend/public/ {
    add_header Content-Disposition 'attachment';
    alias /var/www/backend-public/;
    include include.d/allcache.conf;
}

location /backend/ {
    rewrite ^/backend/(.*) /$1 break;
    proxy_pass http://${BACKEND_SERVICE:-backend}:3000;
}

include ticketz.d/*.conf;
include "include.d/spa.conf";
```

### Solução 4: Limpar Warnings do mimetypes.conf

#### Arquivo: `frontend/nginx/conf.d/mimetypes-clean.conf`

```nginx
types {
  # Data interchange
  application/atom+xml                  atom;
  application/json                      json map topojson;
  application/ld+json                   jsonld;
  application/rss+xml                   rss;
  application/geo+json                  geojson;
  application/xml                       xml;
  application/rdf+xml                   rdf;

  # JavaScript
  text/javascript                       js mjs;
  application/wasm                      wasm;

  # Manifest files
  application/manifest+json             webmanifest;
  application/x-web-app-manifest+json   webapp;
  text/cache-manifest                   appcache;

  # Media files
  audio/midi                            mid midi kar;
  audio/mp4                             f4a f4b m4a;
  audio/x-aac                           aac;
  audio/mpeg                            mp3;
  audio/ogg                             oga ogg opus;
  audio/x-realaudio                     ra;
  audio/x-wav                           wav;
  image/apng                            apng;
  image/avif                            avif avifs;
  image/bmp                             bmp;
  image/gif                             gif;
  image/jpeg                            jpeg jpg;
  image/jxl                             jxl;
  image/jxr                             jxr hdp wdp;
  image/png                             png;
  image/svg+xml                         svg svgz;
  image/tiff                            tif tiff;
  image/vnd.wap.wbmp                    wbmp;
  image/webp                            webp;
  image/x-jng                           jng;
  video/3gpp                            3gp 3gpp;
  video/mp4                             f4p f4v m4v mp4;
  video/mpeg                            mpeg mpg;
  video/ogg                             ogv;
  video/quicktime                       mov;
  video/webm                            webm;
  video/x-flv                           flv;
  video/x-mng                           mng;
  video/x-ms-asf                        asf asx;
  video/x-msvideo                       avi;
  image/x-icon                          cur ico;

  # Microsoft Office
  application/msword                                                         doc;
  application/vnd.ms-excel                                                   xls;
  application/vnd.ms-powerpoint                                              ppt;
  application/vnd.openxmlformats-officedocument.wordprocessingml.document    docx;
  application/vnd.openxmlformats-officedocument.spreadsheetml.sheet          xlsx;
  application/vnd.openxmlformats-officedocument.presentationml.presentation  pptx;

  # Web fonts
  font/woff                             woff;
  font/woff2                            woff2;
  application/vnd.ms-fontobject         eot;
  font/ttf                              ttf;
  font/collection                       ttc;
  font/otf                              otf;

  # Other
  application/java-archive              ear jar war;
  application/mac-binhex40              hqx;
  application/octet-stream              bin deb dll dmg exe img iso msi msm msp safariextz;
  application/pdf                       pdf;
  application/postscript                ai eps ps;
  application/rtf                       rtf;
  application/vnd.google-earth.kml+xml  kml;
  application/vnd.google-earth.kmz      kmz;
  application/vnd.wap.wmlc              wmlc;
  application/x-7z-compressed           7z;
  application/x-bb-appworld             bbaw;
  application/x-bittorrent              torrent;
  application/x-chrome-extension        crx;
  application/x-cocoa                   cco;
  application/x-java-archive-diff       jardiff;
  application/x-java-jnlp-file          jnlp;
  application/x-makeself                run;
  application/x-opera-extension         oex;
  application/x-perl                    pl pm;
  application/x-pilot                   pdb prc;
  application/x-rar-compressed          rar;
  application/x-redhat-package-manager  rpm;
  application/x-sea                     sea;
  application/x-shockwave-flash         swf;
  application/x-stuffit                 sit;
  application/x-tcl                     tcl tk;
  application/x-x509-ca-cert            crt der pem;
  application/x-xpinstall               xpi;
  application/xhtml+xml                 xhtml;
  application/xslt+xml                  xsl;
  application/zip                       zip;
  text/calendar                         ics;
  text/css                              css;
  text/csv                              csv;
  text/html                             htm html shtml;
  text/markdown                         md markdown;
  text/mathml                           mml;
  text/plain                            txt;
  text/vcard                            vcard vcf;
  text/vnd.rim.location.xloc            xloc;
  text/vnd.sun.j2me.app-descriptor      jad;
  text/vnd.wap.wml                      wml;
  text/vtt                              vtt;
  text/x-component                      htc;
}
```

## Passos para Implementar a Solução

### 1. **Reconstruir a Imagem Frontend**

```bash
# 1. Corrigir o arquivo frontend/nginx/sites.d/frontend.conf
# Substituir "backend" por "helpdesk-api-prd-latest"

# 2. Rebuild da imagem frontend
docker build -t nebulasistemas/helpdesk-frontend:prd-latest ./frontend

# 3. Push para registry (se necessário)
docker push nebulasistemas/helpdesk-frontend:prd-latest
```

### 2. **Atualizar Docker Compose**

```bash
# Parar containers atuais
docker compose down

# Atualizar com nova configuração
docker compose up -d
```

### 3. **Verificar Logs**

```bash
# Verificar logs do frontend
docker logs helpdesk-latest

# Verificar logs do backend
docker logs helpdesk-api-prd-latest

# Verificar conectividade
docker exec helpdesk-latest nslookup helpdesk-api-prd-latest
```

## Configuração Nginx do Servidor (Atualizada)

```nginx
server {
  listen 80;
  server_name helpdesk.sistemasnebula.com.br;

  resolver 127.0.0.11 valid=30s;

  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass         http://helpdesk-latest:80;
  }
}

server {
  listen 80;
  server_name api-helpdesk.sistemasnebula.com.br;

  resolver 127.0.0.11 valid=30s;

  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass         http://helpdesk-api-prd-latest:3000;
  }
}
```

## Verificação Final

Após implementar as correções:

1. **Testar conectividade**:
   ```bash
   curl -I http://helpdesk.sistemasnebula.com.br
   curl -I http://api-helpdesk.sistemasnebula.com.br
   ```

2. **Verificar logs**:
   ```bash
   docker logs helpdesk-latest --tail 50
   ```

3. **Testar funcionalidades**:
   - Login no sistema
   - WebSocket (chat em tempo real)
   - Upload de arquivos
   - API endpoints

## Resumo das Correções

✅ **Problema Principal**: Hostname "backend" → "helpdesk-api-prd-latest"  
✅ **Warnings**: Limpeza do mimetypes.conf  
✅ **Configuração**: Docker Compose otimizado  
✅ **Nginx**: Configuração dinâmica com variáveis de ambiente  

Com essas correções, o sistema deve funcionar corretamente em produção.
