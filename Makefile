NAME		:= inception
COMPOSE		:= docker compose -f srcs/docker-compose.yml
USER		:= $(shell whoami)
DATA_DIR	:= /home/$(USER)/data
DB_DIR		:= $(DATA_DIR)/mariadb
WP_DIR		:= $(DATA_DIR)/wordpress

.PHONY: all up down build re clean fclean ps logs dirs

all: up

dirs:
	@mkdir -p $(DB_DIR) $(WP_DIR)

up: dirs
	@$(COMPOSE) up -d --build

down:
	@$(COMPOSE) down

build:
	@$(COMPOSE) build

ps:
	@$(COMPOSE) ps

logs:
	@$(COMPOSE) logs -f

clean: down
	@docker image prune -f >/dev/null 2>&1 || true

fclean: down
	@$(COMPOSE) down -v
	@docker image prune -af >/dev/null/ 2>&1 || true
	@docker volume prune -f >/dev/null/ 2>&1 || true

re: fclean up
