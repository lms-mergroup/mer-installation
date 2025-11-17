
job "siddhi_editor" {

    # Specify Datacenter
    datacenters = [{{ range datacenters }}"{{.}}"{{end}}]

    # Specify job type
    type = "service"
    # define group
    group "siddhi_editor" {

        # define the number of times the tasks need to be executed
        count = 1

        # define job constraints

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
		  port "siddhi_editor_port" {
			  static = 9390
		  }
        }

      task "siddhi_editor" {
            driver = "docker"

            config {
                image = "{{key "valerian 1.0/external services/valkyrie/address"}}/siddhi-editor:{{key "valerian 1.0/versions/siddhi_editor"}}"
                labels {
                    group = "siddhi_editor"
                }
	            mounts = [
                {
                  type = "bind"
                  target = "/home/siddhi_user/siddhi-tooling/wso2/tooling/deployment/workspace"
                  source = "${meta.DFS}/opt/siddhi/apps"
                }           
                ]
		ports = ["siddhi_editor_port"]
            }
            resources {
                cpu    = {{key "valerian 1.0/cluster config/resources/siddhi_editor/cpu"}}
                memory = {{key "valerian 1.0/cluster config/resources/siddhi_editor/memory"}}


            }
            service {
              name = "siddhi-editor"
              port = "siddhi_editor_port"
              tags = ["urlprefix-/siddhi_editor"]
            }
            }
        }
     }




