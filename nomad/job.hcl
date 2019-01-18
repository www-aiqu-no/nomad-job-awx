## =============================================================================
## Application: Ansible Tower Community (awx)
##   - awx-task
##   - awx-web
##   - postgres
##   - memcached
##   - rabbitmq
## =============================================================================
job "core-awx" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel = 1
    auto_revert  = true
  }

## =============================================================================
##   START group/main
## =============================================================================

  group "main" {
    count = 1

    update {
      health_check     = "checks"
      min_healthy_time = "15s"
      healthy_deadline = "8m"
    }

## -----------------------------------------------------------------------------

    task "task" {
      driver = "docker"

      resources {
        cpu    = 750
        memory = 1024
        network {
          mbits = 10
          port "api" {
            #static = 8052
          }
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
        image = "ansible/awx_task:latest"
        hostname = "awx"
        port_map {
          api = 8052
        }
      }
    } # END task/awx-task

## -----------------------------------------------------------------------------

    task "web" {
      driver = "docker"

      resources {
        cpu    = 750
        memory = 1024
        network {
          mbits = 25
          port "ui" {
            static = 8052
          }
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
        image = "ansible/awx_web:latest"
        hostname = "awxweb"
        port_map {
          ui = 8052
        }
      }
    } # END task/awx-task

## -----------------------------------------------------------------------------

    task "postgres" {
      driver = "docker"

      resources {
        cpu    = 250
        memory = 512
        network {
          mbits = 10
          port "tcp" {
            static = 5432
          }
        }
      }

      env {
        POSTGRES_USER     = "awx"
        POSTGRES_PASSWORD = "awxpass"
        POSTGRES_DB       = "awx"

        PGDATA = "/var/lib/postgresql/data/pgdata"
      }

      config {
        image = "postgres:alpine"

        port_map {
          tcp = 5432
        }

        # To persist the storage, restrict to specific node, or configure
        # persistent storage in some other way
        # Note: NOMAD does not clean up unused docker volumes
        volumes = [
          "awx-postgres-v1:/var/lib/postgresql/data/pgdata"
        ]
        volume_driver = "local"
      }
    } # END task/postgres

## -----------------------------------------------------------------------------

    task "memcached" {
      driver = "docker"

      resources {
        cpu    = 125
        memory = 256
        network {
          mbits = 10
          port "api" {
            static = 11211
          }
        }
      }

      config {
        image = "memcached:alpine"

        port_map {
          api = 11211
        }
      }
    } # END task/memcached

## -----------------------------------------------------------------------------

    task "rabbitmq" {
      driver = "docker"

      resources {
        cpu    = 125
        memory = 256
        network {
          mbits = 10
          port "amqp" {
            static = 5672
          }
        }
      }

      env {
        RABBITMQ_DEFAULT_VHOST = "awx"
        RABBITMQ_DEFAULT_USER  = "guest"
        RABBITMQ_DEFAULT_PASS  = "guest"
        RABBITMQ_ERLANG_COOKIE = "cookiemonster"
      }

      config {
        image = "rabbitmq:alpine"

        port_map {
          amqp = 5672
        }
      }
    } # END task/rabbitmq
  } # END group/kos

## =============================================================================

} # END job
