FROM octobercms/october-dev:latest

COPY flag /flag
COPY init.sql /init.sql
COPY setup.sh /usr/bin/start.sh

RUN chmod 755 /usr/bin/start.sh
