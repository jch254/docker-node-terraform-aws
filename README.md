# Docker-node-terraform-aws

[![Dockerhub badge](http://dockeri.co/image/jch254/docker-node-terraform-aws)](https://hub.docker.com/r/jch254/docker-node-terraform-aws)

Docker-powered build/deployment environment for Node.js projects on AWS. This Docker image is intended for use with [Bitbucket Pipelines](https://bitbucket.org/product/features/pipelines) and [AWS CodeBuild](https://aws.amazon.com/codebuild).

This image is based on node:14-alpine and has Terraform 0.13.5, the AWS CLI and Yarn installed (see Dockerfile for all other installed utilities).

See [serverless-node-dynamodb-ui](https://github.com/jch254/serverless-node-dynamodb-ui) for an example of this image in action.
