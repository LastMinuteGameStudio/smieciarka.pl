"""add pickup date and address to listings

Revision ID: c3d1a7e9b2f4
Revises: 8a945c5ffef1
Create Date: 2026-10-04 12:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c3d1a7e9b2f4'
down_revision: Union[str, None] = '8a945c5ffef1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('listings', sa.Column('pickup_date', sa.Date(), nullable=True))
    op.add_column('listings', sa.Column('address', sa.String(length=200), nullable=True))


def downgrade() -> None:
    op.drop_column('listings', 'address')
    op.drop_column('listings', 'pickup_date')
