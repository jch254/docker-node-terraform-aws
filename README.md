# Docker-node-terraform-aws

[![Dockerhub badge](http://dockeri.co/image/jch254/docker-node-terraform-aws)](https://hub.docker.com/r/jch254/docker-node-terraform-aws)

Docker-powered build/deployment environment for Node.js projects on AWS. This Docker image is intended for use with [Bitbucket Pipelines](https://bitbucket.org/product/features/pipelines) and [AWS CodeBuild](https://aws.amazon.com/codebuild).

This image is based on node:20-alpine and has Terraform 1.7.5, the AWS CLI and Yarn installed (see Dockerfile for all other installed utilities).

See [serverless-node-dynamodb-ui](https://github.com/jch254/serverless-node-dynamodb-ui) for an example of this image in action.

Use the [12.x](https://github.com/jch254/docker-node-terraform-aws/tree/12.x) branch/tag for an image running Node v12, the [14.x](https://github.com/jch254/docker-node-terraform-aws/tree/14.x) branch/tag for an image running Node v14, the [16.x](https://github.com/jch254/docker-node-terraform-aws/tree/16.x) branch/tag for an image running Node v16, the [18.x](https://github.com/jch254/docker-node-terraform-aws/tree/18.x) branch/tag for an image running Node v18 and the [20.x](https://github.com/jch254/docker-node-terraform-aws/tree/20.x) branch/tag for an image running Node v20.
