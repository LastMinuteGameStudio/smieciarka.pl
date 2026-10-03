"""switch to jina 1024-dim embeddings

Revision ID: 8a945c5ffef1
Revises: f810b33664ea
Create Date: 2026-10-03 22:56:12.851427

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '8a945c5ffef1'
down_revision: Union[str, None] = 'f810b33664ea'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Vectors from different models are not comparable, so existing embeddings
    # are cleared rather than cast (spec section 11). Rows whose embedding is
    # NULL stay out of search and matching until they are reindexed.
    op.execute("UPDATE listings SET embedding = NULL")
    op.execute("UPDATE watch_filters SET embedding = NULL")
    op.execute("ALTER TABLE listings ALTER COLUMN embedding TYPE vector(1024)")
    op.execute("ALTER TABLE watch_filters ALTER COLUMN embedding TYPE vector(1024)")


def downgrade() -> None:
    op.execute("UPDATE listings SET embedding = NULL")
    op.execute("UPDATE watch_filters SET embedding = NULL")
    op.execute("ALTER TABLE listings ALTER COLUMN embedding TYPE vector(384)")
    op.execute("ALTER TABLE watch_filters ALTER COLUMN embedding TYPE vector(384)")
