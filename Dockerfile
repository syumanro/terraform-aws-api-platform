FROM nginx:1.27-alpine

COPY app/index.html /usr/share/nginx/html/index.html
COPY app/health /usr/share/nginx/html/health
COPY app/styles.css /usr/share/nginx/html/styles.css
COPY app/momo-hero.png /usr/share/nginx/html/momo-hero.png

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1/health || exit 1
