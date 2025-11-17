job "postgis" {

   datacenters = [
        {{ range datacenters }}"{{.}}"{{end}}
    ]

  type = "service"
  priority = 100

  group "postgis" {

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
            static = "5432"
          }
        }
	
      ephemeral_disk {
        size = 300
      }



    task "postgis" {
      driver = "docker"
      env {
          POSTGRES_USER = "postgres"
          POSTGRES_PASSWORD = "password"
          POSTGRES_MULTIPLE_EXTENSIONS="postgis,hstore,postgis_topology"
          #TZ = trimspace(file("/etc/timezone"))
      }

      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/postgis:{{key "valerian 1.0/versions/postgis"}}"
        mounts = [
            {
                type = "bind"
                target = "/var/lib/postgresql/data/"
                source = "/v/opt/postgis/data/"
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
        cpu    = {{key "valerian 1.0/cluster config/resources/postgis/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/postgis/memory"}}
      }


      service {
        name = "pg"
        tags = ["storage", "storage", "gis"]
        port = "db"
      }

    }
  }
}
