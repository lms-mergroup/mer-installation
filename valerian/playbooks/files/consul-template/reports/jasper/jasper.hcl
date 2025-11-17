job "jasper" {

   datacenters = [
     {{ range datacenters }}"{{.}}"{{end}}
    ]

  type = "service"



  group "jasper" {

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
		    static = "8090"
		    to = "8080"
	    }
      port "mail" {
		    static = "2525"
		    to = "25"
    	}
    }
	
  



	task "wait-for-pg" {
		lifecycle {
		  hook = "prestart"
		  sidecar = false
		}

		driver = "exec"
		config {
		  command = "sh"
		  args = ["-c", "while ! nc -z pg.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 5432; do sleep 1; done"]
		}
	}
	
    task "jasper" {
      driver = "docker"
      env {
               #TZ = trimspace(file("/etc/timezone"))
              }
      config {
        image = "{{key "valerian 1.0/external services/valkyrie/address"}}/jasper:{{key "valerian 1.0/versions/jasper"}}"
        mounts = [
               {
                 type = "bind"
                 target = "/usr/local/tomcat/logs"
                  source = "${meta.DFS}/logs/jasper"
                },
		       {
                 type = "bind"
                 target = "/usr/local/tomcat/webapps/jasperserver/WEB-INF/lib/mssql-jdbc-7.4.1.jre8.jar"
                  source = "${meta.DFS}/opt/jasperserver/datasources/mssql-jdbc-7.4.1.jre8.jar"
                },
                {
                 type = "bind"
                 target = "/usr/local/tomcat/webapps/jasperserver/WEB-INF/lib/postgresql-42.2.19.jar"
                  source = "${meta.DFS}/opt/jasperserver/datasources/postgresql-42.2.19.jar"
                },
                {
                 type = "bind"
                 target = "/usr/local/tomcat/webapps/jasperserver/META-INF/context.xml"
                 source = "${meta.DFS}/opt/jasperserver/META-INF/context.xml"
                },
                {
                 type = "bind"
                 target = "/usr/local/tomcat/webapps/jasperserver/WEB-INF/bundles"
                 source = "${meta.DFS}/opt/jasperserver/WEB-INF/bundles"
                },
                {
                 type = "bind"
                 target = "/usr/local/tomcat/webapps/jasperserver/WEB-INF/classes/esapi/security-config.properties"
                 source = "${meta.DFS}/opt/jasperserver/WEB-INF/classes/esapi/security-config.properties"
                },
                {
                 type = "bind"
                 target = "/usr/local/tomcat/webapps/jasperserver/WEB-INF/lib/ArialFontFamily.jar"
                 source = "${meta.DFS}/opt/jasperserver/WEB-INF/lib/ArialFontFamily.jar"
                },
                {
                 type = "bind"
                 target = "/usr/local/tomcat/webapps/jasperserver/WEB-INF/lib/SarabunFontFamily.jar"
                 source = "${meta.DFS}/opt/jasperserver/WEB-INF/lib/SarabunFontFamily.jar"
                },
                {
                 type = "bind"
                 target = "/usr/local/tomcat/webapps/jasperserver/WEB-INF/js.quartz.properties"
                 source = "${meta.DFS}/opt/jasperserver/WEB-INF/js.quartz.properties"
                },
                {
                 type = "bind"
                 target = "/usr/local/tomcat/webapps/jasperserver/WEB-INF/applicationContext-report-scheduling.xml"
                 source = "${meta.DFS}/opt/jasperserver/WEB-INF/applicationContext-report-scheduling.xml"
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
 
        ports = ["http", "mail"]

      }

      resources {
        cpu    = {{key "valerian 1.0/cluster config/resources/jasper/cpu"}}
        memory = {{key "valerian 1.0/cluster config/resources/jasper/memory"}}
	

      }


      service {
        name = "jasper"
        tags = ["jasper"]
        port = "http"
	
	check {
          name     = "pg_alive"
          type     = "script"
          command  = "/bin/sh"
	  args     = ["-c", "nc -z pg.service.{{ range datacenters }}{{.}}{{end}}.{{key "valerian 1.0/cluster config/domain"}} 5432 && exit 0 || (c=$?; exit 2)"]
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




