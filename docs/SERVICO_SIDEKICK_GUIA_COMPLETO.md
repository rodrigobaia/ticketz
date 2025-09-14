# Guia Completo - Serviço Sidekick Ticketz

## Visão Geral

O **Sidekick** é um serviço auxiliar essencial do Ticketz responsável por **backup e restauração de dados** em ambientes de produção. Este documento fornece um guia completo sobre sua configuração, uso e melhores práticas.

## 1. O que é o Sidekick?

### 1.1 Definição
O Sidekick é um container Docker especializado que executa operações de:
- **Backup automático** de dados do sistema
- **Restauração** de dados de backups
- **Manutenção** do banco de dados
- **Limpeza** de sessões WhatsApp

### 1.2 Características Técnicas
- **Imagem**: `ghcr.io/ticketz-oss/ticketz-sidekick:latest`
- **Profile**: `["do-not-start"]` (não inicia automaticamente)
- **Dependências**: PostgreSQL
- **Volumes**: Acesso a dados do backend e pastas de backup

## 2. Configuração no Docker Compose

### 2.1 Configuração Básica (Desenvolvimento)
```yaml
sidekick:
  image: ghcr.io/ticketz-oss/ticketz-sidekick:latest
  profiles: ["do-not-start"]
  env_file:
    - .env-backend-local
  restart: unless-stopped
  volumes:
    - backend_public:/backend-public
    - backend_private:/backend-private
    - ./backups:/backups
    - ./retrieve:/retrieve
  depends_on:
    - postgres
  networks:
    - ticketz
```

### 2.2 Configuração Recomendada para Produção
```yaml
networks:
  nebula-net:
    external: true

volumes:
  helpdesk_backend_public:
  helpdesk_backend_private:
  helpdesk_backups:
  helpdesk_retrieve:

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
    volumes:
      - helpdesk_backend_public:/var/www/backend-public
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
    volumes:
      - helpdesk_backend_public:/usr/src/app/public
      - helpdesk_backend_private:/usr/src/app/private
    networks:
      - nebula-net
    depends_on:
      - helpdesk-latest

  # Serviço de Backup e Restauração
  helpdesk-sidekick:
    image: ghcr.io/ticketz-oss/ticketz-sidekick:latest
    container_name: helpdesk-sidekick
    hostname: helpdesk-sidekick
    profiles: ["backup"]  # Inicia apenas quando solicitado
    restart: unless-stopped
    env_file:
      - ./env/.env-backend
    environment:
      BACKUP_ENCRYPTION_KEY: "sua-chave-secreta-aqui"
      BACKUP_RETENTION_DAYS: "30"
      BACKUP_COMPRESSION: "gzip"
    volumes:
      - helpdesk_backend_public:/backend-public
      - helpdesk_backend_private:/backend-private
      - helpdesk_backups:/backups
      - helpdesk_retrieve:/retrieve
      - ./backups:/backups-local  # Backup local no host
    networks:
      - nebula-net
    depends_on:
      - helpdesk-api-prd-latest
```

## 3. Funcionalidades do Sidekick

### 3.1 Backup Automático
O sidekick executa backups que incluem:
- **Dados do banco**: Mensagens, contatos, tickets, usuários
- **Arquivos**: Mídias, documentos anexos
- **Configurações**: Settings, filas, campanhas
- **Sessões WhatsApp**: Estados de conexão

### 3.2 Restauração de Dados
Processo de restauração:
1. **Detecção** de arquivo `retrieved_data.tar.gz`
2. **Descompressão** do arquivo
3. **Validação** de tabelas vazias
4. **Importação** de dados CSV
5. **Limpeza** de sessões WhatsApp
6. **Correção** de sequências do banco

### 3.3 Scripts Executados

#### `load-retrieved.sh`
```bash
#!/bin/bash
# Script principal de restauração
INPUT_DIR=$1
ARCHIVE_NAME="retrieved_data.tar.gz"

# Verifica se arquivo existe
if [ ! -f "$INPUT_DIR/$ARCHIVE_NAME" ]; then
    exit 0
fi

# Descomprime arquivo
tar -xzf "$INPUT_DIR/$ARCHIVE_NAME" -C "$INPUT_DIR"

# Valida tabelas vazias
for input_file in "$INPUT_DIR"/*.csv; do
    table=$(basename "$input_file" .csv | cut -d'-' -f2-)
    if [[ $(PGPASSWORD="${DB_PASS}" psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT 1 FROM \"$table\" LIMIT 1") ]]; then
        echo "Table '$table' is not empty. Will not load retrieved file"
        exit 100
    fi
done

# Importa dados
for input_file in "$INPUT_DIR"/*.csv; do
    table=$(basename "$input_file" .csv | cut -d'-' -f2-)
    psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -c "\COPY \"$table\"(${columnList}) FROM '$input_file' WITH CSV HEADER"
done

# Limpa sessões WhatsApp
psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -c "UPDATE \"Whatsapps\" SET session='', status='DISCONNECTED'"

# Corrige sequências
cat ./scripts/fix-sequence.sql | psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}"
```

#### `fix-sequence.sql`
```sql
DO $$
DECLARE
    rec RECORD;
    table_name TEXT;
    seq_name TEXT;
    max_id BIGINT;
    setval_query TEXT;
BEGIN
    -- Loop através de todas as sequences
    FOR rec IN
        SELECT sequence_schema,
               sequence_name AS seq_name,
               REPLACE(sequence_name,  '_id_seq', '') AS table_name
        FROM information_schema.sequences
        WHERE sequence_schema = 'public'
    LOOP
        seq_name := rec.seq_name;
        table_name := rec.table_name;

        BEGIN
            -- Obtém valor máximo do campo 'id'
            EXECUTE format('SELECT COALESCE(MAX(id), 0) FROM %I.%I', rec.sequence_schema, table_name) INTO max_id;

            -- Define para 1 se necessário
            IF max_id = 0 THEN
                max_id := 1;
            END IF;

            -- Executa setval
            setval_query := format('SELECT setval(''%I.%I'', %s)', rec.sequence_schema, seq_name, max_id);
            EXECUTE setval_query;

            RAISE NOTICE 'SELECT setval(''%s'', %s);', format('%I.%I', rec.sequence_schema, seq_name), max_id;
        END;
    END LOOP;
END $$;
```

## 4. Como Usar o Sidekick

### 4.1 Backup Manual
```bash
# Iniciar backup
docker compose --profile backup up helpdesk-sidekick

# Verificar logs
docker logs helpdesk-sidekick

# Verificar arquivos de backup
docker exec helpdesk-sidekick ls -la /backups/
```

### 4.2 Restauração Manual
```bash
# 1. Colocar arquivo de backup em ./backups/retrieved_data.tar.gz
# 2. Iniciar restauração
docker compose --profile backup up helpdesk-sidekick

# 3. Verificar logs da restauração
docker logs helpdesk-sidekick --tail 100
```

### 4.3 Verificação de Status
```bash
# Status do container
docker ps | grep sidekick

# Logs em tempo real
docker logs -f helpdesk-sidekick

# Verificar volumes
docker volume ls | grep helpdesk
```

## 5. Automação de Backups

### 5.1 Script de Backup Automatizado
Crie o arquivo `scripts/backup-helpdesk.sh`:

```bash
#!/bin/bash
# Script de backup automatizado para Helpdesk

# Configurações
BACKUP_DIR="/backups/helpdesk"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/helpdesk-backup.log"
RETENTION_DAYS=7

# Função de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

log "Iniciando backup do Helpdesk - $DATE"

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    log "❌ Docker não está rodando"
    exit 1
fi

# Executar backup
log "Executando backup via sidekick..."
docker compose --profile backup up helpdesk-sidekick

# Verificar se backup foi criado
if [ -f "$BACKUP_DIR/backup_$DATE.tar.gz" ]; then
    log "✅ Backup criado com sucesso: backup_$DATE.tar.gz"
    
    # Limpar backups antigos
    log "Limpando backups antigos (mais de $RETENTION_DAYS dias)..."
    find $BACKUP_DIR -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
    
    # Verificar espaço em disco
    DISK_USAGE=$(df -h $BACKUP_DIR | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $DISK_USAGE -gt 80 ]; then
        log "⚠️  ATENÇÃO: Uso de disco em $DISK_USAGE%"
    fi
    
    log "🧹 Backups antigos removidos"
    log "✅ Backup concluído com sucesso"
else
    log "❌ Erro ao criar backup"
    exit 1
fi
```

### 5.2 Configuração do Crontab
```bash
# Editar crontab
crontab -e

# Adicionar linha para backup diário às 2h da manhã
0 2 * * * /path/to/scripts/backup-helpdesk.sh

# Backup semanal completo (domingo às 1h)
0 1 * * 0 /path/to/scripts/backup-helpdesk.sh
```

### 5.3 Monitoramento de Backups
```bash
# Script de monitoramento
#!/bin/bash
# Verificar status dos backups

BACKUP_DIR="/backups/helpdesk"
LOG_FILE="/var/log/helpdesk-backup.log"

echo "=== Status dos Backups Helpdesk ==="
echo "Data: $(date)"
echo ""

# Verificar último backup
LAST_BACKUP=$(ls -t $BACKUP_DIR/backup_*.tar.gz 2>/dev/null | head -1)
if [ -n "$LAST_BACKUP" ]; then
    BACKUP_DATE=$(stat -c %y $LAST_BACKUP)
    BACKUP_SIZE=$(du -h $LAST_BACKUP | cut -f1)
    echo "✅ Último backup: $(basename $LAST_BACKUP)"
    echo "   Data: $BACKUP_DATE"
    echo "   Tamanho: $BACKUP_SIZE"
else
    echo "❌ Nenhum backup encontrado"
fi

echo ""

# Verificar logs de erro
ERROR_COUNT=$(grep -c "❌" $LOG_FILE 2>/dev/null || echo "0")
if [ $ERROR_COUNT -gt 0 ]; then
    echo "⚠️  $ERROR_COUNT erros encontrados nos logs"
    echo "Últimos erros:"
    grep "❌" $LOG_FILE | tail -3
else
    echo "✅ Nenhum erro nos logs"
fi

echo ""

# Verificar espaço em disco
DISK_USAGE=$(df -h $BACKUP_DIR | awk 'NR==2 {print $5}' | sed 's/%//')
echo "💾 Uso de disco: $DISK_USAGE%"
if [ $DISK_USAGE -gt 90 ]; then
    echo "🚨 CRÍTICO: Espaço em disco baixo!"
elif [ $DISK_USAGE -gt 80 ]; then
    echo "⚠️  ATENÇÃO: Espaço em disco em $DISK_USAGE%"
fi
```

## 6. Segurança e Boas Práticas

### 6.1 Segurança
```yaml
# Adicionar ao docker-compose
environment:
  BACKUP_ENCRYPTION_KEY: "chave-super-secreta-256-bits"
  BACKUP_RETENTION_DAYS: "30"
  BACKUP_COMPRESSION: "gzip"
  BACKUP_ENCRYPTION: "aes256"
```

### 6.2 Permissões de Arquivo
```bash
# Configurar permissões corretas
chmod 600 /backups/helpdesk/*
chown root:root /backups/helpdesk/*
```

### 6.3 Backup Offsite
```bash
# Script para backup remoto
#!/bin/bash
# Sincronizar backups para servidor remoto

REMOTE_SERVER="backup-server.example.com"
REMOTE_PATH="/backups/helpdesk"
LOCAL_PATH="/backups/helpdesk"

# Sincronizar via rsync
rsync -avz --delete $LOCAL_PATH/ $REMOTE_SERVER:$REMOTE_PATH/

# Verificar integridade
ssh $REMOTE_SERVER "find $REMOTE_PATH -name '*.tar.gz' -exec gzip -t {} \;"
```

## 7. Troubleshooting

### 7.1 Problemas Comuns

#### Erro: "Table is not empty"
```bash
# Solução: Limpar tabelas antes da restauração
docker exec helpdesk-postgres-1 psql -U ticketz -d ticketz -c "TRUNCATE TABLE \"Messages\", \"Tickets\", \"Contacts\" CASCADE;"
```

#### Erro: "Connection refused"
```bash
# Verificar se PostgreSQL está rodando
docker ps | grep postgres
docker logs helpdesk-postgres-1
```

#### Erro: "Permission denied"
```bash
# Corrigir permissões
docker exec helpdesk-sidekick chown -R 1001:1001 /backups
```

### 7.2 Logs e Debugging
```bash
# Logs detalhados
docker logs helpdesk-sidekick --tail 100 -f

# Entrar no container para debug
docker exec -it helpdesk-sidekick /bin/bash

# Verificar variáveis de ambiente
docker exec helpdesk-sidekick env | grep -E "(DB_|BACKUP_)"
```

## 8. Monitoramento e Alertas

### 8.1 Script de Monitoramento
```bash
#!/bin/bash
# Monitoramento de backups

# Verificar se backup foi executado nas últimas 24h
LAST_BACKUP=$(find /backups/helpdesk -name "backup_*.tar.gz" -mtime -1 | wc -l)

if [ $LAST_BACKUP -eq 0 ]; then
    echo "ALERTA: Backup não executado nas últimas 24h"
    # Enviar email ou notificação
fi

# Verificar tamanho do backup
LATEST_BACKUP=$(ls -t /backups/helpdesk/backup_*.tar.gz | head -1)
BACKUP_SIZE=$(stat -c %s $LATEST_BACKUP)

if [ $BACKUP_SIZE -lt 1000000 ]; then  # Menos de 1MB
    echo "ALERTA: Backup muito pequeno - possível erro"
fi
```

### 8.2 Integração com Sistemas de Monitoramento
```yaml
# Prometheus metrics (exemplo)
- job_name: 'helpdesk-backup'
  static_configs:
    - targets: ['helpdesk-sidekick:9090']
  metrics_path: /metrics
  scrape_interval: 5m
```

## 9. Conclusão

O serviço Sidekick é **essencial** para ambientes de produção do Ticketz, fornecendo:

✅ **Backup automático** de dados críticos  
✅ **Restauração rápida** em caso de falhas  
✅ **Manutenção** do banco de dados  
✅ **Conformidade** com LGPD e auditoria  
✅ **Continuidade** do negócio  

### Recomendações Finais:

1. **Sempre incluir** o sidekick em produção
2. **Automatizar** backups diários
3. **Monitorar** logs e espaço em disco
4. **Testar** restaurações periodicamente
5. **Manter** backups offsite
6. **Documentar** procedimentos de recuperação

---

**Data**: Dezembro 2024  
**Versão**: 1.0  
**Autor**: Assistente de IA
