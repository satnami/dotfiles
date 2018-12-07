#!/bin/bash

docker run --name portainer -p 9000:9000 --restart=always -v "/var/run/docker.sock:/var/run/docker.sock" -v "/var/lib/portainer:/data" -d portainer/portainer

#docker run --name satnami-wallabag -p 8044:80 -v /opt/wallabag:/var/www/wallabag/data -d wallabag/wallabag

#docker run --name satnami-localstack -p 4567-4580:4567-4580 -p 8097:8080 -d  atlassianlabs/localstack

docker run --name satnami-memcached -p 11211:11211 -d memcached:latest

docker run --name satnami-rabbitmq -p 15672:15672 -p 5672:5672 -d rabbitmq:3-management

docker run --name satnami-redis -p 6379:6379 -d redis:latest

docker run --name satnami-rethinkdb -p 29015:29015 -p 8015:8080 -v /var/lib/rethinkdb:/data -d rethinkdb:latest

docker run --name satanmi-mongo -p 27017:27017 -v /var/lib/mongo:/data/db -d mongo:latest

docker run --name satnami-postgres -p 5432:5432 -e POSTGRES_PASSWORD=postgres -v /var/lib/postgresql/9.6-docker/data:/var/lib/postgresql/data -d postgres:latest
#docker run --name satnami-psql -it --rm --link satnami-postgres:postgres postgres psql -h postgres -U postgres

#docker run --name satnami-netdata -p 19999:19999 --privileged --restart=always --cap-add SYS_PTRACE -v /proc:/host/proc:ro -v /sys:/host/sys:ro -d titpetric/netdata

docker run --name satnami-yopass -p 1337:1337 -e 'MEMCACHED=memcache:11211' --link satnami-memcached:memcache -d jhaals/yopass

docker run --name satnami-vpnc --privileged -d satnami/vpnc

# docker run -d -p 9991:8080 -p 9990:9990 --name satnami-wildfly -it jboss/wildfly /opt/jboss/wildfly/bin/standalone.sh -bmanagement 0.0.0.0

# export ACTION=remove && curl -sSL https://shipyard-project.com/deploy | bash -s
# export ACTION=deploy && curl -sSL https://shipyard-project.com/deploy | bash -s
