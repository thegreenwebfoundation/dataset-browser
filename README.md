# The Green Web Foundation Dataset Browser

Source code for the Green Web Foundation dataset browser, live at
[datasets.thegreenwebfoundation.org](https://datasets.thegreenwebfoundation.org)
(also reachable as [datasets.greenweb.org](https://datasets.greenweb.org)).

This is a lightly modified deployment of the [fantastic Datasette project](https://datasette.io),
led by [Simon Willison](https://simonwillison.net). If you have data you are interested in
publishing, it's a fantastic tool.

## The datasets

The browser serves two datasets, each as a SQLite database in the project root:

- **Green domains** (`daily_snapshot.db`, table `greendomain`) — the domain names tracked in the
  Green Web Foundation database that have shown up as "green" in the twelve months before the
  snapshot was taken, along with who hosts them and when they were last checked. The latest
  snapshot is downloaded from the foundation's object storage on each refresh. The
  [about page](https://datasets.thegreenwebfoundation.org/about) documents each column.
- **Real time cloud metadata** (`cloud_regions.db`, table `cloud_regions_metadata`) — the key
  dataset produced by the
  [Green Software Foundation Real Time Cloud working group](https://github.com/Green-Software-Foundation/real-time-cloud/),
  republished here in a form that can be easily queried, linked to, and downloaded. The
  [column specification](https://github.com/Green-Software-Foundation/real-time-cloud/blob/main/Cloud_Region_Metadata_specification.md)
  explains what each column means and how it was created.

## Prerequisites

- [uv](https://docs.astral.sh/uv/) — manages the Python version and dependencies (`uv sync` does the rest)
- [just](https://just.systems) — runs the task recipes used throughout this README
- `wget` and `jq` — used by the data-fetch recipes
- Only to refresh the green domains snapshot locally: the
  [MinIO client (`mcli`)](https://min.io/docs/minio/linux/reference/minio-mc.html), with an alias
  configured that has read access to the foundation's object storage

If you prefer not to use uv, a plain virtualenv works too:

```
python -m venv .venv
.venv/bin/pip install -e .
```

## Running locally

First set up your environment file:

```
cp .env.sample .env   # then edit — see the notes in that file
```

Then:

```
just serve
```

⚠️ `just serve` first **deletes every local `.db` and `.csv` file**, then:

1. downloads the latest green domains snapshot (~175 MB) from object storage — this needs `mcli`
   with a working alias, plus `MINIO_ALIAS` and `BUCKET_NAME` set in `.env`
2. fetches the latest real time cloud CSV and rebuilds `cloud_regions.db` (no credentials needed)
3. starts the Datasette server on `0.0.0.0:8001`

### Without object storage credentials

You can browse the real time cloud dataset with no credentials at all:

```
just real_time_cloud_csvs real_time_cloud_db
just serve_no_snapshot   # skip the download, serve whatever .db files are already present
```

If you have been given a copy of `daily_snapshot.db`, drop it in the project root and it will be
served as well.

A note on freshness: `real_time_cloud_db` deliberately takes its CSV from the **Dev branch** of the
[real-time-cloud repo](https://github.com/Green-Software-Foundation/real-time-cloud) rather than a
ratified release — there is a noticeable delay between data being updated and the GSF steering
council ratifying a release, and the Dev branch is where the latest data lands first. The recipe
is safe to re-run: it clears `cloud_regions.db` first, because `sqlite-utils insert` would
otherwise append duplicate rows.

### Tests

```
just test        # run once
just test_dev    # re-run pytest whenever a .py file changes (uses entr)
```

### Recipe reference

| Recipe | What it does |
| --- | --- |
| `serve` | clear all local data, download the latest snapshots, start the server |
| `serve_no_snapshot` | start the server against whatever `.db` files are already present |
| `real_time_cloud_csvs` | fetch the latest real time cloud CSV from the GSF repo (Dev branch) |
| `real_time_cloud_db` | rebuild `cloud_regions.db` from that CSV (clears it first) |
| `daily_snapshot` | clear and download the latest green domains snapshot (needs `mcli`) |
| `all_dataset_dbs` | both refreshes in one go — what production runs nightly |
| `print_latest_key` | print the object storage key of the latest green domains snapshot |
| `test` / `test_dev` | run pytest |
| `release` | run the ansible deploy playbook against production (see below) |

## How this is built and customised from Datasette

At its core this is stock Datasette: `datasette .` serves every `*.db` file in the project root,
with `settings.json` raising the SQL time limit to 30 seconds. The customisations are:

- **Templates** — `templates/index.html`, `database.html`, and `table.html` override Datasette's
  built-in templates by extending their `default:*` equivalents and adding Green Web Foundation
  branding and copy. `templates/partials/nav_menu.html` holds the shared navigation, and
  `templates/pages/about.html` is a custom page carrying the data dictionary for the green domains
  dataset.
- **CSS** — `static/css/overrides.css`, linked from each custom template.
- **Python code** — the `tgwf_datasette` package is the home for custom Python code. Datasette
  picks up anything in `plugins/` automatically as plugins (currently empty). The package
  currently only carries a version string.
- **No metadata file** — database and column descriptions live in the templates rather than a
  Datasette `metadata.json` or `metadata.yml`.

The data pipeline is the `just` recipes plus `sqlite-utils`: the green domains snapshot arrives
pre-built as a SQLite database from object storage, while the real time cloud dataset is a CSV
imported into a fresh SQLite database at build time.

## Deploying changes

### Automatic (the primary path)

Every push to `main` triggers [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml),
which runs the ansible deploy playbook against production. Note the playbook deploys **from
`main` on GitHub**, so local commits only go live once they are pushed and merged.

The workflow needs these GitHub secrets: `SSH_PRIVATE_KEY`, `BUCKET_NAME`, `RTC_BUCKET_NAME`,
and `MINIO_ALIAS`.

### Manual deploy

```
just release
```

runs the same playbook locally. It needs:

- SSH access to the `deploy` user on the production host
- `MINIO_ALIAS`, `BUCKET_NAME`, and `RTC_BUCKET_NAME` set in your environment — the playbook
  writes them into the server's shared `.env` (see `ansible/templates/dotenv.j2`)
- the ansible dependency, which lives in the project's dev dependency group

### What deployment does

The playbook (`ansible/deploy.yml`, inventory `ansible/inventories/prod.yml`) deploys to
`app3.thegreenwebfoundation.org` as the `deploy` user, into
`/var/www/datasets.thegreenwebfoundation.org/`, using the
[`f500.project_deploy`](ansible/roles/f500.project_deploy/README.md) role's release layout
(`current/` symlink plus a `shared/` directory for the `.env`). It then installs dependencies with
`uv sync`, writes the systemd unit (`dataset_browser.service`, running datasette on port 8001
behind a Caddy reverse proxy), and restarts the service.

### How the data stays fresh in production

A nightly cron at 05:00 runs `refresh_datasets.sh` on the server, which calls `just all_dataset_dbs`
(fresh green domains snapshot from object storage, plus a rebuilt real time cloud database) and
restarts the service. The upstream green domains dump is taken at 01:30, so the cron is timed to
run after it finishes.

## Contributing

Pull requests against `main` are welcome — CI runs `just test` on every push.

## Licensing

- The code is open source, licensed under the
  [Apache 2.0 license](https://choosealicense.com/licenses/apache-2.0/)
- The green domains data is available under the
  [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/summary/index.html) —
  in short, you are welcome to share it, create new works from it and adapt it, as long as you
  provide attribution and share under similar terms
- The real time cloud data is © 2021 Joint Development Foundation Projects, LLC, GSF Series and
  its contributors, licensed under the MIT license
