<?xml version="1.0"?>
<queryset>
 
 
<fullquery name="apm_package_deinstall.apm_uninstall_record">      
      <querytext>
      
	update apm_package_versions
	set    installed_p = 'f', enabled_p = 'f'
	where package_key = :package_key
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_version_count.apm_package_version_count">      
      <querytext>
      
	select count(*) from apm_package_versions
	where package_key = :package_key
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_upgrade_parameters.parameter_id_get">      
      <querytext>
      
	    select parameter_id from apm_parameters
	    where parameter_name = :parameter_name
	    and package_key = :package_key
	
      </querytext>
</fullquery>

 
<fullquery name="apm_package_upgrade_parameters.all_parameters_for_package_key">      
      <querytext>
      
	select parameter_id, parameter_name
	from apm_parameters
	where package_key =:package_key
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_dependencies.all_dependencies_for_version">      
      <querytext>
      
	select dependency_id from apm_package_dependencies
	where version_id = :version_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_owners.apm_delete_owners">      
      <querytext>
      
	delete from apm_package_owners where version_id = :version_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_owners.owner_insert">      
      <querytext>
      
	    insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
	    values(:version_id, :owner_uri, :owner_name, :counter)
	
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_files.files_delete">      
      <querytext>
      
	delete from apm_package_files where version_id = :version_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_spec.package_version_info_select">      
      <querytext>
      
	select package_key, version_id
	from apm_package_version_info 
	where version_id = :version_id
    
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_spec.package_spec_path_select">      
      <querytext>
      
            select path
            from apm_package_files
            where version_id = :version_id
            and file_type = 'package_spec'
	    and path = :info_file_name
        
      </querytext>
</fullquery>

 
<fullquery name="apm_package_install_spec.apm_spec_file_register">      
      <querytext>
      
	    update apm_package_types
		set spec_file_path = :path
	        where package_key = :package_key
	
      </querytext>
</fullquery>
 
</queryset>
