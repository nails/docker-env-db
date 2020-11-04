FROM mysql:8.0.22

# Set default database
ENV MYSQL_USER docker
ENV MYSQL_PASSWORD docker
ENV MYSQL_DATABASE dev
ENV MYSQL_RANDOM_ROOT_PASSWORD yes

# Ensure the mysql user runs as 1000:1000; same as the www-bridge-user
RUN sed -i 's/mysql:x:999:999/mysql:x:1000:1000/g' /etc/passwd && \
    sed -i 's/mysql:x:999:/mysql:x:1000:/g' /etc/group

# Add configs
ADD config/custom_config.cnf /etc/mysql/conf.d/
ADD config/grant-default-user.sql /docker-entrypoint-initdb.d/
