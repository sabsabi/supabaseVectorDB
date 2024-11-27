-- Enable the pgvector extension if not already enabled
create extension if not exists vector;

-- Create a table specifically for ACME documents
create table documents_acme (
  id bigserial primary key,
  content text, -- corresponds to Document.pageContent
  metadata jsonb, -- corresponds to Document.metadata
  embedding vector(1536) -- 1536 works for OpenAI embeddings, change if needed
);

-- Create a function to search for ACME documents
create function match_documents_acme (
  query_embedding vector(1536),
  match_count int default null,
  filter jsonb DEFAULT '{}'
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    content,
    metadata,
    1 - (documents_acme.embedding <=> query_embedding) as similarity
  from documents_acme
  where metadata @> filter
  order by documents_acme.embedding <=> query_embedding
  limit match_count;
end;
$$;
