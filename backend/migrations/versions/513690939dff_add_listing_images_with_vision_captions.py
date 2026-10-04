"""add listing images with vision captions

A listing holds many photos, so they get their own table rather than columns
on listings. Each row carries its own vision caption; listings.image_caption
is the joined form of those captions, kept because it feeds the embedding
text and is read on every reindex.

No backfill: listings created before this migration simply have no images.

Revision ID: 513690939dff
Revises: 8a945c5ffef1
Create Date: 2026-10-03 23:41:02.118446

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '513690939dff'
down_revision: Union[str, None] = '8a945c5ffef1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'listing_images',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('listing_id', sa.UUID(), nullable=False),
        sa.Column('storage_key', sa.String(), nullable=False),
        sa.Column('thumb_key', sa.String(), nullable=False),
        sa.Column('position', sa.SmallInteger(), nullable=False),
        sa.Column('caption', sa.Text(), nullable=True),
        # Deleting a listing takes its image rows with it. The objects in the
        # bucket are not reached by this cascade -- the API deletes those
        # explicitly, and there is no listing-delete endpoint yet.
        sa.ForeignKeyConstraint(['listing_id'], ['listings.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(
        op.f('ix_listing_images_listing_id'), 'listing_images', ['listing_id'], unique=False
    )
    op.add_column('listings', sa.Column('image_caption', sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column('listings', 'image_caption')
    op.drop_index(op.f('ix_listing_images_listing_id'), table_name='listing_images')
    op.drop_table('listing_images')
