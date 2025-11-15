def runmodule() {
	def sqlpb = "${ANSIBLE_PREFIX}${INSTALLPACK_PATH}mssql/playbooks"
	def cd = "${ANSIBLE_PREFIX}${CUSTDATA_PATH}${CUST_NAME}"
	def user = "${ENV_TYPE}"
	def custdatadir = "${ANSIBLE_PREFIX}${CUSTDATA_PATH}${CUST_NAME}/${ENV_TYPE}/"
	def installpack = "${ANSIBLE_PREFIX}${INSTALLPACK_PATH}"
	
	stage('Check WinRM status') {
		sh """
			set -e
			docker exec ansible_control ansible -i $cd/$user/common/ansible-connection.yaml sql -m win_ping
			"""
    }
   
    stage('Change hostname and add to domain') {

		sh """
			set -e
			docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" -e "ipack=$installpack" $sqlpb/change-host-add-to-domain.yaml
			"""

    }

    stage ('Parallel work') {
       parallel (
         "Main": {
           stage('SQL add firewall rules') {

               sh """
                  set -e
                  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir/mssql" $sqlpb/sql-add-firewall-rules.yaml
                  """

            }
    
           stage('Add domain user to admin') {
 
              sh """
                 set -e
                 docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $sqlpb/add-domain-user-to-admin-group.yaml
                """
            }
         },
        "CopySQLiso": {
           stage('Copy MS SQL iso ') {
        
                sh """
                   set -e
                   docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir/mssql" $sqlpb/copy-sql-iso.yaml
                   """
                 
             }
          stage('copy SQL server ISO - set completion flag'){
            
              echo "Set flag file for SQL ISO copy completion"
              writeFile file: 'SQLDone_Status.txt', text: 'true'
              echo "Flag SQLDone_Status.txt written"
            
            }

        }
      )
     }
    stage('Wait for done.txt') {
    
        script {
            waitUntil {
                echo "Waiting for done.txt in ${env.WORKSPACE}..."
                return fileExists('SQLDone_Status.txt')
            }
            echo "done.txt is here!"
        
      }
    }
     
    stage('Install MS SQL') {
      
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir/mssql" $sqlpb/sql-install.yaml

          """
      
    }
    
    stage('Start SQL agent') {
      
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir/mysql" $sqlpb/sql-start-agent.yaml
          """
      
    }
     stage('Enable network access MSDTC') {
      
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" $sqlpb/enable-network-access-msdtc.yaml
          """
      
    }
 
      stage('Add 2 new SQL admins') {
      
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" -e "ipack=$installpack" $sqlpb/sql-add-sql-admins.yaml
          """
      
    }
	
	   stage('Wait for ExtractSMNG_Status.txt') {
       
        script {
          waitUntil {
            echo "Waiting for ExtractSMNG_Status.txt.txt in ${env.WORKSPACE}..."
          return fileExists('ExtractSMNG_Status.txt')
         }
         echo "IISfeaturesDone is here!"
       
      }
     }
    
      stage('Update DBUpdater config file') {
      
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" -e "ipack=$installpack" $sqlpb/update-dbupdater-config-file.yaml
          """
      
    }
      stage('Create DB using DBUpdater.CLI') {
      
        sh """
          set -e
          
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" -e "ipack=$installpack" $sqlpb/create-dbs.yaml

          """
      
    }
    
    stage('Update admin in SmartM user table') {
      
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" -e "ipack=$installpack" $sqlpb/update-admin-in-user-table.yaml
          """
      
    }
    stage('Update GIS url') {
      
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" -e "ipack=$installpack" $sqlpb/update-gis-url.yaml
          """
      
    }
     stage('Add SmartMuser as Admin and owner on tables') {
      
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "customer_data_dir=$custdatadir" -e "ipack=$installpack" $sqlpb/add-sql-smartm-user.yaml
          """
      
    }

}
return this