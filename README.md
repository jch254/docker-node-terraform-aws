# Docker-node-terraform-aws

**This branch/tag is no longer maintained**

[![Docker Hub](https://img.shields.io/docker/pulls/jch254/docker-node-terraform-aws)](https://hub.docker.com/r/jch254/docker-node-terraform-aws) [![Docker Image Size](https://img.shields.io/docker/image-size/jch254/docker-node-terraform-aws/latest)](https://hub.docker.com/r/jch254/docker-node-terraform-aws) 

Docker-powered build/deployment environment for Node.js projects on AWS. This Docker image is intended for use with [Bitbucket Pipelines](https://bitbucket.org/product/features/pipelines) and [AWS CodeBuild](https://aws.amazon.com/codebuild).

This image is based on node:16-alpine and has Terraform 0.15.5, the AWS CLI and Yarn installed (see Dockerfile for all other installed utilities).

See [serverless-node-dynamodb-ui](https://github.com/jch254/serverless-node-dynamodb-ui) for an example of this image in action.
