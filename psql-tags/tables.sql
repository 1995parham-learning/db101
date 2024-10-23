CREATE TABLE IF NOT EXISTS tags (
    id varchar PRIMARY KEY,
    name text NOT NULL,
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp NOT NULL DEFAULT now(),
);

CREATE TABLE IF NOT EXISTS rooms (
    id varchar PRIMARY KEY,
    tag_ids varchar[] DEFAULT '{}' ::varchar[] NOT NULL;

created_at timestamp NOT NULL DEFAULT now(),
updated_at timestamp NOT NULL DEFAULT now(),
)
