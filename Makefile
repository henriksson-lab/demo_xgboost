docker:
	docker build -t demo_xgboost .
docker_testrun:
	docker run --rm -p 3838:3838 demo_xgboost
