DOCKER_COMPOSE_FILE = ./srcs/docker-compose.yml

all: build run
build:
	mkdir -p /home/abausa-v/data/mariadb
	mkdir -p /home/abausa-v/data/wordpress
	docker compose  -f $(DOCKER_COMPOSE_FILE) up --build -d
run:
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d
down:
	docker compose -f $(DOCKER_COMPOSE_FILE) down
clean:
	docker compose -f $(DOCKER_COMPOSE_FILE) down -v

fclean: clean
	docker system prune -a -f
	sudo rm -rf /home/abausa-v/data/mariadb
	sudo rm -rf /home/abausa-v/data/wordpress

re: down fclean build run
