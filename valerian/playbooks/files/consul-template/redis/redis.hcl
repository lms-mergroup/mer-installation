job "redis" {
    datacenters = [
      {{ range datacenters }}"{{.}}"{{end}}
    ]

    type = "service"
    priority = 90
 
    group "redis" {
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
			    static = "6379"
		    }
      }
 
         ephemeral_disk {
             size = 300
          }
 
         task "redis" {
             driver = "docker"
             env {
               #TZ = trimspace(file("/etc/timezone"))
              }
 
             config {
               image = "{{key "valerian 1.0/external services/valkyrie/address"}}/redis:{{key "valerian 1.0/versions/redis"}}"
               mounts = [
                {
                  type = "bind"
                  target = "/usr/local/etc/redis/"
                  source = "${meta.DFS}/opt/redis/conf/"
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
              args = ["redis-server", "/usr/local/etc/redis/redis.conf"]
              ports = ["db"]
              
         }
          resources {
                  cpu    = {{key "valerian 1.0/cluster config/resources/redis/cpu"}}
                  memory = {{key "valerian 1.0/cluster config/resources/redis/memory"}}
           }
 
        service {
              name = "redis"
              tags = ["urlprefix-:6379 proto=tcp"]
              port = "db"
              check {
                  type = "tcp"
                  interval = "10s"
                  timeout = "4s"
          }
       }
    }
  }
}