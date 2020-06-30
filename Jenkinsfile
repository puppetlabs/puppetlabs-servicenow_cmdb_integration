@Library('puppet_jenkins_shared_libraries') _
import com.puppet.jenkinsSharedLibraries.BundleInstall
import com.puppet.jenkinsSharedLibraries.BundleExec

pipeline{
    agent{
        label 'worker'
    }
    environment {
      RUBY_VERSION='2.5.1'
      GEM_SOURCE='https://artifactory.delivery.puppetlabs.net/artifactory/api/gems/rubygems/'
      RAKE_TEST_TASK='rake acceptance:ci_run_tests'
    }
    stages{
        stage('acceptance'){
            steps{
                echo 'Pwned'
            }
        }
    }
}
