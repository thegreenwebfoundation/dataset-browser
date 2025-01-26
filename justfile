# MINIO_ALIAS and BUCKET_NAME are assumed to be environment variables

set dotenv-load

# list all the available commands
default:
  just --list

latest_key := `mcli --json ls ${MINIO_ALIAS}/tgwf-green-domains-live/ | jq -s '.[-1].key'`

print_latest_key:
    echo {{latest_key}}

serve: daily_snapshot
	uv run datasette . -h 0.0.0.0

serve_no_snapshot:
	uv run datasette . -h 0.0.0.0

test:
	uv run pytest

test_dev:
	# run pytest on every file to files matching .py
	find . -name '*.py' | entr pytest

daily_snapshot: downloaded_snapshot
	gunzip ./daily_snapshot.db.gz

downloaded_snapshot: cleared_snapshot
	echo "Downloading database snapshot from ${MINIO_ALIAS}/${BUCKET_NAME}/{{ latest_key }}"
	# copy the file to the local filesystem
	mcli cp ${MINIO_ALIAS}/${BUCKET_NAME}/{{ latest_key }} daily_snapshot.db.gz

cleared_snapshot:
	rm -rf ./*.db

release:
	uv run ansible-playbook ansible/deploy.yml -i ansible/inventories/prod.yml

release_check:
	uv run ansible-playbook ansible/deploy.yml -i ansible/inventories/prod.yml --check
