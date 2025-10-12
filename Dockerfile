FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    wget \
    jq \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash steampipe

RUN curl -fsSL https://steampipe.io/install/steampipe.sh | sh

RUN mkdir -p /home/steampipe/.steampipe/bin && \
    cp /usr/local/bin/steampipe /home/steampipe/.steampipe/bin/ && \
    chown -R steampipe:steampipe /home/steampipe/.steampipe

USER steampipe
ENV PATH="/home/steampipe/.steampipe/bin:$PATH"

WORKDIR /app

RUN mkdir -p /app/queries /app/output

COPY --chown=steampipe:steampipe steampipe.conf /app/
COPY --chown=steampipe:steampipe queries/ /app/queries/
COPY --chown=steampipe:steampipe run_queries.sh /app/

RUN chmod +x /app/run_queries.sh

ENV STEAMPIPE_CONFIG_PATH=/app/steampipe.conf

CMD ["/bin/bash", "/app/run_queries.sh"]
