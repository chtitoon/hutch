"""Scores a photo-to-catalog lookup for X5: for each photo, the 5 closest catalog entries.

Usage: .venv/bin/python -I score.py photos/ [--model google/siglip2-base-patch16-224]

Photos are named after what they really are, e.g. "Apple MacBook Air.heic" or
"RAVPower USB-C charger 2.jpg" (a trailing number is ignored). A photo counts as a hit
when that name is among its top 5. Unnamed photos (IMG_1234.jpg) just print their top 5.
Nothing leaves this Mac: the model runs locally once downloaded.
"""
import argparse
import csv
import re
import sys
import time
from pathlib import Path

import torch
from PIL import Image, ImageOps
from transformers import AutoImageProcessor, AutoModel, GemmaTokenizerFast

try:
    from pillow_heif import register_heif_opener

    register_heif_opener()
except ImportError:
    pass

HERE = Path(__file__).parent


def load_catalog():
    lines = (HERE / "catalog.txt").read_text().splitlines()
    return [l.strip() for l in lines if l.strip() and not l.startswith("#")]


def load_labels(photos):
    """photos/labels.csv, optional: file name, then every catalog name that counts as right,
    separated by ";". `Robot Mixer.JPG,hand mixer` accepts "hand mixer" for that photo."""
    path = photos / "labels.csv"
    if not path.exists():
        return {}
    labels = {}
    for row in csv.reader(path.read_text().splitlines()):
        if len(row) >= 2 and not row[0].startswith("#"):
            labels[row[0].strip()] = [a.strip().lower() for a in row[1].split(";") if a.strip()]
    return labels


def truth_of(path, labels):
    """What counts as right for a photo: its labels.csv entry, else its file name."""
    if path.name in labels:
        return labels[path.name]
    stem = re.sub(r"[\s_-]*\d+$", "", path.stem).strip()
    return None if re.match(r"^(IMG|DSC|PXL|Photo)", stem, re.I) else [stem.lower()]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("photos", type=Path)
    parser.add_argument("--model", default="google/siglip2-base-patch16-224")
    args = parser.parse_args()

    device = "mps" if torch.backends.mps.is_available() else "cpu"
    model = AutoModel.from_pretrained(args.model).to(device).eval()
    # SigLIP 2's config names the SigLIP tokenizer, but it ships Gemma's (tokenizer.json):
    # load the fast one directly, and the image processor on its own.
    tokenizer = GemmaTokenizerFast.from_pretrained(args.model)
    image_processor = AutoImageProcessor.from_pretrained(args.model)
    catalog = load_catalog()

    with torch.no_grad():
        # SigLIP 2 was trained on lowercase text, padded to 64 tokens.
        texts = tokenizer([f"a photo of a {c}.".lower() for c in catalog], padding="max_length", max_length=64, return_tensors="pt").to(device)
        text_emb = model.get_text_features(**texts)
        text_emb = text_emb / text_emb.norm(dim=-1, keepdim=True)

    photos = sorted(p for p in args.photos.iterdir() if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".heic"})
    if not photos:
        sys.exit(f"No photos in {args.photos}")

    labels = load_labels(args.photos)
    known = {c.lower() for c in catalog}
    hits = firsts = scored = 0
    for path in photos:
        image = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
        start = time.perf_counter()
        with torch.no_grad():
            pixels = image_processor(images=image, return_tensors="pt").to(device)
            emb = model.get_image_features(**pixels)
            emb = emb / emb.norm(dim=-1, keepdim=True)
            scores = (emb @ text_emb.T)[0]
        ms = (time.perf_counter() - start) * 1000
        top = [catalog[i] for i in scores.topk(5).indices.tolist()]
        truth = truth_of(path, labels)
        mark = ""
        if truth:
            scored += 1
            ranks = [i for i, t in enumerate(top) if t.lower() in truth]
            hits += bool(ranks)
            firsts += ranks[:1] == [0]
            mark = f"#{ranks[0] + 1}  " if ranks else "MISS"
            if not any(t in known for t in truth):
                mark += " (not in catalog)"
        print(f"{mark:5} {path.name}  [{ms:.0f} ms]\n      " + " · ".join(top))

    if scored:
        print(f"\nFirst: {firsts} of {scored}. Top 5: {hits} of {scored}. ({args.model}, {len(catalog)} catalog entries)")


if __name__ == "__main__":
    main()
