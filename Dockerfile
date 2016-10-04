FROM node:6.7.0

RUN apt-get update
RUN apt-get install -y unzip

RUN wget http://releases.hashicorp.com/terraform/0.7.4/terraform_0.7.4_linux_amd64.zip
RUN unzip terraform_0.7.4_linux_amd64.zip
RUN mv terraform /usr/bin/

RUN wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

ENTRYPOINT ["/bin/bash", "-c"]
