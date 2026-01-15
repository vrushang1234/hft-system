formatter:
	docker build -f Dockerfile.format -t hft-formatter .

format: formatter
	docker run --rm -v $(shell pwd):/repo -w /repo hft-formatter run format:ui
	docker run --rm -v $(shell pwd):/repo -w /repo hft-formatter run format:rl

