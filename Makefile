.PHONY: test
test:
	python3 -m pytest tests/ -v
	bash tests/shell/test_*.sh

.PHONY: test-py
test-py:
	python3 -m pytest tests/ -v

.PHONY: test-shell
test-shell:
	bash tests/shell/test_*.sh
