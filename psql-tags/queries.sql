insert into
  tags (id, name, created_at, updated_at)
values
  ('tag_1', 'the tag', now (), now ());

insert into
  rooms (id, created_at, updated_at)
values
  ('room_1', now (), now ());

update rooms
set
  tag_ids = array_append (tag_ids, 'tag_1')
where
  id = 'room_1'
  and not 'tag_1' = any (tag_ids);
