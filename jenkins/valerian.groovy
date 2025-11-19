def runmodule() {

	def vlrpb = "${ANSIBLE_PREFIX}${INSTALLPACK_PATH}valerian/playbooks"
	def cd = "${ANSIBLE_PREFIX}${CUSTDATA_PATH}${CUST_NAME}"
	def user = "${ENV_TYPE}"
	def custdatadir = "${ANSIBLE_PREFIX}${CUSTDATA_PATH}${CUST_NAME}/${ENV_TYPE}/"
	def installpack = "${ANSIBLE_PREFIX}${INSTALLPACK_PATH}"
    stage('Valerian- change hostname') {
        sh """
          set -e
           docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/change-hostname.yaml --limit valerian
        """
    }
    
    stage('Install required packages') {
		sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/install-packages.yaml --limit valerian
		"""  
    }
	stage('Add to domain') {
        sh """
          set -e
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/add-to-domain.yaml --limit valerian
		"""
    }
    stage('Enable root login') {
        sh """
          set -e
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/enable-root-login.yaml
		"""
    }


    stage('onsite-prerequisite-common') {
        sh """
          set -e
		  docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/onsite-prerequisite-common.yaml --limit valerian
		"""
    }

    stage('Install consul') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/install-consul.yaml
          """
   }
   
   
      stage('Create directories') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/create-base-directories.yaml
          """
      }
      
      stage('Install nomad') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/install-nomad.yaml
          """
    }
  
    stage('Install consul KV') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/install-consul-kv.yaml
          """
    }
   
    stage('kafka-zookeeper') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/kafka-zookeeper.yaml
          """
    }
     
    stage('server-config') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/server-config.yaml
          """
    }
  
    stage('Consul kv config') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$cd/$user/" $vlrpb/consul-kv-configuration.yaml
          """
    }
	
	stage('Wait for Uploaded_images_Status.txt') {
        script {
              waitUntil {
                echo "⏳ Waiting for Uploaded_images_Status.txt in ${env.WORKSPACE}..."
                return fileExists('Uploaded_images_Status.txt')
              }
              echo "✅ Uploaded_images_Status.txt here!"
             }
    }
    
  
    stage('consul-template') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/consul-template.yaml
          """
    }
    
    stage('Check PG exists') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$custdatadir" $vlrpb/check-pg-exists.yaml
          """
    }


	stage('Create PostgresDB using DBUpdater.CLI') {
        sh """
          set -e
          docker exec ansible_control ansible-playbook -i $cd/$user/common/ansible-connection.yaml -e "ipack=$installpack" -e "customer_data_dir=$cd/$user/" $vlrpb/create-pg-dbs.yaml
          """
    }
     	
}

return this