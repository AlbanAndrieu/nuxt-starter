# syntax=docker/dockerfile:1.15

# dockerfile_lint - ignore
# hadolint ignore=DL3007
FROM registry.gitlab.com/jusmundi-group/web/templates/jm-oci/jm-node:latest AS base

LABEL name="nuxt-starter" vendor="nabla" version="0.0.1"

FROM base AS builder

# Set the working directory inside the container
WORKDIR /usr/src/app

ENV NODE_ENV=development
# This is optional. Sets the level of logging that you see
ENV NPM_CONFIG_LOGLEVEL=warn

# Copy the rest of the application files to the working directory
COPY --chown=node:node . ./

RUN npm set progress=false && npm config set depth 0
RUN npm install --no-progress && npm run build

# Run
# dockerfile_lint - ignore
# hadolint ignore=DL3007
# FROM registry.gitlab.com/jusmundi-group/web/templates/jm-oci/jm-node:latest
#
# ENV NODE_ENV=production
#
# # Set the working directory inside the container
# WORKDIR /usr/src/app/storybook
#
# COPY --from=builder --chown=node:node /usr/src/app/ ./

# Make port 4173 available
EXPOSE 4173

HEALTHCHECK NONE

# Define the command to run the application
CMD ["npm", "run", "preview"]
