# hft-system/math/Makefile

.PHONY: all tanh softmax evaluate clean

evaluate:
	python3 evaluate.py

test-tanh:
	$(MAKE) -C tanh

test-softmax:
	$(MAKE) -C softmax

clean-tanh:
	$(MAKE) -C tanh clean || true

clean-softmax:
	$(MAKE) -C softmax clean || true
