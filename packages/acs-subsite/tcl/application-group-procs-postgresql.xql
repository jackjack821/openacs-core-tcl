<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="application_group::contains_party_p.app_group_contains_party_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_element_map
	        where package_id = :package_id
	          and element_id = :party_id
	      union all
	        select 1
	        from application_groups
	        where package_id = :package_id
	          and group_id = :party_id
	    ) then 1 else 0 end
            
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::contains_party_p.app_group_contains_party_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_element_map
	        where package_id = :package_id
	          and element_id = :party_id
	      union all
	        select 1
	        from application_groups
	        where package_id = :package_id
	          and group_id = :party_id
	    ) then 1 else 0 end
            
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::contains_relation_p.app_group_contains_rel_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_element_map
	        where package_id = :package_id
	          and rel_id = :rel_id
	    ) then 1 else 0 end
            
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::contains_segment_p.app_group_contains_segment_p">      
      <querytext>
      
	    select case when exists (
	        select 1
	        from application_group_segments
	        where package_id = :package_id
	          and segment_id = :segment_id
	    ) then 1 else 0 end
            
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::group_id_from_package_id.application_group_from_package_id_query">      
      <querytext>

	    select application_group__group_id_from_package_id (
	        :package_id,
	        :no_complain_p
	    )
	
      </querytext>
</fullquery>

 
<fullquery name="application_group::new.parent_group_id_query">      
      <querytext>

		    select ag.group_id as parent_group_id
		    from application_groups ag,
		         apm_packages,
		         (select object_id, 1 as tree_rownum
		          from site_nodes
			  where tree_sortkey like (select tree_sortkey from site_nodes where node_id = :node_id) || '%') nodes
                    where nodes.object_id = apm_packages.package_id
                      and apm_packages.package_id = ag.package_id
                    limit 1
		
      </querytext>
</fullquery>

 
<fullquery name="application_group::new.add_group">      
      <querytext>

		select application_group__new (
	            :group_id,
	            :group_type,
		    now(),
	            :creation_user,
	            :creation_ip,
		    :email,
		    :url,
	            :group_name,
                    :package_id,
	            :context_id
		)
	    
      </querytext>
</fullquery>

 
<fullquery name="application_group::new.add_composition_rel">      
      <querytext>

		    select composition_rel__new (
			    null,
		            'composition_rel',
		            :parent_group_id,
		            :group_id,
		            :creation_user,
                            :creation_ip
		    )
		
      </querytext>
</fullquery>

 
</queryset>
