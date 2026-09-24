pipeline {
    agent any

    options {
        // Хранить только последние 10 сборок, чтобы не переполнять диск
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Прервать сборку, если она идёт дольше 15 минут
        timeout(time: 15, unit: 'MINUTES')
        // Запретить одновременный запуск нескольких сборок этого конвейера
        disableConcurrentBuilds()
    }

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['staging', 'production'],
            description: 'Окружение, в которое выполняется развёртывание'
        )
        booleanParam(
            name: 'RUN_TESTS',
            defaultValue: true,
            description: 'Запускать этап тестирования'
        )
    }

    environment {
        APP_NAME  = 'devops-ci-demo'
        BUILD_DIR = 'dist'
        REPORTS   = 'reports'
    }

    stages {

        stage('Подготовка') {
            steps {
                echo "=== Подготовка окружения сборки ==="
                echo "Приложение:      ${env.APP_NAME}"
                echo "Номер сборки:    ${env.BUILD_NUMBER}"
                echo "Ветка:           ${env.GIT_BRANCH}"
                echo "Окружение:       ${params.DEPLOY_ENV}"
                sh 'chmod +x scripts/*.sh'
                sh 'rm -rf dist reports deploy'
                sh 'mkdir -p reports'
            }
        }

        stage('Сборка') {
            steps {
                echo "=== Сборка приложения ==="
                sh './scripts/build.sh'
            }
        }

        stage('Тестирование') {
            when {
                expression { return params.RUN_TESTS }
            }
            steps {
                echo "=== Тестирование собранного артефакта ==="
                sh './scripts/test.sh'
            }
        }

        stage('Статический анализ') {
            steps {
                echo "=== Проверка исходного кода ==="
                sh './scripts/analyze.sh'
            }
        }

        stage('Упаковка') {
            steps {
                echo "=== Упаковка дистрибутива ==="
                sh '''
                    VERSION=$(cat VERSION)
                    tar -czf ${APP_NAME}-${VERSION}-build${BUILD_NUMBER}.tar.gz dist
                    ls -lh ${APP_NAME}-${VERSION}-build${BUILD_NUMBER}.tar.gz
                '''
                archiveArtifacts artifacts: '*.tar.gz, reports/*', fingerprint: true
            }
        }

        stage('Развёртывание') {
            steps {
                echo "=== Развёртывание в окружение ${params.DEPLOY_ENV} ==="
                sh "./scripts/deploy.sh ${params.DEPLOY_ENV}"
            }
        }
    }

    post {
        always {
            echo "Сборка #${env.BUILD_NUMBER} завершена со статусом: ${currentBuild.currentResult}"
            // deleteDir() из плагина Workflow Basic Steps очищает рабочую область.
            // Выполняется после archiveArtifacts, поэтому артефакты не теряются.
            deleteDir()
        }
        success {
            echo "Конвейер выполнен успешно. Версия развёрнута в окружении ${params.DEPLOY_ENV}."
        }
        failure {
            echo "Конвейер завершился с ошибкой. Развёртывание не выполнялось."
        }
        unstable {
            echo "Конвейер завершён с предупреждениями: часть проверок не пройдена."
        }
    }
}
