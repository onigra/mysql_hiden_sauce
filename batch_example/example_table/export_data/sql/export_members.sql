use test;

select
  *
into outfile '/usr/local/lib/mysql_hiden_sauce/batch_example/data/example_table/members.csv'
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
from
  members
;

