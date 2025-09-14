# Levantamento Técnico - Projeto Ticketz

## Resumo Executivo

Este documento apresenta um levantamento técnico completo do projeto **Ticketz**, um sistema de comunicação empresarial que integra CRM e Helpdesk utilizando WhatsApp como canal principal. O levantamento inclui análise de arquitetura, tecnologias, funcionalidades e otimizações implementadas.

## 1. Visão Geral do Projeto

### 1.1 Propósito
O Ticketz é uma solução open-source que permite às empresas:
- Gerenciar atendimento ao cliente via WhatsApp
- Organizar tickets de suporte em filas
- Executar campanhas de marketing
- Manter histórico completo de interações
- Gerar relatórios e métricas de atendimento

### 1.2 Características Principais
- **Sistema Multi-tenant**: Suporte a múltiplas empresas
- **Integração WhatsApp**: Via biblioteca Baileys
- **CRM Completo**: Gestão de contatos e histórico
- **Sistema de Tickets**: Atendimento organizado em filas
- **Campanhas**: Marketing direcionado via WhatsApp
- **Relatórios**: Métricas e analytics detalhados
- **Pagamentos**: Integração com gateways de pagamento
- **Notificações**: Tempo real via WebSocket
- **Internacionalização**: Suporte a múltiplos idiomas
- **Temas**: Modo claro/escuro personalizável

## 2. Arquitetura do Sistema

### 2.1 Arquitetura Geral
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Frontend     │    │     Backend     │    │    Database     │
│   (React SPA)   │◄──►│  (Node.js API)  │◄──►│  (PostgreSQL)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │   WebSocket     │    │     Redis       │
│  (Static Files) │    │  (Socket.io)    │    │    (Cache)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 2.2 Estrutura do Backend
```
backend/src/
├── controllers/          # Lógica de negócio
├── models/              # Modelos Sequelize ORM
├── services/            # Serviços especializados
├── routes/              # Endpoints da API REST
├── middleware/          # Autenticação, validação
├── queues/              # Processamento assíncrono
├── libs/                # Bibliotecas auxiliares
├── utils/               # Utilitários
└── config/              # Configurações
```

### 2.3 Estrutura do Frontend
```
frontend/src/
├── components/          # Componentes reutilizáveis
├── pages/               # Páginas da aplicação
├── context/             # Gerenciamento de estado
├── services/            # Integração com API
├── routes/              # Navegação
├── hooks/               # Hooks customizados
├── layout/              # Layouts da aplicação
└── translate/           # Internacionalização
```

## 3. Tecnologias Utilizadas

### 3.1 Backend (Node.js/TypeScript)
| Tecnologia | Versão | Propósito |
|------------|--------|-----------|
| **Node.js** | 20 | Runtime JavaScript |
| **TypeScript** | 5.4.5 | Linguagem tipada |
| **Express.js** | 4.19.2 | Framework web |
| **Sequelize** | 6.37.2 | ORM para PostgreSQL |
| **Socket.io** | 4.7.5 | Comunicação em tempo real |
| **Baileys** | 6.7.18 | Integração WhatsApp |
| **PostgreSQL** | 16-alpine | Banco de dados principal |
| **Redis** | alpine | Cache e filas |
| **Bull** | 4.12.2 | Sistema de filas |
| **JWT** | 9.0.2 | Autenticação |
| **Bcryptjs** | 2.4.3 | Criptografia de senhas |

### 3.2 Frontend (React SPA)
| Tecnologia | Versão | Propósito |
|------------|--------|-----------|
| **React** | 17.0.2 | Framework UI |
| **Material-UI** | 4.12.4 | Componentes de interface |
| **React Router** | 5.2.0 | Roteamento |
| **Axios** | 1.6.8 | Requisições HTTP |
| **Socket.io-client** | 4.7.5 | WebSocket client |
| **React Query** | 3.39.3 | Gerenciamento de estado |
| **Formik** | 2.2.0 | Formulários |
| **Bootstrap** | 5.2.3 | Framework CSS |

### 3.3 Infraestrutura
| Tecnologia | Versão | Propósito |
|------------|--------|-----------|
| **Docker** | Latest | Containerização |
| **Docker Compose** | Latest | Orquestração |
| **Nginx** | Alpine | Servidor web |
| **ACME** | Latest | Certificados SSL |
| **Sentry** | 6.19.7 | Monitoramento de erros |

## 4. Modelos de Banco de Dados

### 4.1 Entidades Principais
- **Company**: Empresas/tenants do sistema
- **User**: Usuários do sistema (agentes, administradores)
- **Whatsapp**: Configurações de conexões WhatsApp
- **Ticket**: Tickets de atendimento
- **Contact**: Contatos dos clientes
- **Message**: Mensagens trocadas
- **Queue**: Filas de atendimento
- **Campaign**: Campanhas de marketing
- **Plan**: Planos de assinatura
- **Setting**: Configurações do sistema

### 4.2 Relacionamentos Principais
- Uma **Company** pode ter múltiplos **Users**
- Uma **Company** pode ter múltiplas conexões **Whatsapp**
- Um **Ticket** pertence a um **Contact** e um **User**
- Um **Ticket** pode ter múltiplas **Messages**
- Uma **Queue** pode ter múltiplos **Users**
- Uma **Campaign** pode ter múltiplos **Contacts**

## 5. Funcionalidades Detalhadas

### 5.1 Sistema de Tickets
- Criação automática de tickets via WhatsApp
- Distribuição por filas de atendimento
- Status: pending, open, closed, pending
- Transferência entre agentes
- Tags e categorização
- Notas internas

### 5.2 CRM e Contatos
- Cadastro automático de contatos
- Campos customizados
- Histórico completo de interações
- Listas de contatos
- Importação/exportação
- Segmentação

### 5.3 Campanhas de Marketing
- Criação de campanhas em massa
- Agendamento de envios
- Templates de mensagens
- Relatórios de entrega
- Controle de opt-out

### 5.4 Sistema de Filas
- Múltiplas filas de atendimento
- Distribuição automática
- Horários de funcionamento
- Mensagens automáticas
- Transferência entre filas

### 5.5 Relatórios e Analytics
- Métricas de atendimento
- Tempo de resposta
- Satisfação do cliente
- Volume de mensagens
- Performance por agente
- Relatórios exportáveis

## 6. Segurança

### 6.1 Autenticação e Autorização
- JWT (JSON Web Tokens)
- Senhas criptografadas com bcrypt
- Controle de acesso por perfil
- Sessões seguras

### 6.2 Proteção de Dados
- CORS configurado
- Validação de entrada
- Sanitização de dados
- Logs de auditoria

### 6.3 Infraestrutura
- Containers isolados
- Usuário não-root
- Certificados SSL
- Firewall configurado

## 7. Deployment e Configuração

### 7.1 Opções de Instalação
1. **Local**: Desenvolvimento e testes
2. **Produção com ACME**: SSL automático
3. **Script automatizado**: Instalação via curl

### 7.2 Configuração Docker
- Multi-stage builds
- Otimização de layers
- Cache de dependências
- Health checks

### 7.3 Variáveis de Ambiente
- Configuração de banco de dados
- URLs de frontend/backend
- Chaves de API
- Configurações de WhatsApp

## 8. Análise de Problemas e Soluções

### 8.1 Problemas Identificados Durante o Levantamento

#### 8.1.1 Erro Docker Compose
**Problema**: Falha ao executar `docker compose up -d`
```
ERROR [backend] resolve image config for docker-image://docker.io/docker/dockerfile:1.7-labs
ERROR [frontend internal] load metadata for ghcr.io/ticketz-oss/nginx-alpine:latest
```

**Causas Identificadas**:
1. Sintaxe incompatível do Dockerfile (`# syntax=docker/dockerfile:1.7-labs`)
2. Flag `--parents` não suportada na versão atual do Docker
3. Problemas de conectividade com registries

**Soluções Implementadas**:
1. Remoção da diretiva `syntax` problemática
2. Correção do comando COPY removendo `--parents`
3. Separação dos comandos COPY em múltiplas linhas

#### 8.1.2 Otimização Docker Alpine
**Proposta**: Implementação de versão Alpine para redução de tamanho
- **Benefício**: Redução de 84% no tamanho da imagem (de ~1.1GB para ~180MB)
- **Status**: Implementada mas revertida por solicitação do usuário

### 8.2 Soluções Finais Implementadas

#### 8.2.1 Dockerfile Corrigido
```dockerfile
# Multi-stage build for Ticketz Backend

# Stage 1: Build the application
FROM node:20 AS build

WORKDIR /usr/src/app
COPY . .

RUN --mount=type=cache,target=/root/.npm \
    npm ci && npm run generate:i18nkeys && npm run build

# Stage 2: Create the final image without source files
FROM ghcr.io/ticketz-oss/node

ARG TICKETZ_REGISTRY_URL

WORKDIR /usr/src/app

# Copy only the necessary build artifacts from the build stage
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/scripts ./scripts

ENV NODE_ENV=production
ENV PORT=3000
ENV TICKETZ_REGISTRY_URL=${TICKETZ_REGISTRY_URL}

EXPOSE 3000

CMD dockerize -wait tcp://${DB_HOST}:5432 -timeout 60s \
  && npx sequelize db:migrate  --config dist/config/database.js --migrations-path dist/database/migrations \
  && ./scripts/load-retrieved.sh /retrieve; exit_code=$? \
  && if [ $exit_code -eq 1 ]; then npm run mark-seeds; exit 0; elif [ $exit_code -ge 100 ]; then exit 1; fi \
  && npx sequelize db:seed:all --config dist/config/database.js --seeders-path dist/database/seeds \
  && node dist/server.js
```

## 9. Licenciamento e Compliance

### 9.1 Licença
- **AGPL (Affero General Public License)**
- Baseado no Whaticket Community (MIT)
- Requer disponibilização do código fonte

### 9.2 Compliance
- Link para código fonte obrigatório
- Modificações devem manter licença
- Uso comercial requer compliance

## 10. Conclusões e Recomendações

### 10.1 Pontos Fortes
- Arquitetura moderna e bem estruturada
- Tecnologias atualizadas e estáveis
- Sistema multi-tenant robusto
- Integração WhatsApp funcional
- Documentação adequada

### 10.2 Áreas de Melhoria
- Otimização de imagens Docker
- Implementação de testes automatizados
- Melhorias de performance
- Atualização para versões mais recentes

### 10.3 Recomendações
1. **Manter versão atual**: O sistema está funcionando corretamente
2. **Monitoramento**: Implementar logs e métricas detalhadas
3. **Backup**: Configurar backup automático dos dados
4. **Segurança**: Revisar periodicamente as configurações de segurança
5. **Performance**: Monitorar uso de recursos e otimizar conforme necessário

## 11. Status Final

### 11.1 Sistema Funcionando
✅ **Docker Compose**: Executando corretamente  
✅ **Backend**: Build e deploy bem-sucedidos  
✅ **Frontend**: Build e deploy bem-sucedidos  
✅ **Banco de Dados**: PostgreSQL funcionando  
✅ **Cache**: Redis funcionando  
✅ **Rede**: Comunicação entre serviços estabelecida  

### 11.2 Acesso ao Sistema
- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:8080
- **Usuário padrão**: admin@ticketz.host
- **Senha padrão**: 123456

---

**Data do Levantamento**: Dezembro 2024  
**Versão Analisada**: Desenvolvimento atual  
**Status**: Sistema funcionando corretamente  
**Analista**: Assistente de IA
