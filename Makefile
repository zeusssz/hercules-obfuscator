.PHONY: test examples examples-serve

EXAMPLES_PORT ?= 8080
TEST_BASE_IMAGE ?= serpensin/hercules-obfuscator-test-base:latest
TEST_IMAGE ?= hercules-obfuscator:test
TEST_PLATFORM ?= linux/amd64

test:
	docker image inspect $(TEST_BASE_IMAGE) >/dev/null 2>&1 || \
		docker pull --platform $(TEST_PLATFORM) $(TEST_BASE_IMAGE) || \
		docker build --platform $(TEST_PLATFORM) -f Dockerfile.test-base -t $(TEST_BASE_IMAGE) .
	docker build --platform $(TEST_PLATFORM) -f Dockerfile.test --build-arg TEST_BASE_IMAGE=$(TEST_BASE_IMAGE) --build-arg TEST_UPDATE_CACHE_BUST=$$(date +%s) -t $(TEST_IMAGE) .
	docker run --rm --name hercules-obfuscator-tests $(TEST_IMAGE)
	docker rmi -f $(TEST_IMAGE)

examples:
	python3 tools/generate_examples.py

examples-serve:
	@port=$(EXAMPLES_PORT); \
	while true; do \
		python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1', $$port)); s.close()" 2>/dev/null \
			&& break; \
		echo "Port $$port is in use, trying $$((port+1))..." >&2; \
		port=$$((port+1)); \
	done; \
	echo "Serving at http://127.0.0.1:$$port/"; \
	python3 -m http.server "$$port" --bind 127.0.0.1 --directory examples/generated/site
