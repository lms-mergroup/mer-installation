job "urbandigital" {
  datacenters =  [{{ range datacenters }}"{{.}}"{{end}}]

  type = "service"

  group "urbandigital" {
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
          port "http" {
            static = "9110"
          }
        }


    task "urbandigital" {
      driver = "docker"
      #env {
      #         TZ = trimspace(file("/etc/timezone"))
      #        }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/urbandigital:{{key "valerian 1.0/versions/urbandigital"}}"
        mounts = [
               {
                 type = "bind"
                 target = "/app/appsettings.json"
                 source = "${meta.DFS}/opt/urbandigital/app/appsettings.json"
                },
		        {
                 type = "bind"
                 target = "/app/backupInitData.json"
                 source = "${meta.DFS}/opt/urbandigital/app/backupInitData.json"
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
                },
                {
                    type = "bind"
                 target = "/app/logs"
                 source = "${meta.DFS}/logs/urbandigital"
                }
              ]
		
	      ports = ["http"]

        }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/urbandigital/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/urbandigital/memory"}}
        

      }

      service {
        name = "urbandigital"
        tags = [
                "urbandigital"
            ]
         }
    }
  }
}
