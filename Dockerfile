# Private email gateway with getmail and dovecot
#
# Author: kevinflynn387 [https://github.com/kevinflynn387/] <kevinflynn387@gmail.com>

FROM debian:stretch-slim
MAINTAINER kevinflynn387 [https://github.com/kevinflynn387/] <kevinflynn387@gmail.com>

# install debian packages
ENV DEBIAN_FRONTEND noninteractive

# install dovecot.org deb repository
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y apt-transport-https curl gpg ca-certificates
RUN curl https://repo.dovecot.org/DOVECOT-REPO-GPG | gpg --import \
&& gpg --export ED409DA1 > /etc/apt/trusted.gpg.d/dovecot.gpg
RUN echo "deb https://repo.dovecot.org/ce-2.3-latest/debian/stretch stretch main" > /etc/apt/sources.list.d/dovecot.list

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
    cron \
    getmail4 \
    dovecot-imapd \
    dovecot-managesieved \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# configure dovecot
RUN sed -i 's/#log_path = syslog/log_path = \/var\/log\/dovecot\/dovecot.log/' /etc/dovecot/conf.d/10-logging.conf \
    # authentication
 && sed -i 's/#auth_verbose =.*/auth_verbose = yes/' /etc/dovecot/conf.d/10-auth.conf \
    # ssl
 && sed -i 's/^ssl =.*/ssl = required/' /etc/dovecot/conf.d/10-ssl.conf \
 && sed -i 's/#ssl_cert =.*/ssl_cert = <\/etc\/ssl\/private\/dovecot.crt/' /etc/dovecot/conf.d/10-ssl.conf \
 && sed -i 's/#ssl_key =.*/ssl_key = <\/etc\/ssl\/private\/dovecot.key/' /etc/dovecot/conf.d/10-ssl.conf \
    # mailboxes
 && sed -i 's/^mail_location =.*/mail_location = maildir:~\/Maildir:LAYOUT=fs/' /etc/dovecot/conf.d/10-mail.conf \
 && sed -i 's/#separator = $/separator = \//' /etc/dovecot/conf.d/10-mail.conf \
 && sed -i 's/#lda_mailbox_autocreate =.*/lda_mailbox_autocreate = yes/' /etc/dovecot/conf.d/15-lda.conf \
 && sed -i 's/#lda_mailbox_autosubscribe =.*/lda_mailbox_autosubscribe = yes/' /etc/dovecot/conf.d/15-lda.conf \
    # sieve plugin
 && sed -i 's/#mail_plugins = \$mail_plugins/mail_plugins = \$mail_plugins sieve/' /etc/dovecot/conf.d/15-lda.conf \
 && sed -i 's/#protocols = \$protocols sieve/protocols = \$protocols sieve/g' /etc/dovecot/conf.d/20-managesieve.conf \
    # imap idle
 && sed -i 's/#imap_idle_notify_interval =.*/imap_idle_notify_interval = 29 mins/' /etc/dovecot/conf.d/20-imap.conf

# setup entrypoint
ENV DEFAULT_PASSWD="replaceMeNow"
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 143
EXPOSE 993
EXPOSE 4190
#VOLUME /home
#VOLUME /etc/cron.d
#VOLUME /etc/ssl/private

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "--follow", "--retry", "/var/log/dovecot/dovecot.log", "/var/log/getmail/*.log"]
