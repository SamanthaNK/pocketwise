"""add privacy mode to users

Revision ID: 5f2e8a1c9d3b
Revises: 0b9f0ea0e403
Create Date: 2026-08-07 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5f2e8a1c9d3b'
down_revision: Union[str, Sequence[str], None] = '0b9f0ea0e403'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # server_default='false' backfills every existing row so the column can be
    # NOT NULL from day one, without a separate data-migration step.
    op.add_column(
        'users',
        sa.Column('privacy_mode_enabled', sa.Boolean(), nullable=False, server_default=sa.text('false')),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('users', 'privacy_mode_enabled')
