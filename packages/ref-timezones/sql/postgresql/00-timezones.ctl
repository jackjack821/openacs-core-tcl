copy timezones 
from '[acs_root_dir]/packages/ref-timezones/sql/common/timezones.dat' 
[ad_decode [db_version] "7.2" "delimiters" "delimiter"] ',' 
[ad_decode [db_version] "7.2" "with null as" "null"] ''
