pipeline {
	agent any
	triggers {
		cron('H 4 * * *')
		pollSCM('H/2 * * * *') 
	}
	stages {
		stage('Tooling') {
			steps {
				sh 'ponyc --version'
			}
		}
		stage('Build') {
			steps {
				sh 'ponyc -b pony-statsd net/statsd'
				archiveArtifacts artifacts: 'pony-statsd', fingerprint: true
			}
		}
		stage('Test') {
			steps {
				sh './pony-statsd'
			}
		}
	}

	/* set up notifications */
	post {
		always {
			echo 'One way or another, I have finished'
			/* deleteDir() */ /* clean up our workspace */
		}
		success {
			echo 'I succeeeded!'
		}
		unstable {
			echo 'I am unstable :/'
			mail to: "${env.PONY_STATSD_BUILD_EMAIL}",
			  subject: "Pipeline unstable: ${currentBuild.fullDisplayName}",
			  body: "The build is unstable: ${env.BUILD_URL}"
		}
		failure {
			echo 'I failed :('
			mail to: "${env.PONY_STATSD_BUILD_EMAIL}",
			  subject: "Pipeline failed: ${currentBuild.fullDisplayName}",
			  body: "The build has failed: ${env.BUILD_URL}"
		}
		changed {
			echo 'Things were different before...'
			mail to: "${env.PONY_STATSD_BUILD_EMAIL}",
			  subject: "Pipeline status changed: ${currentBuild.fullDisplayName} now ${currentBuild.result}",
			  body: "The status of the build has changed: ${env.BUILD_URL}"
		}
	}
}
