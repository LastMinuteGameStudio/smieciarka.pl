"""Object storage for listing photos (S3 API, MinIO in dev).

boto3 is synchronous, so every call is pushed to a thread the way the local
embedding model is -- the event loop must not block on network I/O.

Two clients, not one. SigV4 signs the Host header, so a URL signed against
the internal endpoint (minio:9000) is rejected when a browser calls it on
localhost:9000, and the host cannot be rewritten after signing. Uploads and
deletes go through the internal client; presigned GETs come from the public
one. Outside compose both settings point at the same place and the two
clients are identical.
"""

import asyncio
import logging

import boto3
from botocore.client import Config
from botocore.exceptions import ClientError

from app.config import settings

logger = logging.getLogger(__name__)

# Presigned URLs need SigV4 for MinIO to accept them.
#
# Path addressing is pinned, not left to boto3's "auto". Auto puts a
# DNS-compatible bucket in the hostname, which turns the public endpoint into
# listing-images.s3.wkrynski.dev -- a name with no DNS record and no tunnel
# route, so every presigned URL would fail to resolve. Path style keeps the
# bucket where the single hostname can serve it.
_CONFIG = Config(
    signature_version="s3v4",
    s3={"addressing_style": "path"},
    retries={"max_attempts": 3},
)

_internal_client = None
_public_client = None
_bucket_ready = False


def _build_client(endpoint: str):
    return boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=settings.s3_access_key,
        aws_secret_access_key=settings.s3_secret_key,
        region_name=settings.s3_region,
        config=_CONFIG,
    )


def _internal():
    global _internal_client
    if _internal_client is None:
        _internal_client = _build_client(settings.s3_endpoint)
    return _internal_client


def _public():
    global _public_client
    if _public_client is None:
        _public_client = _build_client(settings.s3_signing_endpoint)
    return _public_client


def _ensure_bucket_sync() -> None:
    """Create the bucket once per process if it does not exist yet.

    Done lazily rather than at startup so the API still boots (and /health
    still answers) when MinIO is down -- only image endpoints fail.
    """
    global _bucket_ready
    if _bucket_ready:
        return
    client = _internal()
    try:
        client.head_bucket(Bucket=settings.s3_bucket)
    except ClientError as exc:
        code = exc.response.get("Error", {}).get("Code")
        if code not in ("404", "NoSuchBucket", "NotFound"):
            raise
        client.create_bucket(Bucket=settings.s3_bucket)
        logger.info("created bucket %s", settings.s3_bucket)
    _bucket_ready = True


def _put_sync(key: str, data: bytes, content_type: str) -> None:
    _ensure_bucket_sync()
    _internal().put_object(
        Bucket=settings.s3_bucket, Key=key, Body=data, ContentType=content_type
    )


def _delete_sync(keys: list[str]) -> None:
    if not keys:
        return
    _ensure_bucket_sync()
    _internal().delete_objects(
        Bucket=settings.s3_bucket, Delete={"Objects": [{"Key": k} for k in keys]}
    )


def _presign_sync(key: str) -> str:
    return _public().generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.s3_bucket, "Key": key},
        ExpiresIn=settings.s3_presign_ttl,
    )


async def put(key: str, data: bytes, content_type: str) -> None:
    await asyncio.to_thread(_put_sync, key, data, content_type)


async def delete(keys: list[str]) -> None:
    await asyncio.to_thread(_delete_sync, keys)


def presigned_get(key: str) -> str:
    """Time-limited read URL. Pure signing, no network call, so not async."""
    return _presign_sync(key)
