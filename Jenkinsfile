pipeline {
  environment {
    registry = "ganeshghube23/ngnix"
    registryCredential = 'dockerhub'
    dockerImage = ''
  }
  agent any
  stages {
    stage('Cloning Git') {
      steps {
        sh "rm -rf *"
        sh "git clone https://github.com/ganeshghube/jenkinsci.git"
        sh 'cp jenkinsci/* .'
      }
    }
    stage('Building image') {
      steps{
        script {
          dockerImage = docker.build registry + ":$BUILD_NUMBER"
        }
      }
    }
    stage('Deploy Image') {
      steps{
        script {
          docker.withRegistry( '', registryCredential ) {
            dockerImage.push()
          }
        }
      }
    }
    stage('Remove Unused docker image') {
      steps{
        sh "docker rmi $registry:$BUILD_NUMBER"
    }   
      }
	  
	 stage('Security Scan docker image') {
      steps{
		writeFile file: 'anchore_images', text:"$registry:$BUILD_NUMBER"
		anchore name: 'anchore_images' , bailOnFail: false, engineRetries: '800'
	    anchore engineCredentialsId: 'anchoreengine', engineurl: 'http://localhost:8228/v1', forceAnalyze: true, name: 'anchore_images'
		
		}
        
    }
  }
}
