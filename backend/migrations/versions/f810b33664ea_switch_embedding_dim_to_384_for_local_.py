"""switch embedding dim to 384 for local fastembed model

Revision ID: f810b33664ea
Revises: 7423f87c964e
Create Date: 2026-10-03 22:06:59.446571

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f810b33664ea'
down_revision: Union[str, None] = '7423f87c964e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TABLE listings ALTER COLUMN embedding TYPE vector(384)")
    op.execute("ALTER TABLE watch_filters ALTER COLUMN embedding TYPE vector(384)")


def downgrade() -> None:
    op.execute("ALTER TABLE listings ALTER COLUMN embedding TYPE vector(1536)")
    op.execute("ALTER TABLE watch_filters ALTER COLUMN embedding TYPE vector(1536)")
