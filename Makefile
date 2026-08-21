.PHONY: test
test:
	python3 -m pytest tests/ -v
	@fail=0; for f in tests/shell/test_*.sh; do bash "$$f" || fail=1; done; exit $$fail

.PHONY: test-py
test-py:
	python3 -m pytest tests/ -v

.PHONY: test-shell
test-shell:
	@fail=0; for f in tests/shell/test_*.sh; do bash "$$f" || fail=1; done; exit $$fail
