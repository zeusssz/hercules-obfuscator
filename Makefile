.PHONY: test

TEST_BASE_IMAGE ?= serpensin/hercules-obfuscator-test-base:latest
TEST_IMAGE ?= hercules-obfuscator:test

test:
	docker image inspect $(TEST_BASE_IMAGE) >/dev/null 2>&1 || \
		docker pull $(TEST_BASE_IMAGE) || \
		docker build -f Dockerfile.test-base -t $(TEST_BASE_IMAGE) .
	docker build -f Dockerfile.test --build-arg TEST_BASE_IMAGE=$(TEST_BASE_IMAGE) --build-arg TEST_UPDATE_CACHE_BUST=$$(date +%s) -t $(TEST_IMAGE) .
	docker run --rm --name hercules-obfuscator-tests $(TEST_IMAGE)
	docker rmi -f $(TEST_IMAGE)
