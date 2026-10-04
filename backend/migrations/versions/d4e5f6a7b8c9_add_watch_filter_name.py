"""add name to watch filters

Revision ID: d4e5f6a7b8c9
Revises: c3d1a7e9b2f4
Create Date: 2026-10-04 13:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd4e5f6a7b8c9'
down_revision: Union[str, None] = 'c3d1a7e9b2f4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('watch_filters', sa.Column('name', sa.String(length=60), nullable=True))


def downgrade() -> None:
    op.drop_column('watch_filters', 'name')
