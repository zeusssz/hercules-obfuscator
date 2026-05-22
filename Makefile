.PHONY: test-comprehensive

test-comprehensive:
	docker build --no-cache -f Dockerfile.test -t hercules-obfuscator:test .
	docker run --rm --name hercules-obfuscator-comprehensive hercules-obfuscator:test
	docker rmi -f hercules-obfuscator:test
