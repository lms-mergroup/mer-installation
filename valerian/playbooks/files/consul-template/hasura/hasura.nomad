
  job "hasura" {

   datacenters = [
        {{ range datacenters }}"{{.}}"{{end}}
    ]

  type = "service"


  update {

    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }


  migrate {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }


  group "hasura" {

    count = 1


    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }


    task "hasura" {
      driver = "docker"
      env {
        HASURA_GRAPHQL_DATABASE_URL="postgres://postgres:password@postgres.service.dev.valerian:5432/MauiDB"
        HASURA_GRAPHQL_ENABLE_CONSOLE="true"
      }

      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/valkyrie:8083/hasura_gql:1.0"
        port_map {
          access_point = 8080
        }
      }

      resources {
        cpu    = 1024
        memory = 1024
        network {
          mbits = 10
          port "access_point" {
              static = "8066"
          }
        }
      }


      service {
        name = "hasura"
        tags = ["gql", "hasura"]
        port = "access_point"
      }

    }
  }
}
