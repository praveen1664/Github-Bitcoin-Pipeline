#!/usr/bin/env groovy

def getBranch() {
    env.CHANGE_BRANCH ? env.CHANGE_BRANCH : env.GIT_BRANCH
}

def getEnvironments() {
    readJSON file: 'environments.json'
}

def getTestTargets(environments, testTarget) {
    environments.auto_deploy_test_targets.findAll{testTarget =~ /^$it.key$/}
                                           .collect{it -> it.value}
                                           .flatten()
}

def getBranchTargets(environments, branchTarget) {
    environments.auto_deploy_branch_targets.findAll{branchTarget =~ /^$it.key$/}
                                           .collect{it -> it.value}
                                           .flatten()
}

def login_to_registry() {
    sh(script: '''
               echo "$JFROG_CREDENTIALS_PSW" | docker login --username "$JFROG_CREDENTIALS_USR" --password-stdin "$REGISTRY_REPO"
               ''',
       label: 'Log in to Docker Registry',
    )
}

def getKubeconfigShell(clusterName) {
    """
    aws eks update-kubeconfig \
        --name ${clusterName} \
        --kubeconfig kube-config
    export KUBECONFIG=kube-config
    kubectl cluster-info
    """
}

def getCloudFrontDistribution(domainName){
    """
    aws cloudfront list-distributions \
        --query "DistributionList.Items[?Aliases.Items!=null] | [?contains(Aliases.Items, '${domainName}')].Id" \
        --output text
    """
}

def build_message(state) {
  def branch = getBranch()
  "Build <${BUILD_URL}|${env.BUILD_NUMBER}> ${state} for ${branch}"
}

def notify(message, channel, color, update) {
  def branch = getBranch()
  if (update) {
    slackResponse = slackSend(channel: channel, message: message, color: color, timestamp: env.ts)
    return slackResponse
  } else {
    slackResponse = slackSend(channel: channel, message: message, color: color)
    return slackResponse
  }
}

def notify_success(message) {
  notify(message, env.thread, "good", false)
}

def notify_failure(message) {
  notify(message, env.thread, "danger", false)
}

def notify_start(message, channel) {
  notify(message, channel, "caution", false)
}

def notify_end(message, channel, color) {
  notify(message, channel, color, true)
}

pipeline {
    agent any
    environment {
        IMAGE_TAG  = GIT_COMMIT.take(7)
        SERVER_TAG = "${IMAGE_TAG}-Backend"
        JFROG_CREDENTIALS = credentials('jfrog')
        JFROG_NPMRC_FILE = credentials('jfrog_npmrc_corelending')
    }
    stages {
        stage('Precheck') {
            stages {
                stage('Get Environment Variables') {
                    steps {
                        script {
                            /*
                             * Read a JSON config file environmnts.json that has environment names as top-level keys.
                             * For keys for environments, use CMDB status names from:
                             *   https://your_org.atlassian.net/
                             *
                             * account: The target AWS account number
                             * domain_name: The domain name, used to construct:
                             * * the cross-account role name,
                             * * S3 bucket name, and
                             * * the CloudFront distribution
                             *
                             * Thanks Stack Overflow https://stackoverflow.com/a/63683524
                             * for the dynamic environment variable definition tip
                             */
                            def environments = getEnvironments()
                            def branch_targets = getBranchTargets(environments, getBranch())
                            def test_targets = getTestTargets(environments, getBranch())
                            env.DEPLOY = false
                            if (branch_targets.size() > 0) {
                              if( env.GIT_BRANCH.contains("PR-") ) {
                                env.deploy = false
                              }
                              else {
                                // Checking CHANGE_ID verifies we do not run deploys on an open PR
                                env.DEPLOY = env.CHANGE_ID ? false : true
                              }
                            }
                            if (test_targets.size() > 0) {
                                env.TEST = true
                            }
                            def sonarqube_target_env = "production"
                            env.IMAGE = environments.image
                            env.VIRTUAL_REGISTRY_REPO = environments.virtual_registry_repo
                            env.REGISTRY_REPO = environments.registry_url
                            env.REGISTRY_URL = "https://${env.REGISTRY_REPO}"
                            env.NAMESPACE = environments.namespace
                            env.SONARQUBE_ENV = environments.sonar_qube_config.target[sonarqube_target_env].environment
                            env.SONARQUBE_IMAGE = environments.sonar_qube_config.image
                            // env.SONARQUBE_PROJECT_BASE_DIR = environments.sonar_qube_config.project_base_dir
                            env.SONARQUBE_PROJ_KEY = environments.sonar_qube_config.project_key
                            env.SONARQUBE_PROJ_NAME = environments.sonar_qube_config.project_name
                            env.SONARQUBE_SOURCE = environments.sonar_qube_config.source
                            env.SONARQUBE_ENDPOINT = environments.sonar_qube_config.target[sonarqube_target_env].endpoint
                            env.SONARQUBE_TOKEN_NAME = environments.sonar_qube_config.target[sonarqube_target_env].token_name
                            def slackResponse = notify_start(build_message("STARTED"), "#credit-pricing-build-test-notifications")
                            env.thread  = slackResponse.threadId
                            env.channel = slackResponse.channelId
                            env.ts      = slackResponse.ts
                        }
                    }
                }
                stage ('Connect to Kubernetes') {
                    when { expression {env.DEPLOY} }
                        agent {
                            docker {
                                // Thanks https://stackoverflow.com/a/58691337 for the entrypoint trick
                                image "${env.REGISTRY_REPO}/${env.VIRTUAL_REGISTRY_REPO}/jshimko/kube-tools-aws:3.6.0"
                                args "-it --entrypoint="
                                registryUrl 'https://jfafn.jfrog.io/'
                                registryCredentialsId "jfrog"
                            }
                        }
                        steps {
                            script {

                            def environments = getEnvironments()
                            def branch_targets = getBranchTargets(environments, getBranch())
                            for(target in branch_targets) {
                                stage("Connect to ${target}"){
                                    env.ORIGIN_DOMAIN_NAME = environments.target[target].origin_domain_name.trim()
                                    // env.API_ORIGIN_DOMAIN_NAME = environments.target[target].api_origin_domain_name.trim()
                                    env.ACCOUNT = environments.target[target].account.trim()
                                    env.CLUSTER_NAME = environments.target[target].cluster_name.trim()
                                    env.DOMAIN = environments.target[target].domain_name.trim()
                                    env.API_DOMAIN = environments.target[target].api_domain_name.trim()
                                    env.SNS_TOPIC = environments.target[target].sns_topic.trim()
                                    env.SNS_TOPIC_ARN = environments.target[target].sns_topic_arn.trim()
                                    env.SNS_TOPIC_ARN_CURRENT_POLICY = environments.target[target].sns_topic_arn_current_policy.trim()
                                    env.SNS_TOPIC_ARN_TEST = environments.target[target].sns_topic_arn_test.trim()
                                    env.SQS_QUEUE_IN = environments.target[target].sqs_queue_in.trim()
                                    env.SQS_QUEUE_URL_IN = environments.target[target].sqs_queue_url_in.trim()
                                    env.SQS_QUEUE_OUT = environments.target[target].sqs_queue_out.trim()
                                    env.SQS_QUEUE_URL_OUT = environments.target[target].sqs_queue_url_out.trim()
                                    env.FULL_NAME_OVERRIDE = environments.target[target].full_name_override.trim()
                                    env.RELEASE_NAME = environments.image
                                        withAWS(role:"${env.ORIGIN_DOMAIN_NAME}",
                                                roleAccount:"${env.ACCOUNT}",
                                                duration: 900,
                                                roleSessionName: 'jenkins-session') {
                                            // Thanks Stack Overflow https://stackoverflow.com/a/35607134 for the query
                                            sh(script: getKubeconfigShell(env.CLUSTER_NAME),
                                               label: 'Use kubectl to get cluster information',
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        stage('Build') {
            parallel {
                stage('Server Docker Build') {
                    steps {
                        dir("${env.WORKSPACE}/server") {
                          sh '''
                            printf '{"GitBranch":"%s","GitCommit":"%s","BuildNo":"%s"}' \
                              "$GIT_BRANCH" \
                              "$GIT_COMMIT" \
                              "$BUILD_NUMBER" \
                              > version.json
                            '''
                          script {
                              writeFile file: '.npmrc', text: env.JFROG_NPMRC_FILE
                              login_to_registry()
                              def app = docker.build("$VIRTUAL_REGISTRY_REPO/$IMAGE:${env.SERVER_TAG}", "-f Dockerfile ..")
                              sh 'docker images'
                              docker.withRegistry(REGISTRY_URL)
                              {
                                  docker.image("$VIRTUAL_REGISTRY_REPO/$IMAGE:${env.SERVER_TAG}").push()
                              }
                          }
                        }
                    }
                }
                stage('Web UI') {
                  stages {
                    stage('Install dependencies') {
                      agent {
                        docker {
                            image "${env.REGISTRY_REPO}/${env.VIRTUAL_REGISTRY_REPO}/your_org/ionic-nodejs-14:2.0"
                            args "-v ${WORKSPACE}:/home/alpine/project -i --entrypoint="
                            registryCredentialsId "jfrog"
                            registryUrl env.REGISTRY_URL
                        }
                      }
                      steps {
                        dir("${env.WORKSPACE}/client") {
                          writeFile file: '.npmrc', text: env.JFROG_NPMRC_FILE
                          sh 'npm install --unsafe-perm'
                          stash includes: 'node_modules/**/*', name: 'node_modules'
                        }
                      }
                    }
                    stage('Sonar Scan - Web Client') {
                      agent {
                        docker {
                          image "${env.VIRTUAL_REGISTRY_REPO}/${env.SONARQUBE_IMAGE}"
                          registryCredentialsId 'jfrog'
                          registryUrl env.REGISTRY_URL
                        }
                      }
                      environment {
                        SONARQUBE_PROJ_KEY = "${environments.sonar_qube_config.project_key}:client"
                        SONARQUBE_PROJ_NAME = "${environments.sonar_qube_config.project_name}_client"
                        SONARQUBE_TOKEN = credentials("${env.SONARQUBE_TOKEN_NAME}")
                        SONARQUBE_PROJECT_BASE_DIR = "./client/"
                      }
                      steps {
                        withSonarQubeEnv("${env.SONARQUBE_ENV}") {
                          sh "DEBUG=false ${WORKSPACE}/bin/sonar-scanner.sh"
                        }
                      }
                      post {
                        success {
                          notify_success('UI Sonar Scan Success')
                        }
                        failure {
                          notify_failure('UI Sonar Scan Failed')
                        }
                      }
                    }
                    stage('Build - npm') {
                      agent {
                        docker {
                            image "${env.REGISTRY_REPO}/${env.VIRTUAL_REGISTRY_REPO}/your_org/ionic-nodejs-14:2.0"
                            args "-v ${WORKSPACE}:/home/alpine/project -i --entrypoint="
                            registryUrl 'https://jfafn.jfrog.io/'
                            registryCredentialsId "jfrog"
                        }
                      }
                      steps {
                        script{
                          def environments = getEnvironments()
                          def branch_targets = getBranchTargets(environments, getBranch())
                          for(target in branch_targets) {
                            dir("${env.WORKSPACE}/client") {
                              sh 'rm -rf node_modules'
                              unstash 'node_modules'
                              sh 'rm -rf src/Utils.js'
                              sh 'rm -rf src/env.json'
                              sh "cp ../client-envs/${target}.js src/Utils.js"
                              sh "cp ../client-envs/${target}.json src/env.json"
                              sh 'CI=false npm run build'
                              stash includes: 'build/**/*', name: "build-${target}"
                            }
                          }
                        }
                      }
                    }
                    stage('Test - Web') {
                      agent {
                        docker {
                            image "${env.REGISTRY_REPO}/${env.VIRTUAL_REGISTRY_REPO}/your_org/ionic-nodejs-14:2.0"
                            args "-v ${WORKSPACE}:/home/alpine/project -i --entrypoint="
                            registryUrl 'https://jfafn.jfrog.io/'
                            registryCredentialsId "jfrog"
                        }
                      }
                      steps {
                        dir("${env.WORKSPACE}/client") {
                          sh 'rm -rf node_modules'
                          unstash 'node_modules'
                          sh 'npm run ci-test'
                        }
                      }
                      post {
                        success {
                          notify_success('UI Test Success')
                        }
                        failure {
                          notify_failure('UI Test Failed')
                        }
                      }
                    }
                    stage('Deploy - Web') {
                      when { expression {env.DEPLOY} }
                      steps{
                        script{
                          echo 'Starting'
                            def environments = getEnvironments()
                            def branch_targets = getBranchTargets(environments, getBranch())
                            env.BUILD_DIR = environments.build_dir
                            timeout(time: 5, unit: 'MINUTES') {
                              lock(resource: env.DOMAIN_NAME,inversePrecedence: false) {
                                for(target in branch_targets) {
                                  unstash "build-${target}"
                                  stage("Deployment to ${target}") {
                                    env.ACCOUNT = environments.target[target].account.trim()
                                    env.DOMAIN_NAME = environments.target[target].domain_name.trim()
                                    withAWS(role: env.DOMAIN_NAME,
                                      roleAccount: env.ACCOUNT,
                                      duration: 900,
                                      roleSessionName: 'jenkins-session') {
                                      env.CF_DISTRIBUTION = sh(script: getCloudFrontDistribution(env.DOMAIN_NAME),
                                        label: 'Use AWS CLI to get Cloudfront distribution',
                                        returnStdout: true,
                                        ).trim()
                                      s3Upload bucket: env.DOMAIN_NAME,
                                        file: "${env.BUILD_DIR}/"
                                      cfInvalidate distribution: env.CF_DISTRIBUTION,
                                        paths: ['/*']
                                    }
                                  }
                                }
                              }
                            }
                          echo 'Finish'
                        }
                      }
                      post {
                        success {
                          notify_success('UI Deploy Success')
                        }
                        failure {
                          notify_failure('UI Deploy Failed')
                        }
                      }
                    }
                  }
                }
                stage ('Run git-secrets') {
                  agent {
                    docker {
                      image "${env.REGISTRY_REPO}/${env.VIRTUAL_REGISTRY_REPO}/your_org/alpine-git-secrets:1.1"
                      args "-it -entrypoint="
                      registryUrl 'https://jfafn.jfrog.io/'
                      registryCredentialsId "jfrog"
                    }
                  }
                  steps {
                    sh '''
                      git secrets --install -f
                      git secrets --register-aws
                      git secrets --scan
                    '''
                  }
                }
                stage('Sonar Scan - Backend API') {
                  agent {
                    docker {
                      image "${env.VIRTUAL_REGISTRY_REPO}/${env.SONARQUBE_IMAGE}"
                      registryCredentialsId 'jfrog'
                      registryUrl env.REGISTRY_URL
                    }
                  }
                  environment {
                    SONARQUBE_PROJ_KEY = "${environments.sonar_qube_config.project_key}:server"
                    SONARQUBE_PROJ_NAME = "${environments.sonar_qube_config.project_name}_server"
                    SONARQUBE_TOKEN = credentials("${env.SONARQUBE_TOKEN_NAME}")
                    SONARQUBE_PROJECT_BASE_DIR = "./server/"
                  }
                  steps {
                    withSonarQubeEnv("${env.SONARQUBE_ENV}") {
                      sh "DEBUG=false ${WORKSPACE}/bin/sonar-scanner.sh"
                    }
                  }
                  post {
                    success {
                      notify_success("Backend sonar scan passed")
                    }
                    failure {
                      notify_failure("Backend sonar scan failed")
                    }
                  }
                }
            }
        }
        stage('Backend Services Tests') {
          when { not { expression {env.DEPLOY} } }
          steps {
            script {
              catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                def environments = getEnvironments()
                def branch_targets = getBranchTargets(environments, getBranch())
                env.ACCOUNT = environments.target['sandbox'].account.trim()
                env.ORIGIN_DOMAIN_NAME = environments.target['sandbox'].origin_domain_name.trim()
                login_to_registry()
                docker.withRegistry(REGISTRY_URL)
                {
                  docker.image("$VIRTUAL_REGISTRY_REPO/$IMAGE:${env.SERVER_TAG}").inside("-u root -v ${WORKSPACE}:/usr/src/app/reports") {
                    withAWS(role:"${env.ORIGIN_DOMAIN_NAME}_tester",
                                        roleAccount:"${env.ACCOUNT}",
                                        duration: 900,
                                        roleSessionName: 'jenkins-session-test') {
                      // Thanks https://stackoverflow.com/a/60878112
                      sh '''
                        cd /usr/src/app
                        npm run jest-ci
                        '''
                    }
                  }
                }
              }
            }
          }
          post {
            always {
              publishHTML target: [
                allowMissing         : false,
                alwaysLinkToLastBuild: false,
                keepAll              : true,
                reportDir            : "${WORKSPACE}/jest",
                reportFiles          : 'UnitTests.html',
                reportName           : 'Test Report'
              ]
            }
            success {
              notify_success("Backend services tests passed.  <${BUILD_URL}/Test_20Report|Test report>")
            }
            failure {
              notify_failure("Backend services tests failed.  <${BUILD_URL}/Test_20Report|Test report>")
            }
          }
        }
        stage ('Dependency Audit') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        login_to_registry()
                        docker.withRegistry(REGISTRY_URL){
                          for(tag in [env.SERVER_TAG]) {
                            // Thanks https://stackoverflow.com/a/60878112
                            docker.image("$VIRTUAL_REGISTRY_REPO/$IMAGE:${tag}").inside {
                                sh '''
                                    cd /usr/src/app
                                    npm audit
                                  '''
                            }
                          }
                        }
                    }
                }
            }
            post {
              success {
                notify_success("Backend services dependency audit passed.")
              }
              failure {
                notify_failure("Backend services dependency audit failed.")
              }
            }
        }
        stage('Deploy - Backend') {
            when { expression {env.DEPLOY} }
            agent {
                docker {
                    // Thanks https://stackoverflow.com/a/58691337 for the entrypoint trick
                    image "${env.REGISTRY_REPO}/${env.VIRTUAL_REGISTRY_REPO}/jshimko/kube-tools-aws:3.8.1"
                    args "-it --entrypoint="
                    registryUrl 'https://jfafn.jfrog.io/'
                    registryCredentialsId "jfrog"
                }
            }
            steps {
                script {

                    def environments = getEnvironments()
                    def branch_targets = getBranchTargets(environments, getBranch())
                    for(target in branch_targets) {
                        stage("Deploy ${target}"){
                            // env.DOMAIN_NAME = environments.target[target].domain_name.trim()
                            // env.API_DOMAIN_NAME = environments.target[target].api_domain_name.trim()
                            env.SERVICE_ACCOUNT_NAME = environments.target[target].service_account_name.trim()
                            // env.ORIGIN_DOMAIN_NAME = environments.target[target].origin_domain_name.trim()
                            // env.REPLICA_COUNT = environments.target[target].replica_count.trim()
                            // env.API_ORIGIN_DOMAIN_NAME = environments.target[target].api_origin_domain_name.trim()
                            // env.CLUSTER_NAME = environments.target[target].cluster_name.trim()
                            // env.ACCOUNT = environments.target[target].account.trim()
                            withAWS(role:"${env.ORIGIN_DOMAIN_NAME}",
                                    roleAccount:"${env.ACCOUNT}",
                                    duration: 900,
                                    roleSessionName: 'jenkins-session') {
                                // Thanks Stack Overflow https://stackoverflow.com/a/35607134 for the query
                                def kubeConfigShell = getKubeconfigShell(env.CLUSTER_NAME)
                                dir("${env.WORKSPACE}/helm") {
                                  sh(script: """
                                              ${kubeConfigShell}
                                              # Thanks https://github.com/helm/helm/issues/8194#issuecomment-671312246
                                              PKG=\$(
                                                  helm package \
                                                  --app-version=${env.SERVER_TAG} \
                                                  server \
                                                  | awk '{print \$8}'
                                              )
                                              helm upgrade \
                                                  --install \
                                                  --atomic \
                                                  --wait \
                                                  --namespace ${env.NAMESPACE} \
                                                  --set domain=${env.DOMAIN} \
                                                  --set apiDomain=${env.API_DOMAIN} \
                                                  --set serviceAccount.name=${env.SERVICE_ACCOUNT_NAME} \
                                                  --set image.registry=${env.REGISTRY_REPO} \
                                                  --set image.tag=${env.SERVER_TAG} \
                                                  --set image.repository=${env.VIRTUAL_REGISTRY_REPO}/${env.IMAGE} \
                                                  --set snsTopic=${env.SNS_TOPIC} \
                                                  --set snsTopicArn=${env.SNS_TOPIC_ARN} \
                                                  --set snsTopicArnCurrentPolicy=${env.SNS_TOPIC_ARN_CURRENT_POLICY} \
                                                  --set snsTopicArnTest=${env.SNS_TOPIC_ARN_TEST} \
                                                  --set sqsQueueIn=${env.SQS_QUEUE_IN} \
                                                  --set sqsQueueUrlIn=${env.SQS_QUEUE_URL_IN} \
                                                  --set sqsQueueOut=${env.SQS_QUEUE_OUT} \
                                                  --set sqsQueueUrlOut=${env.SQS_QUEUE_URL_OUT} \
                                                  --set nodeEnv=${target} \
                                                  --set environment=${target} \
                                                  ${env.FULL_NAME_OVERRIDE} \
                                                  "\$PKG"
                                              helm history \
                                                  --namespace ${env.NAMESPACE} \
                                                  ${env.FULL_NAME_OVERRIDE}
                                              """,
                                          label: 'Deploy application with helm',
                                  )
                                }
                            }
                        }
                    }
                }
            }
            post {
              success {
                notify_success("Backend deploy success")
              }
              failure {
                notify_failure("Backend deploy failed")
              }
            }
        }
    }
    post {
      success {
        notify_end(build_message("SUCCESS"), env.channel, "good")
      }
      failure {
        notify_end(build_message("FAILURE"), env.channel, "danger")
      }
    }
}
