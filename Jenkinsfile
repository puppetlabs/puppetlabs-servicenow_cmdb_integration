@Library('puppet_jenkins_shared_libraries@add-ruby-helper-vars') _

pipeline{
    agent {
        label 'worker'
    }
    environment {
      RUBY_VERSION='2.5.1'
      GEM_SOURCE='https://artifactory.delivery.puppetlabs.net/artifactory/api/gems/rubygems/'
      RAKE_SETUP_TASK='rake acceptance:setup'
      RAKE_TEST_TASK='rake acceptance:run_tests'
      RAKE_TEARDOWN_TASK='rake acceptance:tear_down'
      CI='true'
      RESULTS_FILE_NAME='rspec_junit_results.xml'
    }
    stages{

        stage('Setup') {
            steps {
                echo 'Bundle Install'
                bundleInstall env.RUBY_VERSION
                bundleExec env.RUBY_VERSION, env.RAKE_SETUP_TASK
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Run Tests'
                bundleExec env.RUBY_VERSION, env.RAKE_TEST_TASK
            }
        }
    }
    post{
        always {
            if(fileExists env.RESULTS_FILE_NAME) {
                junit env.RESULTS_FILE_NAME
            }
        }
        cleanup {
            bundleExec env.RUBY_VERSION, env.RAKE_TEARDOWN_TASK
        }
    }
}
