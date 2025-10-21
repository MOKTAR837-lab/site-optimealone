from alembic import op

revision = "0002_add_metadata_fields"
down_revision = "0001_init_pgvector_knowledge"
branch_labels = None
depends_on = None

def upgrade():
    op.execute("ALTER TABLE course_docs ADD COLUMN IF NOT EXISTS category TEXT, ADD COLUMN IF NOT EXISTS author TEXT, ADD COLUMN IF NOT EXISTS language TEXT DEFAULT 'fr';")
    op.execute("ALTER TABLE course_chunks ADD COLUMN IF NOT EXISTS header TEXT;")
    op.execute("ALTER TABLE course_embeddings ADD COLUMN IF NOT EXISTS model_name TEXT DEFAULT 'nomic-embed-text', ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW();")
    op.execute("CREATE INDEX IF NOT EXISTS idx_course_docs_category ON course_docs(category) WHERE category IS NOT NULL;")
    op.execute("CREATE INDEX IF NOT EXISTS idx_course_chunks_header ON course_chunks(header) WHERE header IS NOT NULL;")

def downgrade():
    op.execute("DROP INDEX IF EXISTS idx_course_chunks_header;")
    op.execute("DROP INDEX IF EXISTS idx_course_docs_category;")
    op.execute("ALTER TABLE course_embeddings DROP COLUMN IF EXISTS created_at, DROP COLUMN IF EXISTS model_name;")
    op.execute("ALTER TABLE course_chunks DROP COLUMN IF EXISTS header;")
    op.execute("ALTER TABLE course_docs DROP COLUMN IF EXISTS language, DROP COLUMN IF EXISTS author, DROP COLUMN IF EXISTS category;")
