# Comparação: Node.js Standard vs Alpine

## Tamanho das Imagens

| Imagem | Tamanho | Redução |
|--------|---------|---------|
| `node:20` | ~1.1GB | - |
| `node:20-alpine` | ~180MB | **84% menor** |

## Benefícios da Versão Alpine

### 1. **Tamanho Significativamente Menor**
- **Node.js Standard**: ~1.1GB
- **Node.js Alpine**: ~180MB
- **Redução**: 84% menor

### 2. **Segurança Aprimorada**
- Base Alpine Linux (musl libc)
- Menor superfície de ataque
- Usuário não-root por padrão
- Menos pacotes instalados

### 3. **Performance**
- Inicialização mais rápida
- Menos memória utilizada
- Download mais rápido

### 4. **Otimizações Implementadas**

#### Multi-stage Build Otimizado:
```dockerfile
# Stage 1: Build (com devDependencies)
FROM node:20-alpine AS build

# Stage 2: Dependencies (apenas production)
FROM node:20-alpine AS deps

# Stage 3: Final (imagem mínima)
FROM node:20-alpine AS production
```

#### Melhorias de Segurança:
- Usuário não-root (`nodejs:nodejs`)
- `dumb-init` para gerenciamento de sinais
- Permissões corretas nos arquivos

#### Cache Otimizado:
- Cache de npm montado
- Layers otimizados para melhor cache
- Limpeza de cache após instalação

#### Health Check:
- Verificação de saúde da aplicação
- Restart automático em caso de falha

## Como Usar

### Opção 1: Substituir Dockerfile Atual
```bash
# Backup do original
mv Dockerfile Dockerfile.original

# Usar a versão otimizada
mv Dockerfile.alpine-optimized Dockerfile
```

### Opção 2: Usar Dockerfile Específico
```bash
# Build com Dockerfile específico
docker build -f Dockerfile.alpine-optimized -t ticketz-backend:alpine .
```

## Comandos de Build

```bash
# Build da imagem otimizada
docker build -f Dockerfile.alpine-optimized -t ticketz-backend:alpine .

# Verificar tamanho
docker images ticketz-backend:alpine

# Testar a imagem
docker run -p 3000:3000 ticketz-backend:alpine
```

## Verificação de Tamanho

```bash
# Comparar tamanhos
docker images | grep ticketz-backend

# Análise detalhada
docker history ticketz-backend:alpine
```

## Considerações

### Dependências Nativas
Algumas dependências podem precisar de ajustes:
- `sharp` (processamento de imagem)
- `bcrypt` (criptografia)
- `sqlite3` (se usado)

### Compatibilidade
- Alpine usa `musl libc` em vez de `glibc`
- Maioria das dependências Node.js funciona normalmente
- Testes recomendados antes de produção

## Resultado Final

A versão Alpine reduz o tamanho da imagem em **84%**, mantendo toda a funcionalidade e adicionando melhorias de segurança e performance.