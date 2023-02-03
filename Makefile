build:
	eval $(minikube docker-env)
	docker build -t dj-app-3 ./backend_main_django

deploy-db:
	kubectl apply -f ./k8s/dj_app_postgres_config.yml
	kubectl apply -f ./k8s/dj_app_postgres_volume.yml
	kubectl apply -f ./k8s/dj_app_postgres_volume_claim.yml
	kubectl apply -f ./k8s/dj_app_postgres_deployment.yml

deploy-app:
	kubectl apply -f ./k8s/dj_app_config.yml
	kubectl apply -f ./k8s/dj_app_service.yml
	kubectl apply -f ./k8s/dj_app_deployment.yml
	kubectl apply -f ./k8s/dj_app_migrate_job.yml
	kubectl apply -f ./k8s/dj_app_clear_sessions_job.yml
	kubectl apply -f ./k8s/dj_app_ingress.yml

migrate:
	kubectl apply -f ./k8s/dj_app_migrate_job.yml

clear-sessions:
	kubectl create job --from=cronjob/dj-app-clear-sessions clear-sessions