# —— Inspired by ———————————————————————————————————————————————————————————————
# https://www.strangebuzz.com/en/snippets/the-perfect-makefile-for-symfony

# Setup ————————————————————————————————————————————————————————————————————————

# Parameters
SHELL         = bash
ME            = $(shell whoami)

# Image
APP_NAME     = nuxt-starter
# 783876277037.dkr.ecr.eu-west-3.amazonaws.com
OCI_REGISTRY = registry.gitlab.com/AlbanAndrieu/nuxt-starter
AWS_REGION   = eu-west-3
OCI_IMAGE := $(OCI_REGISTRY)/$(APP_NAME)
OCI_TAG = $${OCI_TAG:-"latest"}
IMAGE_NEXT_TAG := $${OCI_IMAGE_TAG:-"0.0.1"}
IMAGE := $(OCI_IMAGE):$(OCI_TAG)

TRIVY_VULN_TYPE = "os,library"
TRIVY_SCANNERS = "vuln,misconfig,secret"
TRIVY_GLOBAL_SECURITY_CHECKS = --scanners ${TRIVY_SCANNERS} --vuln-type ${TRIVY_VULN_TYPE}
TRIVY_ARGS = --skip-dirs .direnv --skip-dirs .venv --skip-dirs ./node_modules --skip-files .env --skip-dirs /home/ubuntu/go/ --skip-dirs /home/ubuntu/node_modules/ --skip-dirs /home/runner/work/trivy/ --skip-dirs /usr/local/lib/python3.8/dist-packages/ansible/galaxy/ --skip-dirs /home/ubuntu/.local/lib/python3.8/site-packages/awscli/ --skip-dirs /home/ubuntu/.local/share/virtualenvs/ --skip-dirs /home/ubuntu/.local/lib/python3.8/site-packages/rsa/ --skip-dirs /home/ubuntu/.local/lib/python3.8/site-packages/botocore/data/ --skip-dirs /usr/lib/node_modules/ --skip-files /usr/local/bin/container-structure-test --skip-files /usr/local/go/src/crypto/elliptic/internal/fiat/Dockerfile --skip-dirs /home/ubuntu/.local/lib/python3.8/site-packages/ansible
CS_SEVERITY_REPORT_THRESHOLD = "HIGH,CRITICAL"

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = source
BUILDDIR      = build

# Executables: local only
DOCKER        = docker
GIT           = git
YARN          = yarn

# Misc
.DEFAULT_GOAL = build
.PHONY       =  # Not needed here, but you can put your all your targets to be sure
	            # there is no name conflict between your files and your targets.

## —— 🐝 The Strangebuzz Docker Makefile 🐝 ———————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

## —— All 🎵 ———————————————————————————————————————————————————————————————
.PHONY: all
all: down clean build up test

## —— Clean Docker 🧹🐳💩 ———————————————————————————————————————————————————————————————
.PHONY: clean-docker
clean-docker:
	@echo "=> Cleaning image..."
	docker rmi $(IMAGE)

## —— Clean 🧹 ———————————————————————————————————————————————————————————————
.PHONY: clean
clean: clean-docker

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
.PHONY: build-docker
build-docker:  ## Build container with docker
	@echo "=> Building image..."
	@echo "docker build -t $(IMAGE) ."
	@docker build -t $(IMAGE) .

## —— Docker Debug 🐳🐞 ————————————————————————————————————————————————————————————————
.PHONY: debug-docker
debug-docker:
	@echo "docker run -it -u 1000:1000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock -w /home/ubuntu/ -v "$(PWD)":/home/ubuntu/ $(IMAGE)"
	@docker run -it -u 0:0 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock--rm --entrypoint /bin/bash -w /home/ubuntu/ -v "$(PWD)":/home/ubuntu/ $(IMAGE)

## —— Docker Slim 🐳 ————————————————————————————————————————————————————————————————
.PHONY: build-docker-slim
build-docker-slim:  ## Build container with docker-slim
	@echo "=> Building image..."
	@echo "docker-slim build --target $(IMAGE) --http-probe=my/sample-app"
	docker-slim build --continue-after --target $(IMAGE) --http-probe=false

## —— Build 🚀 —————————————————————————————————————————————————————————————————
.PHONY: build
build: build-docker

## —— Up Docker ✅🐳 —————————————————————————————————————————————————————————————————
.PHONY: up-docker
up-docker:
	@echo "up docker"
	docker run -it --network=host $(IMAGE)

## —— Up Python ✅🐍 —————————————————————————————————————————————————————————————————
.PHONY: up-python
up-python:
	@echo "up python http://0.0.0.0:8080/ping"
	python serve.py

## —— Up ✅ —————————————————————————————————————————————————————————————————
.PHONY: up
up:
	@echo "up"
	# podman-compose up --force-recreate -d
	$(DOCKER) container exec -it $(IMAGE) bash

.PHONY: down
down:
	@echo "down"
	# podman-compose down

.PHONY: run
run: down up

.PHONY: doc
doc: ## Documentation
	@echo "=> Doc..."
	sphinx-build ./docs/source/ _build --color -W -bhtml

## —— Formating 🧪🔗 ———————————————————————————————————————————————————————————————
.PHONY: fmt
fmt: ## Run formating
	@echo "=> Executing formating..."
	shfmt -i 2 -ci -w *.sh || true
	ansible-lint --write ./

## —— Tests Ansible 🧪🔗 —————————————————————————————————————————————————————————————————
.PHONY: test
test: ## Run all tests
	@echo "=> Testing ansible..."
	ansible-lint ./

## —— Debug 📜🐳 —————————————————————————————————————————————————————————————————
.PHONY: debug
debug: ## Enter container
	@echo "=> Debuging image..."
	@echo "docker run -it -u 1000:1000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock $(IMAGE)"
	docker run -it --entrypoint /bin/bash $(IMAGE)

## —— Project 🐝🐳 ———————————————————————————————————————————————————————————————
.PHONY: start
start: ## Run container
	@echo "=> Executing image..."
	@echo "docker run -it -d -u 1000:1000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock $(IMAGE)"
	# @echo "http 172.16.0.5:3000/en"
	docker run -it -u 1000:1000 -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro -v /var/run/docker.sock:/var/run/docker.sock $(IMAGE)

## —— Tests Dive 🧪🐳🚨 —————————————————————————————————————————————————————————————————
.PHONY: test-dive
test-dive: ## Run Dive image tests
	@echo "=> Testing Dive image..."
	@echo "CI=true dive --ci --highestUserWastedPercent 0.1 --lowestEfficiency 0.9 --json docker-dive-stats.json $(IMAGE) 1>docker-dive.log 2>docker-dive-error.log"
	CI=true docker run --rm -it \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$(pwd)":"$(pwd)" \
      -w "$(pwd)" \
      -v "$(pwd)/.dive.yaml":"$(pwd)/.dive.yaml" \
      wagoodman/dive:latest --ci --json docker-dive-stats.json $(IMAGE)

## —— Tests Dive CI 🧪🐳🚨 —————————————————————————————————————————————————————————————————
.PHONY: test-dive-ci
test-dive-ci: ## Run Dive image tests for CI
	@echo "=> Testing Dive image..."
	CI=true dive --ci --highestUserWastedPercent 0.1 --lowestEfficiency 0.9 --json docker-dive-stats.json $(OCI_IMAGE):$(IMAGE_NEXT_TAG)

## —— Tests Codeclimate 🧪🤖 —————————————————————————————————————————————————————————————————
.PHONY: test-codeclimate
test-codeclimate:
	@echo "=> Testing Codeclimate image..."
	@echo "codeclimate analyze"
	docker run \
  --interactive --tty --rm \
  --env CODECLIMATE_CODE="$PWD" \
  --volume "$PWD":/code \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume /tmp/cc:/tmp/cc \
  codeclimate/codeclimate analyze

## —— Tests Semgrep 🧪👽 —————————————————————————————————————————————————————————————————
.PHONY: test-semgrep
test-semgrep:
	@echo "=> Testing Semgrep image..."
	semgrep --config auto .

## —— Tests CST 🧪🕳️ —————————————————————————————————————————————————————————————————
.PHONY: test-cst
test-cst:
	@echo "=> Testing CST image..."
	@echo "/usr/local/bin/container-structure-test test --save -v info --image $(OCI_IMAGE):$(IMAGE_NEXT_TAG) --config ./config.yaml --test-report junit"
	@echo "docker pull $(OCI_IMAGE):$(IMAGE_NEXT_TAG)"
	/usr/local/bin/container-structure-test test --image $(OCI_IMAGE):$(IMAGE_NEXT_TAG) --config ./config.yaml

## —— Tests 🧪 —————————————————————————————————————————————————————————————————
.PHONY: test
test: test-dive test-codeclimate test-semgrep test-cst

## —— Tests Sast Docker 👮😈🐳 —————————————————————————————————————————————————————————————————
.PHONY: sast-docker
sast-docker:
	@echo "=> Scanning trivy image..."
	time trivy image --exit-code 1 --severity $(CS_SEVERITY_REPORT_THRESHOLD) $(TRIVY_GLOBAL_SECURITY_CHECKS) $(TRIVY_ARGS) --format table --output scan-report.md $(IMAGE) 1>docker-trivy.log 2>docker-trivy-error.log

## —— Tests Sast Fs Docker 👮😈️🐳 —————————————————————————————————————————————————————————————————
.PHONY: sast-fs-docker
sast-fs-docker:
	@echo "=> Scanning trivy filesystem..."
	time trivy filesystem --exit-code 2 --severity $(CS_SEVERITY_REPORT_THRESHOLD) $(TRIVY_GLOBAL_SECURITY_CHECKS) $(TRIVY_ARGS) --format table --output scan-report-fs.md . 1>docker-trivy-fs.log 2>docker-trivy-fs-error.log

## —— Tests 👮😈 —————————————————————————————————————————————————————————————————
.PHONY: sast
sast: sast-fs-docker ## Run Trivy sast

## —— Deploy Docker 💾🐳 ———————————————————————————————————————————————————————————————
.PHONY: deploy-docker
deploy-docker: ## Push to registry
	@echo "=> Tagging image..."
	docker tag $(IMAGE) $(OCI_IMAGE):$(IMAGE_NEXT_TAG)
	@echo "=> docker login registry.gitlab.com --username \$${GITLAB_PRIVATE_USERNAME} --password \$${GITLAB_FULL_PRIVATE_TOKEN}"
	@echo "=> aws ecr get-login-password --profile ecr | docker login --username AWS --password-stdin \$${OCI_REGISTRY:-\"783876277037.dkr.ecr.eu-west-3.amazonaws.com\"} "
	@echo "=> Pushing image..."
	@echo "=> By Hand 👊 => docker push $(OCI_IMAGE):$(IMAGE_NEXT_TAG)"
	@echo "=> By Hand ✌ => docker push $(OCI_IMAGE):latest"

## —— Yarn 🐱 / JavaScript —————————————————————————————————————————————————————
yarn: ## Rebuild assets for the dev env
	$(YARN) install
	$(YARN) dev

watch: ## Watch files and build assets when needed for the dev env
	$(YARN) dev --watch

yarn@prod: ## Build assets for production
	$(YARN) install
	$(YARN) build

## —— Deploy 💾👑 ———————————————————————————————————————————————————————————————
.PHONY: deploy
deploy: deploy-docker ## Push to registry

## —— Stats 📜 —————————————————————————————————————————————————————————————————
stats: ## Commits by the hour for the main author of this project
	$(GIT) log --author="$(GIT_AUTHOR)" --date=iso | perl -nalE 'if (/^Date:\s+[\d-]{10}\s(\d{2})/) { say $$1+0 }' | sort | uniq -c|perl -MList::Util=max -nalE '$$h{$$F[1]} = $$F[0]; }{ $$m = max values %h; foreach (0..23) { $$h{$$_} = 0 if not exists $$h{$$_} } foreach (sort {$$a <=> $$b } keys %h) { say sprintf "%02d - %4d %s", $$_, $$h{$$_}, "*"x ($$h{$$_} / $$m * 50); }'
