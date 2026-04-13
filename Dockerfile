# Estágio de construção
FROM node:20-alpine AS builder

# Configurar variáveis de ambiente para o build
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

WORKDIR /app

# Instalar pnpm globalmente
RUN npm install -g pnpm

# Copiar apenas os arquivos necessários para instalar dependências
COPY package.json pnpm-lock.yaml ./

# Instalar dependências com cache limpo
RUN pnpm install --ignore-scripts

# Copiar o resto dos arquivos do projeto
COPY . .

# Construir a aplicação
RUN pnpm build

# Estágio de produção
FROM node:20-alpine AS runner

# Configurar variáveis de ambiente
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

WORKDIR /app

# Criar usuário não-root
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    chown -R nextjs:nodejs /app

# Instalar apenas as dependências necessárias
COPY --from=builder /app/package.json /app/pnpm-lock.yaml ./
RUN npm install -g pnpm && \
    pnpm install --prod  --ignore-scripts

# Copiar arquivos de build e públicos
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/next.config.mjs ./

# Configurar permissões
RUN chown -R nextjs:nodejs .

# Mudar para o usuário não-root
USER nextjs

# Expor a porta
EXPOSE 3000

# Iniciar a aplicação
CMD ["pnpm", "start"] 