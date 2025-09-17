
EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
/*
-- https://smartpostgres.com/posts/how-to-read-the-buffers-numbers-in-explain-plans/
Shared hit = pages that Postgres got from cache. (By default, Postgres pages are 8KB, so you can multiply these buffer numbers by 8KB to get a rough idea of how much data is involved.)
Read = pages that had to be read up from storage because they weren’t in cache. (Also 8KB by default.)
The block/page size is configurable, but is typically left at the default of 8192 bytes. You can check this on your server: show block_size;
*/
