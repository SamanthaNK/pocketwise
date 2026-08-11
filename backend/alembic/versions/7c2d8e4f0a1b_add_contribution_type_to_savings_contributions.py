"""add contribution type to savings contributions

Revision ID: 7c2d8e4f0a1b
Revises: 6a1b7c3d9e0f
Create Date: 2026-08-08 09:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '7c2d8e4f0a1b'
down_revision: Union[str, Sequence[str], None] = '6a1b7c3d9e0f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    savings_contribution_type = sa.Enum('deposit', 'withdrawal', name='savings_contribution_type')
    savings_contribution_type.create(op.get_bind(), checkfirst=True)
    op.add_column(
        'savings_contributions',
        sa.Column('contribution_type', savings_contribution_type, nullable=False, server_default='deposit'),
    )


def downgrade() -> None:
    op.drop_column('savings_contributions', 'contribution_type')
    sa.Enum(name='savings_contribution_type').drop(op.get_bind(), checkfirst=True)
