<?xml version="1.0"?>
<queryset>

<fullquery name="new.package_select">      
      <querytext>
      
	    select t.package_name, lower(t.id_column) as id_column
	      from acs_object_types t
	     where t.object_type = :group_type
	
      </querytext>
</fullquery>

 
<fullquery name="new.package_select">      
      <querytext>
      
	    select t.package_name, lower(t.id_column) as id_column
	      from acs_object_types t
	     where t.object_type = :group_type
	
      </querytext>
</fullquery>

 
<fullquery name="join_policy.select_join_policy">      
      <querytext>
      
	    select join_policy from groups where group_id = :group_id
	
      </querytext>
</fullquery>

 
</queryset>
