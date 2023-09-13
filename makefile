# MINIO_ALIAS and BUCKET_NAME is assumed to be an environment variable


latest_key := $(shell mcli --json ls ${MINIO_ALIAS}/tgwf-green-domains-live/ | jq -s '.[-1].key')

serve: daily_snapshot.db 
	datasette ./daily_snapshot.db --template-dir=templates --static static:static --setting sql_time_limit_ms 10000 -h 0.0.0.0

test.dev:
  	# run pytest on every file to files matching .py
	find . -name '*.py' | entr pytest

daily_snapshot.db: downloaded_snapshot
	gunzip ./daily_snapshot.db.gz

downloaded_snapshot: cleared_snapshot
	echo "Downloading database snapshot from ${MINIO_ALIAS}/${BUCKET_NAME}/${latest_key}"

	# copy the file to the local filesystem
	mcli cp $(MINIO_ALIAS)/${BUCKET_NAME}/${latest_key} daily_snapshot.db.gz

cleared_snapshot:
	rm -rf ./*.db

release:
	ansible-playbook ansible/deploy.yml -i ansible/inventories/prod.yml

release.check:
	ansible-playbook ansible/deploy.yml -i ansible/inventories/prod.yml --check
