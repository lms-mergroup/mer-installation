  job "minio" {

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


  group "minio" {

    count = 1


    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }


    task "minio" {
      driver = "docker"
      env {
        MINIO_ACCESS_KEY="stiletto"
        MINIO_SECRET_KEY="BlackbirdSR71"
        TZ = trimspace(file("/etc/timezone"))
      }

      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/minio:{{key "valerian 1.0/versions/minio"}}"
        args = [ "server", "/data"]
        mounts = [
            {
                type = "bind"
                target = "/data"
                source = "/v/minio/storage"
            }
        ]
        port_map {
          access_point = 9000
        }
      }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/minio/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/minio/memory"}}
        network {
          mbits = 10
          port "access_point" {
              static = "{{key "valerian 1.0/cluster config/resources/minio/port"}}"
          }
        }
      }


      service {
        name = "minio"
        tags = ["storage", "minIO"]
        port = "access_point"
      }

    }
  }
}
