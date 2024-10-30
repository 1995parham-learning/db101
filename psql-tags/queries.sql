INSERT INTO tags (
    id,
    name,
    created_at,
    updated_at)
VALUES (
    'tag_1',
    'the tag',
    now(),
    now());

INSERT INTO rooms (
    id,
    created_at,
    updated_at)
VALUES (
    'room_1',
    now(),
    now());

UPDATE
    rooms
SET
    tag_ids = array_append(tag_ids, 'tag_1')
WHERE
    id = 'room_1'
    AND NOT 'tag_1' = ANY (tag_ids);

