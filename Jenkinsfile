pipeline {

  environment {
    PROJECT_DIR = "/app"
    REGISTRY = "oabuoun/secure_rest_api" + ":" + "$BUILD_NUMBER"
    DOCKER_CREDENTIALS = "docker_auth"
    DOCKER_IMAGE = ""
  }

  agent any

  options {
    skipStagesAfterUnstable()
  }

  stages {

    stage('Cloning The Code from GIT') {
      steps {
      checkout([
        $class: 'GitSCM', branches: [[name: '*/main']],
        userRemoteConfigs: [[url: 'git@github.com:oabuoun/secure_rest_calculator.git',credentialsId:'secure_rest_calc']]
      ])

      }

    }

    stage('Build-Image'){
      steps {
        script {
          DOCKER_IMAGE = docker.build REGISTRY
        }
      }
    }

    stage('Testing the Code'){
      steps {
        script {
          sh '''
            docker run --rm -v $PWD/test-results:/reports --workdir $PROJECT_DIR $REGISTRY pytest -v --junitxml=/reports/results.xml
            ls -la $PWD/test-results
          '''

        }
      }
      post {
        always {
          junit testResults: '**/test-results/*.xml'
        }
      }
    }

    stage('Deploy To Docker Hub') {
      steps {
        script {
          docker.withRegistry('', DOCKER_CREDENTIALS){
            DOCKER_IMAGE.push()
          }
        }
      }
    }

    stage('Removing the Docker Image'){
      steps {
        sh "docker rmi $REGISTRY"
      }
    }
  }

}
