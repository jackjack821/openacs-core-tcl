<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="ad_locale_system_tz_offset.system_offset">      
      <querytext>
      
	select ( (sysdate - timezone.local_to_utc (:system_timezone, sysdate)) * 24 )
	from dual
    
      </querytext>
</fullquery>

 
</queryset>
