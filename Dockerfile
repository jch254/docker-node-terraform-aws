FROM mhart/alpine-node:latest

RUN apk add --update bash wget unzip python ca-certificates

RUN wget https://releases.hashicorp.com/terraform/0.8.8/terraform_0.8.8_linux_amd64.zip
RUN unzip terraform_0.8.8_linux_amd64.zip
RUN mv terraform /usr/bin/

RUN wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
RUN aws configure set preview.cloudfront true

RUN npm install -g yarn@0.21.3

ENTRYPOINT ["/bin/bash", "-c"]
