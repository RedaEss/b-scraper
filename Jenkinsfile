// Jenkinsfile - Pipeline pour le scraper Basta Media
// SOURCES DES VARIABLES D'ENVIRONNEMENT :
// 1. Variables personnalisées (définies dans environment {})
// 2. Variables Jenkins prédéfinies (automatiques)
// 3. Variables système (OS/configuration Jenkins)

// NOUVEAU : Paramètres utilisateur pour choisir la branche à builder
// Cela permet de builder manuellement différentes branches sans changer la configuration Jenkins

pipeline {
    // Agent = environnement d'exécution
    agent {
        docker {
            image 'docker:latest'  // Utilise l'image Docker officielle
            args '-v /var/run/docker.sock:/var/run/docker.sock'  // Docker-in-Docker: permet d'exécuter des commandes Docker
        }
    }
    
    // Options globales du pipeline
    options {
        timeout(time: 30, unit: 'MINUTES')  // Tue le build après 30min (évite les builds infinis)
        buildDiscarder(logRotator(numToKeepStr: '10'))  // Garde seulement les 10 derniers builds
        disableConcurrentBuilds()  // Empêche 2 builds en même temps
    }
    
    // NOUVEAU : Paramètres utilisateur - apparaît quand on clique "Build with Parameters"
    parameters {
        choice(
            name: 'BRANCH',
            choices: ['development', 'main'],
            description: 'Branche à builder',
           // defaultValue: 'development'  // Valeur par défaut pour les builds manuels
        )
    }
    
    // Déclencheurs automatiques
    triggers {
        pollSCM('H/15 * * * *')  // Vérifie Git toutes les 15min (pour les builds automatiques)
    }
    
    // Variables d'environnement (équivalent aux variables dans l'interface Jenkins)
    environment {
        DOCKER_IMAGE = 'basta-scraper-r'  // Nom de l'image Docker - Remplace "docker build -t basta-scraper-r ."
        RESULTS_DIR = 'jenkins-results'   // Dossier des résultats - Remplace "mkdir -p jenkins-results"
        DOCKER_BUILDKIT = '1'             // Active BuildKit pour des builds plus rapides
    }
    
    // Étapes du pipeline 
    stages {
        // ÉTAPE 1: Récupération du code et setup
        // Remplace la section "Source Code Management" de l'interface Jenkins
        stage('Checkout & Setup') {
            steps {
                checkout scm  // Récupère automatiquement le code depuis Git (comme config SCM dans l'interface jenkins) 'scm' est une variable Jenkins automatique = configuration Git du job
                
                // NOUVEAU : Logique de changement de branche si paramètre différent de 'development'
                script {
                    // Si l'utilisateur a choisi une branche différente de 'development' via les paramètres
                    if (params.BRANCH != 'development') {
                        sh "git checkout ${params.BRANCH}"  // Change vers la branche sélectionnée
                        echo "✅ Branche changée vers: ${params.BRANCH}"
                    } else {
                        echo "✅ Utilisation de la branche development (défaut)"
                    }
                }
                
                sh 'apk add --no-cache docker-compose'  // Installe docker-compose (pour éventuelle évolution)

                // AFFICHAGE DES VARIABLES POUR DÉBOGAGE 
                sh '''
                    echo "=== VARIABLES DISPONIBLES ==="
                    echo "DOCKER_IMAGE: ${DOCKER_IMAGE}"
                    echo "RESULTS_DIR: ${RESULTS_DIR}" 
                    echo "JOB_NAME: ${JOB_NAME}"
                    echo "BUILD_URL: ${BUILD_URL}"
                    echo "WORKSPACE: ${WORKSPACE}"
                    echo "BRANCH_PARAM: ${BRANCH}"  // NOUVEAU : Affiche la branche choisie
                '''
            }
        }
        
        // ÉTAPE 2: Construction de l'image Docker
        // Remplace l'étape "Execute shell" avec "docker build -t simple-web-scraper ."
        stage('Build Image') {
            steps {
                sh """
                    docker build \\
                    --build-arg BUILDKIT_INLINE_CACHE=1 \\  # Optimisation du cache
                    -t ${env.DOCKER_IMAGE} .  # Même commande que l'interface - freestyle project - mais avec variable
                """
            }
        }
        
        // ÉTAPE 3: Exécution du scraper
        // Remplace étape "Execute shell" avec "docker run simple-web-scraper"
        // Mais amélioré avec le montage de volume pour récupérer les fichiers
        stage('Run Scraper') {
            steps {
                sh """
                    mkdir -p ${env.RESULTS_DIR}  # Crée le dossier de résultats (comme dans freestyle)
                    docker run --rm \\  # Exécute et supprime le conteneur après
                      -v \$(pwd)/${env.RESULTS_DIR}:/results \\  # Monte le dossier résultats
                      ${env.DOCKER_IMAGE}  # Même image que celle buildée
                """
            }
        }
        
        // ÉTAPE 4: Validation des résultats - NOUVELLE ÉTAPE (pas dans le freestyle)
        // Vérifie que le scraping a bien fonctionné
        stage('Validate Results') {
            steps {
                script {
                    // Vérifie qu'au moins un fichier CSV a été généré
                    def files = findFiles(glob: "${env.RESULTS_DIR}/*.csv")
                    if (files.length == 0) {
                        error "Aucun fichier CSV généré"  // Échoue le build si pas de CSV
                    }
                    
                    // Lit le fichier CSV pour vérifier son contenu
                    def csvFile = readFile files[0].path
                    def lines = csvFile.readLines().size()
                    echo "📈 Fichier CSV: ${lines} lignes"  // Log le nombre de lignes
                    
                    // Vérifie qu'il y a au moins l'en-tête + 1 ligne de données
                    if (lines < 2) {
                        error "Fichier CSV vide ou incomplet"  // Échoue si pas de données
                    }
                    
                    // NOUVEAU : Mention de la branche dans les logs de validation
                    echo "✅ Validation réussie - Branche: ${params.BRANCH}"
                }
            }
        }
    }
    
    // Actions exécutées après les stages (succès ou échec)
    post {
        // TOUJOURS exécuté (succès ou échec)
        always {
            // Archive les artefacts - Même configuration que "Archive the artifacts" dans freestyle
            archiveArtifacts artifacts: "${env.RESULTS_DIR}/*", fingerprint: true
            
            // Nettoyage Docker - Équivalent à votre nettoyage manuel
            sh 'docker system prune -f'
            
            // Publie les résultats HTML/JSON (pour consultation dans Jenkins)
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: env.RESULTS_DIR,
                reportFiles: '*.html,*.json',
                reportName: 'Rapports Scraping'
            ])
        }
        
        // Seulement en cas de SUCCÈS
        success {
            // NOUVEAU : Inclut la branche dans le message de succès
            echo "✅ Pipeline exécuté avec succès ! - Branche: ${params.BRANCH}"
            
            // SECTION SLACK COMMENTÉE - POUR USAGE FUTUR
            // Décommentez ces lignes quand vous configurerez Slack
            /*
            slackSend(
                channel: '#jenkins',
                message: "✅ ${env.JOB_NAME} - SUCCÈS - Branche: ${params.BRANCH}\n${env.BUILD_URL}"
            )
            */
        }
        
        // Seulement en cas d'ÉCHEC
        failure {
            // NOUVEAU : Inclut la branche dans le message d'échec
            echo "❌ Pipeline a échoué - Branche: ${params.BRANCH}"
            
            // SECTION SLACK COMMENTÉE - POUR USAGE FUTUR
            // Décommentez ces lignes quand vous configurerez Slack
            /*
            slackSend(
                channel: '#jenkins',
                message: "❌ ${env.JOB_NAME} - ÉCHEC - Branche: ${params.BRANCH}\n${env.BUILD_URL}"
            )
            */
        }
    }
}