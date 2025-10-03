FROM ubuntu:24.04

LABEL maintainer="Tony Arianto <tony.arianto@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    NOTVISIBLE="in users profile"

# ARG untuk username & password biar ga hardcode
ARG APP_USER=app
ARG APP_PASSWORD=s1app123

# Set timezone & install packages
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt-get update && apt-get install -yq --no-install-recommends \
       sudo openssh-server apt-utils curl git apache2 libapache2-mod-php \
       php-cli php-dev php-json php-curl php-fpm php-gd php-readline \
       php-igbinary php-ldap php-redis php-memcached php-pcov php-xdebug \
       php-mbstring php-mysql php-soap php-sqlite3 php-xml php-zip php-intl \
       php-imagick php-bcmath php-pgsql screen unzip nano supervisor \
       mysql-client iputils-ping locales ca-certificates proftpd cron tzdata composer \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd /etc/supervisor/conf.d/ /home/$APP_USER/html/public

# Setup user non-root
RUN useradd -m $APP_USER && echo "$APP_USER:$APP_PASSWORD" | chpasswd \
    && usermod -aG sudo $APP_USER

# SSH config (lebih aman: disable root login, hanya pakai user app)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && echo "export VISIBLE=now" >> /etc/profile

# Install Node.js LTS (22.x)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm

# Apache + PHP config
COPY 000-default.conf /etc/apache2/sites-available/
RUN a2ensite 000-default \
    && a2enmod rewrite

# ProFTPD config
RUN sed -i "s|# DefaultRoot|DefaultRoot |g" /etc/proftpd/proftpd.conf

# Tambahkan file aplikasi
COPY index.php /home/$APP_USER/html/public
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chown -R $APP_USER:$APP_USER /home/$APP_USER/html

# Expose ports
EXPOSE 80 443 22 21

WORKDIR /home/$APP_USER

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
