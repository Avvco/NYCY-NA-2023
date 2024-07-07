FROM nginx

RUN apt-get update \
    && apt install net-tools

RUN mkdir -p /home/judge/log && \
    mkdir -p /etc/nginx/ssl

RUN openssl genrsa -out "/etc/nginx/ssl/default.key" 2048 && \
    openssl req -new -key "/etc/nginx/ssl/default.key" -out "/etc/nginx/ssl/default.csr" -subj "/CN=67.cs.nycu/OU=2023SA/O=NYCU/L=Hsinchu/ST=Hsinchu/C=TW" && \
    openssl x509 -req -days 365 -in "/etc/nginx/ssl/default.csr" -signkey "/etc/nginx/ssl/default.key" -out "/etc/nginx/ssl/default.crt" && \
    chmod 644 /etc/nginx/ssl/default.key
# COPY /vagrant/nginx/ssl.sh /docker-entrypoint.d/ssl.sh
# RUN chmod +x /docker-entrypoint.d/ssl.sh