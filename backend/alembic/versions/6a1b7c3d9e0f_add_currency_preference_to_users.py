"""add currency preference to users

Revision ID: 6a1b7c3d9e0f
Revises: 5f2e8a1c9d3b
Create Date: 2026-08-08 09:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '6a1b7c3d9e0f'
down_revision: Union[str, Sequence[str], None] = '5f2e8a1c9d3b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'users',
        sa.Column('currency_preference', sa.String(length=3), nullable=False, server_default='XAF'),
    )


def downgrade() -> None:
    op.drop_column('users', 'currency_preference')
