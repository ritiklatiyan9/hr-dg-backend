FROM node:24-bookworm-slim AS build
WORKDIR /app
COPY package*.json tsconfig.json ./
COPY apps ./apps
COPY packages ./packages
COPY scripts ./scripts
RUN npm ci && npm run contracts && npm run build
FROM node:24-bookworm-slim
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/apps/hr-web/dist ./public
COPY --from=build /app/packages/contracts/schema.graphql ./dist/packages/contracts/schema.graphql
# Public AWS RDS regional trust roots; connection URLs still require verify-full.
# Render mounts /etc/secrets at runtime, so the image-owned path is under /app.
COPY --chmod=644 infra/rds-ap-south-1-bundle.crt /app/rds-ca.pem
USER node
EXPOSE 4000
HEALTHCHECK CMD node -e "fetch('http://localhost:'+(process.env.PORT||4000)+'/health/ready',{signal:AbortSignal.timeout(4000)}).then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"
CMD ["node", "dist/apps/api/src/index.js"]
