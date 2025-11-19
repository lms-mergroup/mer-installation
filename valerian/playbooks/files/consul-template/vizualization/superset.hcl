
job "superset" {
  type = "service"
  datacenters = [
        {{ range datacenters }}"{{.}}"{{end}}
    ]

  group "superset" {
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
          port "server" {
            static = "8085"
            to = "8088"
          }
        }

    task "superset" {
      driver = "docker"
        env {
          MAPBOX_API_KEY = "pk.eyJ1IjoidmFsZXJpYW4tbWVyIiwiYSI6ImNrdzBrZHpjdjFjanQybnFpb2V2aXdkZjkifQ.Vyu7s37N4gLkGm5BSKxPQA"
          #ADMIN_USERNAME = "admin"
          #ADMIN_PWD = "admin"
          #TZ = trimspace(file("/etc/timezone"))
        }

      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/superset:{{key "valerian 1.0/versions/superset"}}"
        
        mounts = [        
            {
                type = "bind"
                target = "/app/superset/config.py"
                source = "${meta.DFS}/opt/superset/config/config.py"
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
        ports = ["server"]
      }

     
      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/superset/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/superset/memory"}}
      }

      service {
        name = "superset"
        tags = ["global", "visualization"]
        port = "server"
      }

   
    }
  }
}


