job "timescaledb" {

   datacenters = [
        {{ range datacenters }}"{{.}}"{{end}}
    ]

  type = "service"

  group "timescaledb" {

        count = 1
        restart {
            attempts = 5
            interval = "30m"
            delay = "20s"
            mode = "fail"
          }

        reschedule {
            attempts       = 15
            interval       = "1h"
            delay          = "30s"
            delay_function = "exponential"
            max_delay      = "120s"
            unlimited      = false
        }

        
        network {
          port "db" {
            static = "5433"
            to = "5432"
          }
        }
	
      ephemeral_disk {
        size = 300
      }



    task "timescaledb" {
      driver = "docker"
      env {
          POSTGRES_PASSWORD="password"
          #TZ = trimspace(file("/etc/timezone"))
      }

      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/timescaledb:{{key "valerian 1.0/versions/timescaledb"}}"
        mounts = [
            {
                type = "bind"
                target = "/var/lib/postgresql/data/"
                source = "/v/opt/timescaledb/"
            },
            {
                  type = "bind"
                  target = "/etc/timezone"
                  source = "/etc/timezone"
                },
				{
                  type = "bind"
                  target = "/etc/localtime"
                  source = "/etc/localtime"
                } 
        ]

        ports = ["db"]
      }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/timescaledb/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/timescaledb/memory"}}
      }


      service {
        name = "timescale"
        port = "db"
      }

    }
  }
}
