<?xml version="1.0"?>
<queryset>

<fullquery name="select_type_info">      
      <querytext>
      
    select t.table_name, t.package_name
      from acs_object_types t
     where t.object_type=:group_type

      </querytext>
</fullquery>

 
<fullquery name="select_group_ids">      
      <querytext>
      
	    select o.object_id
	    from acs_objects o, acs_object_party_privilege_map perm
	    where perm.object_id = o.object_id
              and perm.party_id = :user_id
              and perm.privilege = 'delete'
	      and o.object_type = :group_type
	
      </querytext>
</fullquery>

</queryset>
