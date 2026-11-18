#!/usr/bin/env python3
"""Encrypt bundled content assets per docs/ASSET_FORMAT.md.

Usage:
    DHA_ASSET_KEY=<passphrase> python3 tools/encrypt_assets.py [--verify]

Reads plaintext from assets_src/, writes ciphertext to assets/encrypted/.
Deterministic: unchanged sources produce byte-identical output.
"""

import argparse
import hashlib
import hmac
import os
import sys
from pathlib import Path

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets_src"
OUT = ROOT / "assets" / "encrypted"
MANIFEST = ROOT / "tools" / "asset_manifest.log"

MAGIC = bytes.fromhex("A74E435259505421")
VERSION = 0x01

# Content files to encrypt: logical_id -> source path (relative to assets_src/)
ASSETS = {
    "data/dictionary_full": "data/dictionary_full.json",
    "data/cultural_facts": "data/cultural_facts.json",
    "bible": "bible.json",
}


def load_key() -> bytes:
    passphrase = os.environ.get("DHA_ASSET_KEY")
    if not passphrase:
        sys.exit("error: set DHA_ASSET_KEY environment variable")
    return hashlib.sha256(passphrase.encode("utf-8")).digest()


def derive(key: bytes, label: str, logical_id: str, n: int) -> bytes:
    return hmac.new(key, f"{label}:{logical_id}".encode(), hashlib.sha256).digest()[:n]


def obfuscated_name(key: bytes, logical_id: str) -> str:
    return derive(key, "name", logical_id, 8).hex()


def nonce_for(key: bytes, logical_id: str) -> bytes:
    return derive(key, "nonce", logical_id, 12)


def encrypt_file(key: bytes, aes: AESGCM, logical_id: str, src: Path) -> Path:
    plaintext = src.read_bytes()
    nonce = nonce_for(key, logical_id)
    ciphertext = aes.encrypt(nonce, plaintext, None)  # includes 16-byte tag
    name = obfuscated_name(key, logical_id)
    out = OUT / name
    out.write_bytes(MAGIC + bytes([VERSION]) + nonce + ciphertext)
    return out


def decrypt_file(key: bytes, aes: AESGCM, path: Path) -> bytes:
    blob = path.read_bytes()
    assert blob[:8] == MAGIC, "bad magic"
    assert blob[8] == VERSION, "bad version"
    nonce, ct = blob[9:21], blob[21:]
    return aes.decrypt(nonce, ct, None)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--verify", action="store_true",
                    help="decrypt outputs and diff against sources")
    args = ap.parse_args()

    key = load_key()
    aes = AESGCM(key)
    OUT.mkdir(parents=True, exist_ok=True)

    manifest_lines = []
    failures = 0

    for logical_id, rel in ASSETS.items():
        src = SRC / rel
        if not src.exists():
            print(f"SKIP {logical_id}: {src} not found", file=sys.stderr)
            continue
        out = encrypt_file(key, aes, logical_id, src)
        manifest_lines.append(f"{rel} -> assets/encrypted/{out.name}")
        print(f"encrypted {logical_id}: {src.name} -> {out.name}")

        if args.verify:
            back = decrypt_file(key, aes, out)
            if back == src.read_bytes():
                print(f"  verify OK ({len(back)} bytes)")
            else:
                failures += 1
                print(f"  verify FAILED for {logical_id}", file=sys.stderr)

    MANIFEST.write_text("\n".join(manifest_lines) + "\n")
    print(f"\nmanifest -> {MANIFEST.relative_to(ROOT)}")

    # Decoys: valid-looking containers with garbage ciphertext so bulk
    # extraction scripts produce visibly broken output.
    decoys = write_decoys(key, aes)
    print(f"decoys: {decoys} written")

    if failures:
        sys.exit(f"{failures} verification failure(s)")


def write_decoys(key: bytes, aes: AESGCM) -> int:
    """Deterministic fake encrypted files — same container shape, random
    payload that can never decrypt. Names derive from fake logical ids so
    they can never collide with real assets."""
    count = 0
    for i in range(8):
        logical_id = f"decoy_{i:02d}"
        name = obfuscated_name(key, logical_id)
        nonce = nonce_for(key, logical_id)
        # Deterministic "ciphertext" — hash counter stream, NOT encrypted.
        size = 180 + (i * 137) % 600
        junk = bytearray()
        counter = 0
        while len(junk) < size:
            junk += hashlib.sha256(
                b"decoy" + logical_id.encode() + counter.to_bytes(4, "big")
            ).digest()
            counter += 1
        blob = MAGIC + bytes([VERSION]) + nonce + bytes(junk[:size])
        (OUT / name).write_bytes(blob)
        count += 1
    return count


if __name__ == "__main__":
    main()
