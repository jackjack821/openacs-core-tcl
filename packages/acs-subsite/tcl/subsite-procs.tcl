# /packages/subsite/tcl/subsite-procs.tcl

ad_library {

    Procs to manage application groups

    @author oumi@arsdigita.com
    @creation-date 2001-02-01
    @cvs-id $Id$

}

namespace eval subsite {
    namespace eval util {}
}

ad_proc -public subsite::after_mount { 
    {-package_id:required}
    {-node_id:required}
} {
    This is the TCL proc that is called automatically by the APM
    whenever a new instance of the subsites application is mounted.

    We do three things:

    <ul>
      <li> Create application group
      <li> Create segment "Subsite Users"
      <li> Create relational constraint to make subsite registration 
           require supersite registration.
    </ul>

    @author Don Baccus (dhogaza@pacifier.com)
    @creation-date 2003-03-05

} {

    if { [empty_string_p [application_group::group_id_from_package_id -no_complain -package_id $package_id]] } {

        set subsite_name [db_string subsite_name_query {}]

        set truncated_subsite_name [string range $subsite_name 0 89]

        db_transaction {

            # Create subsite application group
            set group_name "$truncated_subsite_name Parties"
            set subsite_group_id [application_group::new \
                                      -package_id $package_id \
                                      -group_name $group_name]

            # Create segment of registered users
            set segment_name "$truncated_subsite_name Members"
            set segment_id [rel_segments_new $subsite_group_id membership_rel $segment_name]

            # Create a constraint that says "to be a member of this
            # subsite you must be a member of the parent subsite".
	    set subsite_id [site_node_closest_ancestor_package acs-subsite]

            db_1row parent_subsite_query {}

            set constraint_name "Members of [string range $subsite_name 0 30] must be members of [string range $supersite_name 0 30]"
            set user_id [ad_conn user_id]
            set creation_ip [ad_conn peeraddr]
            db_exec_plsql add_constraint {}

            # Create segment of registered users for administrators
            set segment_name "$truncated_subsite_name Administrators"
            set admin_segment_id [rel_segments_new $subsite_group_id admin_rel $segment_name]

            # Grant admin privileges to the admin segment
            permission::grant \
                -party_id $admin_segment_id \
                -object_id $package_id \
                -privilege admin

            # Grant read/write/create privileges to the member segment
            foreach privilege { read create write } {
                permission::grant \
                    -party_id $segment_id \
                    -object_id $package_id \
                    -privilege $privilege
            }
            
        }
    }
}

ad_proc -public subsite::before_uninstantiate { 
    {-package_id:required}
} {

    Delete the application group associated with this subsite.

} {
    application_group::delete -group_id [application_group::group_id_from_package_id -package_id $package_id]
}

ad_proc -public subsite::before_upgrade { 
    {-from_version_name:required}
    {-to_version_name:required}
} {
    Handles upgrade
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.0d3 5.0d4 {
                array set main_site [site_node::get -url /]
                set main_site_id $main_site(package_id)

                # Move parameter values from subsite to kernel

                parameter::set_value \
                    -package_id [ad_acs_kernel_id] \
                    -parameter ApprovalExpirationDays \
                    -value [parameter::get \
                                -package_id $main_site_id \
                                -parameter ApprovalExpirationDays \
                                -default 0]
                
                parameter::set_value \
                    -package_id [ad_acs_kernel_id] \
                    -parameter PasswordExpirationDays \
                    -value [parameter::get \
                                -package_id $main_site_id \
                                -parameter PasswordExpirationDays \
                                -default 0]
                
                
                apm_parameter_unregister \
                    -package_key acs-subsite \
                    -parameter ApprovalExpirationDays \
                    {}

                apm_parameter_unregister \
                    -package_key acs-subsite \
                    -parameter PasswordExpirationDays \
                    {}
            }
        }
}



ad_proc -private subsite::instance_name_exists_p {
    node_id
    instance_name 
} { 
    Returns 1 if the instance_name exists at this node. 0
    otherwise. Note that the search is case-sensitive.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-03-01

} {
    return [db_string select_name_exists_p {
	select count(*) 
	  from site_nodes
	 where parent_id = :node_id
	   and name = :instance_name
    }]
}

ad_proc -public subsite::auto_mount_application { 
    { -instance_name "" }
    { -pretty_name "" }
    { -node_id "" }
    package_key
} {
    Mounts a new instance of the application specified by package_key
    beneath node_id.  This proc makes sure that the instance_name (the
    name of the new node) is unique before invoking site_node::instantiate_and_mount.


    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-28

    @param instance_name The name to use for the url in the
    site-map. Defaults to the package_key plus a possible digit to
    serve as a unique identifier (e.g. news-2)

    @param pretty_name The english name to use for the site-map and
    for things like context bars. Defaults to the name of the object
    mounted at this node + the package pretty name (e.g. Intranet News)

    @param node_id Defaults to [ad_conn node_id]

    @see site_node::instantiate_and_mount

    @return The package id of the newly mounted package 

} {
    if { [empty_string_p $node_id] } {
	set node_id [ad_conn node_id]
    }

    set ctr 2
    if { [empty_string_p $instance_name] } {
	# Default the instance name to the package key. Add a number,
	# if necessary, until we find a unique name
	set instance_name $package_key
	while { [subsite::instance_name_exists_p $node_id $instance_name] } {
	    set instance_name "$package_key $ctr"
	    incr ctr
	}
	# Convert spaces to dashes
	regsub -all { } $instance_name "-" instance_name
    }

    if { [empty_string_p $pretty_name] } {
	# Get the name of the object mounted at this node
	db_1row select_package_object_names {
	    select t.pretty_name as package_name, acs_object.name(s.object_id) as object_name
	      from site_nodes s, apm_package_types t
	     where s.node_id = :node_id
	       and t.package_key = :package_key
	}
	set pretty_name "$object_name $package_name"
	if { $ctr > 2 } {	    
	    # This was a duplicate pkg name... append the ctr used in the instance name
	    append pretty_name " [expr $ctr - 1]"
	}
    }

    return [site_node::instantiate_and_mount -parent_node_id $node_id \
                                             -node_name $instance_name \
                                             -package_name $pretty_name \
                                             -package_key $package_key]
}


ad_proc -public subsite::get {
    {-subsite_id {}}
    {-array:required}
} {
    Get information about a subsite.

    @param subsite_id The id of the subsite for which info is requested.
    If no id is provided, then the id of the closest ancestor subsite will
    be used.
    @param array The name of an array in which information will be returned.

    @author Frank Nikolajsen (frank@warpspace.com)
    @creation-date 2003-03-08
} {
    upvar $array subsite_info

    if { [empty_string_p $subsite_id] } {
	set subsite_id [site_node_closest_ancestor_package "acs-subsite"]
    }

    array unset subsite_info
    array set subsite_info [site_node::get_from_object_id -object_id $subsite_id]
}

ad_proc -public subsite::get_element {
    {-subsite_id {}}
    {-element:required}
    {-notrailing:boolean}
} {
    Return a single element from the information about a subsite.

    @param subsite_id The node id of the subsite for which info is requested.
    If no id is provided, then the id of the closest ancestor subsite will
    be used.
    @param element The element you want, one of:
    directory_p object_type package_key package_id name pattern_p
    instance_name node_id parent_id url object_id
    @notrailing If true and the element requested is an url, then strip any
    trailing slash ('/'). This means the empty string is returned for the root.
    @return The element you asked for

    @author Frank Nikolajsen (frank@warpspace.com)
    @creation-date 2003-03-08
} {
    get -subsite_id $subsite_id -array subsite_info

    if { $notrailing_p && [string match $element "url"]} {
        set returnval [string trimright $subsite_info($element) "/"]
    } else {
	set returnval $subsite_info($element)
    }

    return $returnval
}


ad_proc subsite::util::sub_type_exists_p {
    object_type
} {
    returns 1 if object_type has sub types, or 0 otherwise

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 2000-02-07

    @param object_type

} {

    return [db_string sub_type_exists_p {
	select case 
                 when exists (select 1 from acs_object_types 
                              where supertype = :object_type)
                 then 1 
                 else 0 
               end
        from dual
    }]

}


ad_proc subsite::util::object_type_path_list {
    object_type
    {ancestor_type acs_object}
} {

} {
    set path_list [list]

    set type_list [db_list select_object_type_path {
	select object_type
	from acs_object_types
	start with object_type = :object_type
	connect by object_type = prior supertype
    }]

    foreach type $type_list {
	lappend path_list $type
	if {[string equal $type $ancestor_type]} {
	    break
	}
    }

    return $path_list

}

ad_proc subsite::util::object_type_pretty_name {
    object_type
} {
    returns pretty name of object.  We need this so often that I thought
    I'd stick it in a proc so it can possibly be cached later.

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 2000-02-07

    @param object_type
} {
    return [db_string select_pretty_name {
	select pretty_name from acs_object_types 
	where object_type = :object_type
    }]
}

ad_proc subsite::util::return_url_stack {
    return_url_list
} {
    Given a list of return_urls, we recursively encode them into one
    return_url that can be redirected to or passed into a page.  As long 
    as each page in the list does the typical redirect to return_url, then
    the page flow will go through each of the pages in $return_url_list
} {

    if {[llength $return_url_list] == 0} {
	error "subsite::util::return_url_stack - \$return_url_list is empty"
    }

    set first_url [lindex $return_url_list 0]
    set rest [lrange $return_url_list 1 end]

    # Base Case
    if {[llength $rest] == 0} {
	return $first_url
    }

    # More than 1 url was in the list, so recurse
    if {[string first ? $first_url] == -1} {
	append first_url ?
    }
    append first_url "&return_url=[ad_urlencode [return_url_stack $rest]]"

    return $first_url
}


ad_proc subsite::define_pageflow {
    {-sections_multirow "sections"}
    {-subsections_multirow "subsections"}
    {-section ""}
} {
    Defines the page flow of the subsite
} {
    set pageflow [get_pageflow_struct]
    
    # TODO: add an image
    # TODO: add link_p/selected_p for subsections

    set base_url [subsite::get_element -element url]

    template::multirow create $sections_multirow name label title url selected_p link_p

    template::multirow create $subsections_multirow name label title url selected_p link_p

    foreach { section_name section_spec } $pageflow {
        array set section_a {
            label {}
            url {}
            title {}
            subsections {}
            folder {}
            selected_patterns {}
        }

        array set section_a $section_spec
        set section_a(name) $section_name

        set selected_p [add_section_row \
                            -array section_a \
                            -base_url $base_url \
                            -multirow $sections_multirow]

        if { $selected_p } {
            foreach { subsection_name subsection_spec } $section_a(subsections) {
                array set subsection_a {
                    label {}
                    title {}
                    folder {}
                    url {}
                    selected_patterns {}
                }
                array set subsection_a $subsection_spec
                set subsection_a(name) $subsection_name
                set subsection_a(folder) [file join $section_a(folder) $subsection_a(folder)]

                add_section_row \
                    -array subsection_a \
                    -base_url $base_url \
                    -multirow $subsections_multirow
            }
        }
    }
}


ad_proc subsite::add_section_row {
    {-array:required}
    {-base_url:required}
    {-multirow:required}
    {-section {}}
} {
    upvar $array info

    # the folder index page is called .
    if { [string equal $info(url) ""] || [string equal $info(url) "index"] || \
             [string match "*/" $info(url)] || [string match "*/index" $info(url)] } {
        set info(url) "[string range $info(url) 0 [string last / $info(url)]]."
    }
    
    if { [ad_conn node_id] == [site_node_closest_ancestor_package "acs-subsite"] } {
        set current_url [ad_conn extra_url]
    } else {
        # Need to prepend the path from the subsite to this package
        set current_url [string range [ad_conn url] [string length $base_url] end]
    }
    if { [empty_string_p $current_url] || [string equal $current_url "index"] || \
             [string match "*/" $current_url] || [string match "*/index" $current_url] } {
        set current_url "[string range $current_url 0 [string last / $current_url]]."
    }
    
    set info(url) [file join $info(folder) $info(url)]

    # Default to not selected
    set selected_p 0
    
    if { [string equal $current_url $info(url)] || [string equal $info(name) $section] } {
        set selected_p 1
    } else {
        foreach pattern $info(selected_patterns) {
            set full_pattern [file join $info(folder) $pattern]
            if { [string match $full_pattern $current_url] } {
                set selected_p 1
                break
            }
        }
    }
    
    set link_p [expr ![string equal $current_url $info(url)]]
    
    template::multirow append $multirow \
        $info(name) \
        $info(label) \
        $info(title) \
        [file join $base_url $info(url)] \
        $selected_p \
        $link_p

    return $selected_p
}

ad_proc -public subsite::get_section_info {
    {-array "section_info"}
    {-sections_multirow "sections"}
} {
    upvar $array row
    # Find the label of the selected section

    array set row {
        label {}
        url {}
    }

    template::multirow foreach $sections_multirow {
        if { [template::util::is_true $selected_p] } {
            set row(label) $label
            set row(url) $url
            break
        }
    }
}

ad_proc subsite::get_pageflow_struct {} {
    # This is where the page flow structure is defined
    set subsections [list]
    lappend subsections home {
        label "Home"
        url ""
    }


    set pageflow [list]
    lappend pageflow home {
        label "Home"
        folder ""
        url ""
        selected_patterns {
            ""
            "subsites"
        }
    }

    set user_id [ad_conn user_id]
    set admin_p [permission::permission_p -object_id \
	    [site_node_closest_ancestor_package "acs-subsite"] -privilege admin]
    set show_member_list_to [parameter::get -parameter "ShowMembersListTo" -default 2]

    if { $admin_p || ($user_id != 0 && $show_member_list_to == 1) || \
	$show_member_list_to == 0 } {
	lappend pageflow members {
	    label "Members"
	    folder "members"
	    selected_patterns {*}
	}
    }


    set subsite_url [subsite::get_element -element url]
    array set subsite_sitenode [site_node::get -url $subsite_url]
    set subsite_node_id $subsite_sitenode(node_id)

    set child_urls [lsort -ascii [site_node::get_children -node_id $subsite_node_id -package_type apm_application]]

    foreach child_url $child_urls {
        array set child_node [site_node::get_from_url -exact -url $child_url]
        lappend pageflow $child_node(name) [list \
                                                label $child_node(instance_name) \
                                                folder $child_node(name) \
                                                url {} \
                                                selected_patterns *]
    }

    if { $admin_p } {
        lappend pageflow admin {
            label "Administration"
            url "admin/configure"
            selected_patterns {
                admin/*
                shared/parameters
            }
            subsections {
                configuration {
                    label "Configuration"
                    url "admin/configure"
                }
                applications {
                    label "Applications"
                    folder "admin/applications"
                    url ""
                    selected_patterns {
                        *
                    }
                }
                permissions {
                    label "Permissions"
                    url "admin/permissions"
                    selected_patterns {
                        permissions*
                    }
                }
                parameters {
                    label "Parameters"
                    url "shared/parameters"
                }
                advanced {
                    label "Advanced"
                    url "admin/."
                    selected_patterns {
                        site-map/*
                        groups/*
                        group-types/*
                        rel-segments/*
                        rel-types/*
                        host-node-map/*
                        object-types/*
                    }
                }
            }
        }
    }

    return $pageflow
}

ad_proc -public subsite::main_site_id {} {
    Get the package_id of the Main Site. The Main Site is the subsite
    that is always mounted at '/' and that has a number
    of site-wide parameter settings.

    @author Peter Marklund
} {
    array set main_node [site_node::get_from_url -url "/"]
    
    return $main_node(object_id)
}


ad_proc -public subsite::get_template_options {} {
    Gets options for subsite master template for use with a form builder select widget.
} {
    set master_template_options [list]
    lappend master_template_options [list "Default" "/www/default-master"]
    lappend master_template_options [list "Community" "/packages/acs-subsite/www/group-master"]
    set current_master [parameter::get -parameter DefaultMaster -package_id [ad_conn subsite_id]]
    set found_p 0
    foreach elm $master_template_options {
        if { [string equal $current_master [lindex $elm 1]] } {
            set found_p 1
            break
        }
    }
    if { !$found_p } {
        lappend master_template_options [list $current_master $current_master]
    }
    return $master_template_options
}
