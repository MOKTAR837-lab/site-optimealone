from alembic import op

# Première migration de la chaîne Alembic
revision = "0001_init_pgvector_knowledge"
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # 1) Extension pgvector (idempotent)
    op.execute("CREATE EXTENSION IF NOT EXISTS vector;")

    # 2) Tables documents / chunks / embeddings
    op.execute("""
    CREATE TABLE IF NOT EXISTS course_docs (
      id BIGSERIAL PRIMARY KEY,
      path TEXT NOT NULL,
      sha256 TEXT NOT NULL,
      topic TEXT,
      valid_from TIMESTAMP NULL,
      valid_to TIMESTAMP NULL,
      meta JSONB DEFAULT '{}'::jsonb,
      created_at TIMESTAMP DEFAULT NOW()
    );
    """)

    op.execute("""
    CREATE TABLE IF NOT EXISTS course_chunks (
      id BIGSERIAL PRIMARY KEY,
      doc_id BIGINT NOT NULL REFERENCES course_docs(id) ON DELETE CASCADE,
      ordinal INT NOT NULL,
      text TEXT NOT NULL
    );
    """)

    # Dimension 768 pour nomic-embed-text (Ollama)
    op.execute("""
    CREATE TABLE IF NOT EXISTS course_embeddings (
      chunk_id BIGINT PRIMARY KEY REFERENCES course_chunks(id) ON DELETE CASCADE,
      embedding vector(768)
    );
    """)

    # 3) Index ANN (cosine)
    op.execute("""
    CREATE INDEX IF NOT EXISTS idx_course_embeddings_ann
      ON course_embeddings
      USING hnsw (embedding vector_cosine_ops);
    """)

    # 4) Index utiles
    op.execute("CREATE INDEX IF NOT EXISTS idx_course_docs_sha ON course_docs(sha256);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_course_chunks_doc ON course_chunks(doc_id);")
    op.execute("CREATE INDEX IF NOT EXISTS idx_course_chunks_ord ON course_chunks(ordinal);")


def downgrade():
    op.execute("DROP INDEX IF EXISTS idx_course_embeddings_ann;")
    op.execute("DROP INDEX IF EXISTS idx_course_docs_sha;")
    op.execute("DROP INDEX IF EXISTS idx_course_chunks_doc;")
    op.execute("DROP INDEX IF EXISTS idx_course_chunks_ord;")
    op.execute("DROP TABLE IF EXISTS course_embeddings;")
    op.execute("DROP TABLE IF EXISTS course_chunks;")
    op.execute("DROP TABLE IF EXISTS course_docs;")