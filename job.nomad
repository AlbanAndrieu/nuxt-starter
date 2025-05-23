# nomad job stop --namespace=* -purge nuxt-starter
# nomad job run -var env=uat -var team=uat job.nomad

variable "env" {
  type    = string
  default = "dev"

  validation {
    condition     = var.env == "dev" || var.env == "uat" || var.env == "prod"
    error_message = "The env value must be valid env uat or prod."
  }
}

variable "team" {
  type    = string
  default = "uat"

  validation {
    condition     = var.team == "ateam" || var.team == "bteam" || var.team == "uat" || var.team == "prod" || var.team == "dev"
    error_message = "The env value must be valid team ateam or bteam."
  }
}

variable "datacenters" {
  type        = list(string)
  description = "List of datacenters to deploy to."
  default     = ["gra"]
}

job "nuxt-starter" {
  datacenters = var.datacenters
  namespace   = "datascience"
  type        = "service"

  group "nuxt-starter" {
    count = 1


    ephemeral_disk {
      # Used to store index, cache, WAL
      # Nomad will try to preserve the disk between job updates
       size   = 500
       sticky  = true
       # migrate = true
    }

    # Canary disable, because service is too big 10 G minimum and cluster is not sized for it, so auto_promote set to false
    update {
      max_parallel      = 1
      min_healthy_time  = "5s"
      healthy_deadline  = "5m"
      progress_deadline = "0"
      canary            = 0
      auto_revert       = var.env == "prod" ? true : false
      auto_promote      = var.env == "prod" ? true : false
    }

    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode     = var.env == "dev" ? "fail" : "delay"
    }

    network {
      port "server" {
        to     = 4173
      }
    }

    task "nuxt-starter" {
      driver = "docker"

      config {
        # image = "[[ .CONTAINER_IMAGE ]]"
        image = "registry.gitlab.com/jusmundi-group/web/tech-and-product-hackathon-22nd-of-may/team-four/nuxt-starter:0.0.3"
        ports = ["server"]

        # force_pull = true
        shm_size = 536870912 # 512MB
        auth_soft_fail = true
        # image_pull_timeout = "25m"

        memory_hard_limit = 2048  # at ???G we will have OOM and the container will be killed
      }

      env {
        DD_VERSION = "[[ .CI_COMMIT_TAG ]]"
        DD_GIT_COMMIT_SHA = "[[ .CI_COMMIT_SHA ]]"
      }

      vault {
        policies  = ["cicd", "default"]
      }

      template {
        data        = <<EOF
UVICORN_LOG_LEVEL=debug
EOF
        destination = "${NOMAD_SECRETS_DIR}/.env.local"

        env         = true
      }

      service {
        name = "nuxt-starter"
        port = "server"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.nuxt-starter.entrypoints=http",
          "traefik.http.routers.nuxt-starter.rule=Host(`nuxt-starter.service.gra.${var.env}.consul`)",
          # "traefik.http.routers.nuxt-starter.tls=true",
        ]

        # check {
        #   name     = "server-alive"
        #   port     = "server"
        #   type     = "http"
        #   path     = "/health" # v1/ping /docs /metrics
        #   # 30s because can be heavy to lead, better to put it at this interval
        #   interval = "30s"
        #   timeout  = "5s"
        # }

      } # service nuxt-starter

      resources {
        cpu    = 1000 # MHz
        memory = 1000 # MB
      }
    } # task nuxt-starter

  } # group nuxt-starter

}
