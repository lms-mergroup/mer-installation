job "mongo" {
        datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

        type = "service"
        priority = 100
 
        group "mongo" {
        
        count = 1
        restart {
            attempts = 5
            interval = "30m"
            delay = "20s"
            mode = "fail"
          }

        reschedule {
            delay          = "3m"
            delay_function = "exponential"
            max_delay      = "1h"
            unlimited      = false
              attempts = 3
          interval = "30m"
          }
 

        
        network {
          port "db_m" {
            static = "27017"
          }
        }

         ephemeral_disk {
             size = 300
          }
 
         task "mongo" {
             driver = "docker"
            env {
              MONGO_INITDB_ROOT_USERNAME = "admin"
              MONGO_INITDB_ROOT_PASSWORD = "password"
              #TZ = trimspace(file("/etc/timezone"))
            }
             config {
               image = "{{key "valerian 1.0/external services/valkyrie/address"}}/mongo:{{key "valerian 1.0/versions/mongo"}}"
               mounts = [
                {
                  type = "bind"
                  target = "/data/db"
                  source = "${meta.DFS}/opt/mongo/db"
                },
                {
                  type = "bind"
                  target = "/data/configdb"
                  source = "${meta.DFS}/opt/mongo/configdb"
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
              
              ports = ["db_m"]
         }
          resources {
                cpu    = {{key "valerian 1.0/cluster config/resources/mongo/cpu"}}
                memory = {{key "valerian 1.0/cluster config/resources/mongo/memory"}}
           }
 
      service {
            name = "mongodb"
            tags = ["urlprefix-:27017 proto=tcp"]
            port = "db_m"
            check {
                type = "tcp"
                interval = "10s"
                timeout = "4s"
        }
      }
    }
  }
}
