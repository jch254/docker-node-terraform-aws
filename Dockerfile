FROM node:8-alpine

RUN apk add --no-cache python py-pip py-setuptools ca-certificates openssl groff less bash curl jq git && \
    pip install --no-cache-dir --upgrade pip awscli

RUN aws configure set preview.cloudfront true

ENV TERRAFORM_VERSION 0.9.7

RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform.zip -d /usr/local/bin && \
    rm -f terraform.zip

ENTRYPOINT ["/bin/bash", "-c"]
