
job "siddhi" {

    # Specify Datacenter
    datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

    # Specify job type
    type = "service"
    priority = 85
    
    group "siddhi" {
    

    # define the number of times the tasks need to be executed
    count = 1

    # specify the number of attemtps to run the job within the specified interval
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
		  port "http1" {
			  static = "9090"
		  }
		  
		  port "http2" {
			  static = "9443"
		  }
        }
		

  
  	task "wait-for-kafka" {
		lifecycle {
		  hook = "prestart"
		  sidecar = false
		}

		driver = "exec"
		config {
		  command = "sh"
		  args = ["-c", "while ! nc -z kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 29092; do sleep 1; done"]
		}
	}


	task "kafka-companion" {
		lifecycle {
		  hook = "poststart"
		  sidecar = true
		}

		driver = "exec"
		config {
		  command = "sh"
		  args = ["-c", "while nc -z kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 29092; do sleep 1; done"]
		}
	}
	
      task "siddhi" {
            driver = "docker"
            env {
               #TZ = trimspace(file("/etc/timezone"))
              }

            config {
                image = "{{key "valerian 1.0/external services/valkyrie/address"}}/siddhi:{{key "valerian 1.0/versions/siddhi"}}"
                labels {
                    group = "siddhi"
                }

                args = [
                    "-Dapps=/apps",
                    "-Dfiles=/files",
                    "-Dlog4j2.formatMsgNoLookups=true"
                ]
	            mounts = [
                {
                  type = "bind"
                  target = "/apps"
                  source = "${meta.DFS}/opt/siddhi/apps"
                },
                {
                  type = "bind"
                  target = "/configs"
                  source = "${meta.DFS}/opt/siddhi/config"
                },
                {
                  type = "bind"
                  target = "/home/siddhi_user/siddhi-runner-0.1.0/wso2/runner/logs"
                  source = "${meta.DFS}/logs/siddhi"
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
				
				ports = ["http1", "http2"]
            }
            
            resources {
                cpu    = {{key "valerian 1.0/cluster config/resources/siddhi/cpu"}}
                memory = {{key "valerian 1.0/cluster config/resources/siddhi/memory"}}
            }

            service {
              name = "siddhi"
              port = "http1"
              tags = ["urlprefix-/stream"]

               check {
                    name     = "kafka_alive"
                    type     = "script"
                    command  = "/bin/sh"
                    args     = ["-c", "nc -z kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 29092 && exit 0 || (c=$?; exit 2)"]
                    interval = "60s"
                    timeout  = "20s"

                }

                check_restart {
                    limit = 3
                    grace = "90s"
                    ignore_warnings = false

                }
            }
            }
        }
     }




