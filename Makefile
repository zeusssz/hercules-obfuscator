.PHONY: test

test:
	docker build --no-cache -f Dockerfile.test -t hercules-obfuscator:test .
	docker run --rm --name hercules-obfuscator-tests hercules-obfuscator:test
	docker rmi -f hercules-obfuscator:test
