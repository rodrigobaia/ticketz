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
