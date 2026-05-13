"""SQLAlchemy engine and session factory."""

from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, DeclarativeBase

from app.config import settings

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    pool_recycle=300,
    connect_args={"options": "-c client_encoding=UTF8"},
)


@event.listens_for(engine, "connect")
def set_client_encoding(dbapi_conn, connection_record):
    """Force UTF-8 encoding on every new connection."""
    dbapi_conn.set_client_encoding("UTF8")


SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
