#!/bin/bash

# Script para corrigir problemas de deploy em produção
# Autor: Assistente de IA
# Data: Dezembro 2024

echo "🔧 Corrigindo problemas de deploy em produção..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose-local.yaml" ]; then
    error "Execute este script no diretório raiz do projeto Ticketz"
    exit 1
fi

log "1. Corrigindo arquivo de configuração do Nginx frontend..."

# Backup do arquivo original
if [ -f "frontend/nginx/sites.d/frontend.conf" ]; then
    cp frontend/nginx/sites.d/frontend.conf frontend/nginx/sites.d/frontend.conf.backup
    log "Backup criado: frontend/nginx/sites.d/frontend.conf.backup"
fi

# Aplicar correção
if [ -f "frontend/nginx/sites.d/frontend-production.conf" ]; then
    cp frontend/nginx/sites.d/frontend-production.conf frontend/nginx/sites.d/frontend.conf
    log "Configuração de produção aplicada"
else
    error "Arquivo frontend/nginx/sites.d/frontend-production.conf não encontrado"
    exit 1
fi

log "2. Aplicando configuração limpa do mimetypes..."

# Backup do arquivo original
if [ -f "frontend/nginx/conf.d/mimetypes.conf" ]; then
    cp frontend/nginx/conf.d/mimetypes.conf frontend/nginx/conf.d/mimetypes.conf.backup
    log "Backup criado: frontend/nginx/conf.d/mimetypes.conf.backup"
fi

# Aplicar correção
if [ -f "frontend/nginx/conf.d/mimetypes-clean.conf" ]; then
    cp frontend/nginx/conf.d/mimetypes-clean.conf frontend/nginx/conf.d/mimetypes.conf
    log "Configuração limpa do mimetypes aplicada"
else
    error "Arquivo frontend/nginx/conf.d/mimetypes-clean.conf não encontrado"
    exit 1
fi

log "3. Reconstruindo imagem frontend..."

# Build da nova imagem
docker build -t nebulasistemas/helpdesk-frontend:prd-latest ./frontend

if [ $? -eq 0 ]; then
    log "✅ Imagem frontend reconstruída com sucesso"
else
    error "❌ Falha ao reconstruir imagem frontend"
    exit 1
fi

log "4. Verificando imagens..."

echo "Imagens disponíveis:"
docker images | grep -E "(helpdesk-frontend|helpdesk-backend)"

log "5. Instruções para deploy:"

echo ""
echo "📋 Próximos passos:"
echo "1. Parar containers atuais:"
echo "   docker compose down"
echo ""
echo "2. Atualizar docker-compose com nova configuração:"
echo "   docker compose up -d"
echo ""
echo "3. Verificar logs:"
echo "   docker logs helpdesk-latest"
echo "   docker logs helpdesk-api-prd-latest"
echo ""
echo "4. Testar conectividade:"
echo "   curl -I http://helpdesk.sistemasnebula.com.br"
echo "   curl -I http://api-helpdesk.sistemasnebula.com.br"
echo ""

log "✅ Correções aplicadas com sucesso!"
log "📖 Consulte docs/SOLUCAO_DEPLOY_PRODUCAO.md para mais detalhes"
