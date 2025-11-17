job "logstash" {
        datacenters = [
            {{ range datacenters }}"{{.}}"{{end}}
        ]

        type = "service"
 
    group "logstash" {
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
            static = "5044"
          }
        }
         task "logstash" {
             driver = "docker" 
             env {
               #TZ = trimspace(file("/etc/timezone"))
              }
	     config {
               image = "{{key "valerian 1.0/external services/valkyrie/address"}}/logstash:{{key "valerian 1.0/versions/logstash"}}"
	       #command = "bin/logstash-plugin install logstash-output-mongodb"
               mounts = [
               {
                 type = "bind"
                 target = "/usr/share/logstash/config"
                 source = "${meta.DFS}/opt/logstash/config"

                },
                {
                 type = "bind"
		         target = "/usr/share/logstash/pipeline"
		         source = "${meta.DFS}/opt/logstash/pipeline"
                },
                {
                  type = "bind"
                  target = "/usr/share/logstash/lib/pluginmanager"
                  source = "${meta.DFS}/opt/logstash/lib/pluginmanager"
                },
                {
                  type = "bind"
                  target = "/usr/share/logstash/driver"
                  source = "${meta.DFS}/opt/logstash/driver"
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
	        ports = ["http"]
         }
         resources {
                cpu    = {{key "valerian 1.0/cluster config/resources/logstash/cpu"}}
                memory = {{key "valerian 1.0/cluster config/resources/logstash/memory"}}
       }
 
            service {
                 name = "logstash"
                
                 port = "http"
       }
 

    }
  }
}
