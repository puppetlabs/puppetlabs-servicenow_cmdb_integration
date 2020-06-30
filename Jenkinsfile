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
      CI='true'
    }
    stages{
        stage('acceptance'){
            steps{
                echo 'Bundle Install'
                script {
                  def setup_gems = new BundleInstall(env.RUBY_VERSION)
                  sh "${setup_gems.bundleInstall}"
                }
                echo 'Run Acceptance'
                script {
                  def bundle_exec = new BundleExec(env.RUBY_VERSION, env.RAKE_TEST_TASK)
                  sh "${bundle_exec.bundleExec}"
                }
            }
        }
    }
    post{
        always{
            echo 'Upload JUnit Results File'
            junit 'rspec.xml'
        }
    }
}
