
serve:
	datasette ./daily_snapshot.db --template-dir=templates --static static:static

test.dev:
  # run pytest on every file to files matching .py
	find . -name '*.py' | entr pytest
