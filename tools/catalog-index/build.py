"""Builds what the iPhone app needs to match a photo to the catalog, with no network (X5):

- ImageEncoder.mlpackage: SigLIP 2's image half in Core ML, weights quantized to int8. It
  takes a 224x224 RGB image and returns a unit-length embedding.
- catalog.bin: each catalog name's text embedding, unit length, float16, row after row.
- catalog.json: the names in the same order, the embedding size, and SigLIP's logit scale
  and bias, which turn a similarity into an independent 0-1 score.

Usage: .venv/bin/python -I build.py [--out ../../apps/ios/Hutch/Catalog] [--check photos/]

--check compares Core ML's embeddings with PyTorch's on those photos (X5 phase 3: cosine
similarity of at least 0.99), and fails if any is below.
"""
import argparse
import json
import sys
from datetime import date
from pathlib import Path

import coremltools as ct
import numpy as np
import torch
from PIL import Image, ImageOps
from transformers import AutoImageProcessor, AutoModel, GemmaTokenizerFast

try:
    from pillow_heif import register_heif_opener

    register_heif_opener()
except ImportError:
    pass

HERE = Path(__file__).parent
MODEL = "google/siglip2-base-patch16-224"
SIZE = 224


class ImageEncoder(torch.nn.Module):
    """The image half, ending in a unit-length embedding so the phone only needs dot products."""

    def __init__(self, model):
        super().__init__()
        self.model = model

    def forward(self, pixels):
        embedding = self.model.get_image_features(pixel_values=pixels)
        return embedding / embedding.norm(dim=-1, keepdim=True)


def load_catalog():
    lines = (HERE / "catalog.txt").read_text().splitlines()
    return [l.strip() for l in lines if l.strip() and not l.startswith("#")]


def convert(model, out):
    encoder = ImageEncoder(model).eval()
    traced = torch.jit.trace(encoder, torch.rand(1, 3, SIZE, SIZE))
    mlmodel = ct.convert(
        traced,
        # SigLIP's preprocessing is pixel / 127.5 - 1 on a 224x224 RGB image: Core ML does
        # the scaling, the app does the resizing.
        inputs=[ct.ImageType(name="image", shape=(1, 3, SIZE, SIZE), scale=1 / 127.5, bias=[-1, -1, -1], color_layout=ct.colorlayout.RGB)],
        outputs=[ct.TensorType(name="embedding")],
        minimum_deployment_target=ct.target.iOS18,
        compute_precision=ct.precision.FLOAT16,
    )
    # int8 in blocks of 32 weights, each block with its own scale. One scale per channel (the
    # default) drifted to a cosine of 0.93 against PyTorch on my photos; per block stays at
    # 0.9998 for a few MB more.
    config = ct.optimize.coreml.OptimizationConfig(
        global_config=ct.optimize.coreml.OpLinearQuantizerConfig(mode="linear_symmetric", dtype="int8", granularity="per_block", block_size=32)
    )
    mlmodel = ct.optimize.coreml.linear_quantize_weights(mlmodel, config=config)
    mlmodel.short_description = f"{MODEL} image encoder, int8 weights, unit-length output. Apache 2.0."
    path = out / "ImageEncoder.mlpackage"
    mlmodel.save(str(path))
    return mlmodel, path


def embed_catalog(model, tokenizer, catalog):
    with torch.no_grad():
        texts = tokenizer([f"a photo of a {c}.".lower() for c in catalog], padding="max_length", max_length=64, return_tensors="pt")
        emb = model.get_text_features(**texts)
        return (emb / emb.norm(dim=-1, keepdim=True)).numpy()


def check(model, mlmodel, image_processor, photos):
    """Core ML against PyTorch on real photos; returns the lowest cosine similarity."""
    lowest = 1.0
    for path in sorted(p for p in photos.iterdir() if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".heic"}):
        image = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
        with torch.no_grad():
            pixels = image_processor(images=image, return_tensors="pt")["pixel_values"]
            reference = ImageEncoder(model)(pixels)[0].numpy()
        resized = image.resize((SIZE, SIZE), Image.BILINEAR)
        ours = np.array(mlmodel.predict({"image": resized})["embedding"]).reshape(-1)
        cosine = float(np.dot(reference, ours) / (np.linalg.norm(reference) * np.linalg.norm(ours)))
        lowest = min(lowest, cosine)
        print(f"  {cosine:.4f}  {path.name}")
    return lowest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=HERE / "../../apps/ios/Hutch/Catalog")
    parser.add_argument("--check", type=Path)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    model = AutoModel.from_pretrained(MODEL, torch_dtype=torch.float32).eval()
    tokenizer = GemmaTokenizerFast.from_pretrained(MODEL)
    catalog = load_catalog()

    print("Embedding the catalog…")
    vectors = embed_catalog(model, tokenizer, catalog)
    (args.out / "catalog.bin").write_bytes(vectors.astype("<f2").tobytes())
    (args.out / "catalog.json").write_text(json.dumps({
        "model": MODEL,
        "built": date.today().isoformat(),
        "dimensions": int(vectors.shape[1]),
        "logitScale": float(model.logit_scale.exp()),
        "logitBias": float(model.logit_bias),
        "names": catalog,
    }, ensure_ascii=False, indent=1))
    print(f"  {len(catalog)} names, {vectors.shape[1]} dimensions")

    print("Converting the image encoder to Core ML…")
    mlmodel, path = convert(model, args.out)
    size = sum(f.stat().st_size for f in path.rglob("*") if f.is_file())
    print(f"  {path.name}: {size / 1e6:.0f} MB")

    if args.check:
        # The compute units the app uses on the phone: the Neural Engine and CPU paths drift
        # to a cosine of 0.97 with these int8 weights; the GPU path doesn't.
        print("Checking Core ML (CPU and GPU, as on the phone) against PyTorch:")
        image_processor = AutoImageProcessor.from_pretrained(MODEL)
        on_phone = ct.models.MLModel(str(path), compute_units=ct.ComputeUnit.CPU_AND_GPU)
        lowest = check(model, on_phone, image_processor, args.check)
        print(f"  lowest cosine similarity: {lowest:.4f}")
        if lowest < 0.99:
            sys.exit("Below 0.99: Core ML doesn't match PyTorch closely enough.")


if __name__ == "__main__":
    main()
