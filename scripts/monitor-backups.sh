#!/bin/bash
# Script de monitoramento de backups

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
