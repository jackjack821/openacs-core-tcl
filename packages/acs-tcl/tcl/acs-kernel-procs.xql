<?xml version="1.0"?>
<queryset>

<fullquery name="ad_acs_administrator_exists_p.admin_exists_p">      
      <querytext>
      
	select 1 as admin_exists_p
	from dual
	where exists (select 1
		      from acs_object_party_privilege_map m, users u
		      where m.object_id = 0
		      and m.party_id = u.user_id
		      and m.privilege = 'admin')
    
      </querytext>
</fullquery>

<fullquery name="ad_acs_admin_node.acs_admin_node_p">      
      <querytext>
      
	select case when count(object_id) = 0 then 0 else 1 end
	from site_nodes
	where object_id = (select package_id 
	                   from apm_packages 
	                   where package_key = 'acs-admin')
    
      </querytext>
</fullquery>

</queryset>
