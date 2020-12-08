# Private email gateway with offlineimap and dovecot
#
# Author: n-a-m-e [https://github.com/n-a-m-e/] <none>

FROM debian:buster-slim
MAINTAINER n-a-m-e [https://github.com/n-a-m-e/] <none>

# install debian packages
ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt upgrade -y

# install dovecot.org deb repository
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y apt-transport-https curl gpg gpg-agent ca-certificates
RUN curl https://repo.dovecot.org/DOVECOT-REPO-GPG | gpg --import \
&& gpg --export ED409DA1 > /etc/apt/trusted.gpg.d/dovecot.gpg
RUN echo "deb https://repo.dovecot.org/ce-2.3-latest/debian/buster buster main" > /etc/apt/sources.list.d/dovecot.list

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
    cron \
    offlineimap \
    dovecot-imapd \
    dovecot-managesieved \
    dovecot-submissiond \
    python3 \
    logrotate \
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
 && sed -i 's/^mail_location =.*/mail_location = maildir:~\/.maildir:INBOX=~\/.maildir\/.INBOX/' /etc/dovecot/conf.d/10-mail.conf \
 && sed -i 's/#separator = $/separator = \./' /etc/dovecot/conf.d/10-mail.conf \
    # imap idle
 && sed -i 's/#imap_idle_notify_interval =.*/imap_idle_notify_interval = 29 mins/' /etc/dovecot/conf.d/20-imap.conf

RUN curl https://raw.githubusercontent.com/HendrikF/burlproxy/master/burlproxy.py --output /usr/local/bin/burlproxy.py
RUN chmod +x /usr/local/bin/burlproxy.py

RUN ln -s /etc/cron.daily/logrotate /etc/cron.hourly/logrotate

# setup entrypoint
ENV DEFAULT_PASSWD="replaceMeNow"
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 143
EXPOSE 587
EXPOSE 993
EXPOSE 1587

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "--follow", "--retry", "/var/log/dovecot/dovecot.log", "/var/log/offlineimap/offlineimap.log"]
