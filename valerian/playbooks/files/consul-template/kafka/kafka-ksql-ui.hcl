job "kafka-ksql-ui" {
    datacenters = [
          {{ range datacenters }}"{{.}}"{{end}}
    ]

    type = "service"
    priority = 70

 
    group "kafka-ksql-ui" {
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
            mode = "host"
            port "ksql" {
              static = "8097"
              to = "8088"
            }
            port "kafka_ui" {
              static = "8099"
              to = "8080"
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
 	  
	
        task "ksql-server" {
          driver = "docker" 
          
          env{
                KSQL_BOOTSTRAP_SERVERS="kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}:29092"
                KSQL_LISTENERS="http://0.0.0.0:8088/"
                KSQL_KSQL_SERVICE_ID="ksql_service_3_"
                KSQL_CONFIG_DIR="/etc/ksql"
                #KSQL_KSQL_QUERIES_FILE="/etc/ksql/queries/queries.sql"
                KSQL_PRODUCER_INTERCEPTOR_CLASSES="io.confluent.monitoring.clients.interceptor.MonitoringProducerInterceptor"
                KSQL_CONSUMER_INTERCEPTOR_CLASSES="io.confluent.monitoring.clients.interceptor.MonitoringConsumerInterceptor"
                #TZ = trimspace(file("/etc/timezone"))
              }

          config {
              image = "{{key "valerian 1.0/external services/valkyrie/address"}}/ksql-server:{{key "valerian 1.0/versions/ksql-server"}}"
              ports=["ksql"]
              
              mounts = [
                  #{
                  #  type = "bind"
                  #  target = "/etc/ksql"
                  #  source = "${meta.DFS}/opt/kafka/ksql"
                  #},
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
            }
            
          resources {
              cpu    = {{key "valerian 1.0/cluster config/resources/ksql-server/cpu"}}
              memory = {{key "valerian 1.0/cluster config/resources/ksql-server/memory"}}
            }
          service {
              name = "ksql"

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
  
        task "kafka-ui" {
          driver = "docker" 

          env{
                 KAFKA_CLUSTERS_0_NAME="local" 
                 KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS="kafka.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}:29092" 
                 KAFKA_CLUSTERS_0_KSQLDBSERVER="http://ksql.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}}:8097"
                 #TZ = trimspace(file("/etc/timezone"))
              }

          config {
              image = "{{key "valerian 1.0/external services/valkyrie/address"}}/kafka-ui:{{key "valerian 1.0/versions/kafka-ui"}}"
              ports=["kafka_ui"]
              
              mounts = [
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
            }
          resources {
              cpu    = {{key "valerian 1.0/cluster config/resources/kafka-ui/cpu"}}
              memory = {{key "valerian 1.0/cluster config/resources/kafka-ui/memory"}}
            }
          service {
                  name = "kafka-ui"

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

