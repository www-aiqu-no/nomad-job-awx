## =============================================================================
# Application: Ansible Tower Community (awx) v3.0.1 and lower
# Nomad Version Used: 0.9.1
## =============================================================================
job "awx-301" {
  datacenters = ["dc1"]
  region      = "global"

  type     = "service"
  priority =  60

  update {
    min_healthy_time  = "15s"
    healthy_deadline  = "15m"
    progress_deadline = "30m"
    health_check      = "checks"
    auto_revert       = true
    max_parallel      = 1
  }

## =============================================================================
##   START group/tower
## =============================================================================

  group "tower" {
    count = 1

    restart {
      attempts = 5
      delay    = "30s"
      interval = "5m"
      mode     = "fail"
    }

    reschedule {
      unlimited      = false
      attempts       = 5
      interval       = "1h"
      delay          = "30s"
      delay_function = "fibonacci"
      max_delay      = "1h"
    }

## -----------------------------------------------------------------------------

    task "awx" {
      driver = "docker"

      resources {
        cpu    = 1000
        memory = 1000
      }

      env {
        SECRET_KEY = "aabbcc"

        #AWX_ADMIN_USER      = "awx"
        #AWX_ADMIN_PASSWORD  = "awx_secret"
        #AWX_SKIP_MIGRATIONS = true

        DATABASE_USER     = "awx"
        DATABASE_PASSWORD = "awxpass"
        DATABASE_NAME     = "awx"
        DATABASE_HOST     = "${NOMAD_IP_postgres_tcp}" #"postgres"
        DATABASE_PORT     = "${NOMAD_PORT_postgres_tcp}" #5432

        RABBITMQ_USER     = "guest"
        RABBITMQ_PASSWORD = "guest"
        RABBITMQ_VHOST    = "awx"
        RABBITMQ_HOST     = "${NOMAD_IP_rabbitmq_amqp}" #"rabbitmq"
        RABBITMQ_PORT     = "${NOMAD_PORT_rabbitmq_amqp}" #5672

        MEMCACHED_HOST = "${NOMAD_IP_memcached_api}" #"memcached"
        MEMCACHED_PORT = "${NOMAD_PORT_memcached_api}" #11211
      }

      config {
        image = "ansible/awx_task:3.0.1"
        hostname = "awx"
      }
    } # END task/awx-task

## -----------------------------------------------------------------------------

    task "awxweb" {
      driver = "docker"

      resources {
        cpu    = 750
        memory = 1000
        network {
          mbits = 25
          port "http"  { static = 8052 }
        }
      }

      env {
        SECRET_KEY = "aabbcc"

        #AWX_ADMIN_USER      = "awx"
        #AWX_ADMIN_PASSWORD  = "awx_secret"
        #AWX_SKIP_MIGRATIONS = true

        DATABASE_USER     = "awx"
        DATABASE_PASSWORD = "awxpass"
        DATABASE_NAME     = "awx"
        DATABASE_HOST     = "${NOMAD_IP_postgres_tcp}" #"postgres"
        DATABASE_PORT     = "${NOMAD_PORT_postgres_tcp}" #5432

        RABBITMQ_USER     = "guest"
        RABBITMQ_PASSWORD = "guest"
        RABBITMQ_VHOST    = "awx"
        RABBITMQ_HOST     = "${NOMAD_IP_rabbitmq_amqp}" #"rabbitmq"
        RABBITMQ_PORT     = "${NOMAD_PORT_rabbitmq_amqp}" #5672

        MEMCACHED_HOST = "${NOMAD_IP_memcached_api}" #"memcached"
        MEMCACHED_PORT = "${NOMAD_PORT_memcached_api}" #11211
      }

      config {
        image = "ansible/awx_web:3.0.1"
        hostname = "awxweb"
        port_map {
          http  = 8052
        }
      }
    } # END task/awx-task
## -----------------------------------------------------------------------------

    task "rabbitmq" {
      driver = "docker"

      resources {
        cpu    = 125
        memory = 250
        network {
          mbits = 10
          port "amqp"  { static = 5672 }
          port "admin" { static = 15672 }
        }
      }

      env {
        RABBITMQ_DEFAULT_VHOST = "awx"
        RABBITMQ_DEFAULT_USER  = "guest"
        RABBITMQ_DEFAULT_PASS  = "guest"
        RABBITMQ_ERLANG_COOKIE = "cookiemonster"
      }

      config {
        image = "ansible/awx_rabbitmq:latest"
        port_map {
          amqp  = 5672
          admin = 15672
          #cluster = 25672
        }
      }
    } # END task/rabbitmq

## -----------------------------------------------------------------------------

    task "memcached" {
      driver = "docker"

      resources {
        cpu    = 100
        memory = 100
        network {
          mbits = 10
          port "api" { static = 11211 }
        }
      }

      config {
        image = "memcached:1.5-alpine"
        port_map {
          api = 11211
        }
      }
    } # END task/memcached

## -----------------------------------------------------------------------------

    task "postgres" {
      driver = "docker"

      resources {
        cpu    = 250
        memory = 250
        network {
          mbits = 10
          port "tcp" { static = 5432 }
        }
      }

      env {
        POSTGRES_USER     = "awx"
        POSTGRES_PASSWORD = "awxpass"
        POSTGRES_DB       = "awx"
        PGDATA            = "/var/lib/postgresql/data/pgdata"
      }

      config {
        image = "postgres:9.6-alpine"
        port_map {
          tcp = 5432
        }
        # To persist the storage, restrict to specific node, or configure
        # persistent storage in some other way
        # Note: NOMAD does not clean up unused docker volumes
        #volume_driver = "local"
        #volumes = [
        #  "awx301-pg-v1:/var/lib/postgresql/data/pgdata"
        #]
      }
    } # END task/postgres

  } # END group/kos

## =============================================================================

} # END job
