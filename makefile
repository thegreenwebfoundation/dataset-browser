
serve: daily_snapshot.db
	datasette ./daily_snapshot.db --template-dir=templates --static static:static

test.dev:
  # run pytest on every file to files matching .py
	find . -name '*.py' | entr pytest

SNAPSHOT_FILENAME := $(shell aws s3 ls s3://$(BUCKET_NAME) | cut -d " " -f 6   | tail -n 1)

daily_snapshot.db: downloaded_snapshot
	gunzip ./daily_snapshot.db.gz

downloaded_snapshot: cleared_snapshot
	@echo FILENAME $(SNAPSHOT_FILENAME)
	aws s3 cp s3://$(BUCKET_NAME)/$(SNAPSHOT_FILENAME) daily_snapshot.db.gz

cleared_snapshot:
	rm -rf ./*.db

release:
	ansible-playbook ansible/deploy.yml -i ansible/inventories/prod

release.check:
	ansible-playbook ansible/deploy.yml -i ansible/inventories/prod --check
