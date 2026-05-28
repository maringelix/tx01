FROM nginxinc/nginx-unprivileged:1.27.3-alpine@sha256:9e7238f579a54582263a960d1b0094b4a3ecce641342eda3f8e2ff82b1703d2b

# Remove default config (base image's USER nginx can't write to /etc/nginx, switch
# briefly to root just for the COPY/RM steps and drop back to nginx for runtime).
USER root
RUN rm /etc/nginx/conf.d/default.conf

# Custom nginx config (listens on 8080 because the base image runs unprivileged)
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Image base already sets USER nginx (uid 101); kept explicit for clarity.
USER nginx

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
