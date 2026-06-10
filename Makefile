.PHONY: help up rebuild down logs bash run test coverage lint seed setup fresh credentials

help:
	@echo "Geolocation API (Docker only)"
	@echo ""
	@echo "  make up           start API + PostgreSQL"
	@echo "  make credentials  print a new client_secret (if you lost it)"
	@echo "  make bash         shell in web container"
	@echo "  make test         run rspec"
	@echo "  make coverage     run rspec with SimpleCov"
	@echo "  make lint         run rubocop"
	@echo "  make fresh        reset DB and rebuild"

up:
	docker compose up --build -d

rebuild: up

down:
	docker compose down

fresh:
	docker compose down -v
	docker compose up --build -d

logs:
	docker compose logs -f web

bash:
	bin/bash

run:
	bin/run $(CMD)

test:
	bin/rspec

coverage:
	bin/coverage

lint:
	bin/rubocop

seed:
	bin/run bundle exec rake db:seed

setup:
	bin/setup

credentials:
	bin/run bundle exec rake auth:reset_credentials
