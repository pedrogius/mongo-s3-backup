FROM python:3.9-slim

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y wget gnupg curl \
    && wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add - \
    && echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/6.0 main" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list \
    && apt-get update \
    && apt-get install -y mongodb-database-tools

RUN pip install --no-cache-dir awscli

RUN pip install --no-cache-dir s3cmd

COPY run.sh .

RUN chmod +x run.sh

CMD ["./run.sh"]
