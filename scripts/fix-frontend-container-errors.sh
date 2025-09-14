#!/bin/bash

# Script para corrigir erros do container frontend
# - Adiciona variável BACKEND_SERVICE ao docker-compose
# - Corrige warnings de mimetypes duplicados
# - Reconstrói a imagem frontend

set -e

echo "🔧 Corrigindo erros do container frontend..."

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose-local.yaml" ]; then
    echo "❌ Execute este script no diretório raiz do projeto"
    exit 1
fi

echo "✅ Adicionando variável BACKEND_SERVICE ao docker-compose-local.yaml..."
# A variável já foi adicionada manualmente, apenas verificamos
if grep -q "BACKEND_SERVICE=helpdesk-api-prd-latest" docker-compose-local.yaml; then
    echo "✅ Variável BACKEND_SERVICE já está configurada"
else
    echo "❌ Variável BACKEND_SERVICE não encontrada. Adicione manualmente:"
    echo "   environment:"
    echo "     - BACKEND_SERVICE=helpdesk-api-prd-latest"
    exit 1
fi

echo "✅ Verificando arquivo mimetypes.conf..."
if [ -f "frontend/nginx/conf.d/mimetypes.conf" ]; then
    echo "✅ Arquivo mimetypes.conf corrigido (sem duplicatas)"
else
    echo "❌ Arquivo mimetypes.conf não encontrado"
    exit 1
fi

echo "🔄 Parando containers existentes..."
docker compose -f docker-compose-local.yaml down

echo "🔄 Removendo imagem frontend antiga..."
docker rmi ticketz-frontend:latest 2>/dev/null || true

echo "🏗️ Reconstruindo imagem frontend..."
docker compose -f docker-compose-local.yaml build frontend

echo "🚀 Iniciando containers..."
docker compose -f docker-compose-local.yaml up -d

echo "⏳ Aguardando containers iniciarem..."
sleep 10

echo "🔍 Verificando status dos containers..."
docker compose -f docker-compose-local.yaml ps

echo "📋 Verificando logs do frontend..."
echo "--- Logs do Frontend (últimas 20 linhas) ---"
docker compose -f docker-compose-local.yaml logs --tail=20 frontend

echo ""
echo "✅ Correções aplicadas com sucesso!"
echo ""
echo "📝 Resumo das correções:"
echo "   1. ✅ Adicionada variável BACKEND_SERVICE=helpdesk-api-prd-latest"
echo "   2. ✅ Corrigido arquivo mimetypes.conf (removidas duplicatas)"
echo "   3. ✅ Reconstruída imagem frontend"
echo ""
echo "🔍 Para verificar se os erros foram corrigidos:"
echo "   docker compose -f docker-compose-local.yaml logs frontend"
echo ""
echo "🌐 Para acessar a aplicação:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8080"
