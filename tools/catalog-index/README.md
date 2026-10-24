# Catalog index

[X5](../../ROADMAP.md#x5)'s tools, run on the Mac.

The goal: from a photo, the phone suggests what a thing is by finding the closest entries in a catalog of names, with no network call. These tools build and score that catalog. The app only ever gets the finished files.

## What's here

- `catalog.txt`: a hand-made catalog, one name per line. It's the phase 2 starting point, before the Google Product Taxonomy and Wikidata layers.
- `score.py`: scores photos against the catalog with SigLIP 2 (`google/siglip2-base-patch16-224`, Apache 2.0). Prints each photo's 5 closest entries and the top-5 hit rate.

## Running it

1. `python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`
2. Put photos in `photos/`, each named after what it really is: `Apple MacBook Air.heic`, `wooden picture frame 2.jpg`. A trailing number is ignored. Optionally, `photos/labels.csv` lists every catalog name that counts as right per photo (`Robot Mixer.JPG,hand mixer`).
3. `.venv/bin/python -I score.py photos/`

The first run downloads the model, about 1.5 GB. After that, nothing leaves the Mac.

`photos/` is git-ignored: my photos never enter the repo.
