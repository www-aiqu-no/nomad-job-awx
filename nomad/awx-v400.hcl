# ==============================================================================
# Configure parameters: AWX (Ansible Tower) v4.0.0
# Nomad Version Used for testing: 0.9.1
#
# NOTE:
#  - Some config files are required to be added to disk
#  - ENV variables does not seem to work, hence all ports in example are static
#  - You can use Adminer (port 8080) to view database. Remember to change type to 'postgres'
#  - database is not persisted by default. See info in postgres-task
#  - To test clustering/scaling, you should put database in another job or group (or use external db)
# ==============================================================================

job "awx-400" {
  datacenters = ["dc1"]
  region      = "global"

  type        = "service"
  priority    = 60

  update {
    min_healthy_time  = "15s"
    healthy_deadline  = "15m"
    progress_deadline = "30m"
    health_check      = "checks"
    auto_revert       = true
    max_parallel      = 1
  }

  #constraint {}

# ==============================================================================
#  START group/tower
# ==============================================================================

  group "tower" {
    count = 1

    #affinity {}

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

      # Required on disk. Will download all files to default allocation folder
      artifact {
        source = "git::https://github.com/www-aiqu-no/nomad-job-awx/resources"
      }

      env {
        AWX_ADMIN_USER     = "awx"
        AWX_ADMIN_PASSWORD = "awx_secret"
        #AWX_SKIP_MIGRATIONS = true

        DATABASE_NAME     = "awx"
        DATABASE_USER     = "awx"
        DATABASE_PASSWORD = "awx_database"
        DATABASE_HOST     = "${NOMAD_IP_postgres_tcp}"
        DATABASE_PORT     = "${NOMAD_PORT_postgres_tcp}"

        RABBITMQ_VHOST      = "awx"
        RABBITMQ_USER       = "awx"
        RABBITMQ_PASSWORD   = "awx_rabbit"
        RABBITMQ_HOST       = "${NOMAD_IP_rabbitmq_amqp}"
        RABBITMQ_PORT       = "${NOMAD_PORT_rabbitmq_amqp}"

        MEMCACHED_HOST      = "${NOMAD_IP_memcached_tcp}"
        MEMCACHED_PORT      = "${NOMAD_PORT_memcached_tcp}"
      }

      config {
        image = "ansible/awx_task:4.0.0"
        hostname = "awx"
        volumes = [
          "local/SECRET_KEY:/etc/tower/SECRET_KEY",
          "local/environment.sh:/etc/tower/conf.d/environment.sh"
          #"local/credentials.py:/etc/tower/conf.d/credentials.py"
        ]
      }
    } # END task/awx

## -----------------------------------------------------------------------------

    task "awxweb" {
      driver = "docker"

      resources {
        cpu    = 1000
        memory = 1000
        network {
          mbits = 25
          port "http"  { static = 8052 }
          port "https" { static = 8053 }
        }
      }

      # Required on disk. Will download all files to default allocation folder
      artifact {
        source = "git::https://github.com/www-aiqu-no/nomad-job-awx/resources"
      }

      env {
        AWX_ADMIN_USER     = "awx"
        AWX_ADMIN_PASSWORD = "awx_secret"
        #AWX_SKIP_MIGRATIONS = true

        DATABASE_USER     = "awx"
        DATABASE_PASSWORD = "awx_database"
        DATABASE_NAME     = "awx"
        DATABASE_HOST     = "${NOMAD_IP_postgres_tcp}"
        DATABASE_PORT     = "${NOMAD_PORT_postgres_tcp}"

        RABBITMQ_VHOST    = "awx"
        RABBITMQ_USER     = "awx"
        RABBITMQ_PASSWORD = "awx_rabbit"
        RABBITMQ_HOST     = "${NOMAD_IP_rabbitmq_amqp}"
        RABBITMQ_PORT     = "${NOMAD_PORT_rabbitmq_amqp}"

        MEMCACHED_HOST = "${NOMAD_IP_memcached_tcp}"
        MEMCACHED_PORT = "${NOMAD_PORT_memcached_tcp}"
      }

      config {
        image = "ansible/awx_web:4.0.0"
        hostname = "awxweb"
        port_map {
          http  = 8052
          https = 8053
        }
        volumes = [
          "local/SECRET_KEY:/etc/tower/SECRET_KEY",
          "local/environment.sh:/etc/tower/conf.d/environment.sh",
          #"local/credentials.py:/etc/tower/conf.d/credentials.py"
        ]
      }
    } # END task/awxweb

## -----------------------------------------------------------------------------

    task "rabbitmq" {
      driver = "docker"

      resources {
        cpu    = 125
        memory = 250
        network {
        mbits = 25
          port "amqp"    { static = 5672  }
          port "admin"   { static = 15672 }
          port "cluster" { static = 25672 }
        }
      }

      env {
        RABBITMQ_DEFAULT_VHOST = "awx"
        RABBITMQ_DEFAULT_USER  = "awx"
        RABBITMQ_DEFAULT_PASS  = "awx_rabbit"
        RABBITMQ_ERLANG_COOKIE = "cookiemonster"
        RABBITMQ_NODE_PORT     = "5672"
        #RABBITMQ_USE_LONGNAME  = "true"
      }

      config {
        image = "ansible/awx_rabbitmq:latest"
        port_map {
          amqp    = 5672
          cluster = 25672
          admin   = 15672
          #amqp_tls = 5671
          #epmd = 4369
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
          port "tcp" { static = 11211 }
        }
      }

      config {
        image = "memcached:1.5-alpine"
        port_map {
          tcp = 11211
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
          mbits = 50
          port "tcp" { static = 5432 }
        }
      }

      env {
        POSTGRES_DB       = "awx"
        POSTGRES_USER     = "awx"
        POSTGRES_PASSWORD = "awx_database"
        PGDATA            = "/var/lib/postgresql/data/awx"
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
        #  "awx400-pg-v1:/var/lib/postgresql/data/awx"
        #]
      }
    } # END task/postgres

## -----------------------------------------------------------------------------

    task "adminer" {
      driver = "docker"

      resources {
        cpu    = 100
        memory = 100
        network {
          mbits = 10
          port "http" { static = 8080 }
        }
      }

      env {
        ADMINER_DEFAULT_SERVER = "${NOMAD_ADDR_postgres_tcp}"
      }

      config {
        image = "adminer:4.7"
        port_map {
          http = 8080
        }
      }
    } # END task/adminer

## -----------------------------------------------------------------------------

  } # END group/tower

# ==============================================================================

} # END job
