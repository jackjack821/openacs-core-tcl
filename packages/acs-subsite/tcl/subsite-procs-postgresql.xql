<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="subsite::configure.add_constraint">      
      <querytext>

	select rel_constraint__new(
	  null,
	  'rel_constraint',
	  :constraint_name,
	  :segment_id,
	  'two',
	  rel_segment__get(:supersite_group_id, 'membership_rel'),
	  null,
	  :user_id,
	  :creation_ip
	);
		
      </querytext>
</fullquery>

 
<fullquery name="subsite::auto_mount_application.select_package_object_names">      
      <querytext>
      
	    select t.pretty_name as package_name, acs_object__name(s.object_id) as object_name
	      from site_nodes s, apm_package_types t
	     where s.node_id = :node_id
	       and t.package_key = :package_key
	
      </querytext>
</fullquery>

 
<fullquery name="subsite::util::sub_type_exists_p.sub_type_exists_p">      
      <querytext>
      
	select case 
                 when exists (select 1 from acs_object_types 
                              where supertype = :object_type)
                 then 1 
                 else 0 
               end
        
    
      </querytext>
</fullquery>

 
<fullquery name="subsite::util::object_type_path_list.select_object_type_path">      
      <querytext>

	select t2.object_type
	  from acs_object_types t1, acs_object_types t2
	 where t1.object_type = :object_type
	   and t1.tree_sortkey between t2.tree_sortkey and tree_right(t2.tree_sortkey)
	 order by t2.tree_sortkey desc
    
      </querytext>
</fullquery>

 
</queryset>
