# /packages/mbryzek-subsite/tcl/group-procs.tcl

ad_library {

    Procs to manage groups

    @author mbryzek@arsdigita.com
    @creation-date Thu Dec  7 18:13:56 2000
    @cvs-id $Id$

}


namespace eval group {}

ad_proc group::new { 
    { -form_id "" }
    { -variable_prefix "" }
    { -creation_user "" }
    { -creation_ip "" }
    { -group_id "" } 
    { -context_id "" } 
    { -group_name "" }
    {group_type "group"}
} {
    Creates a group of this type by calling the .new function for
    the package associated with the given group_type. This
    function will fail if there is no package.
    
    <p> 
    There are now several ways to create a group of a given
    type. You can use this TCL API with or without a form from the form
    system, or you can directly use the PL/SQL API for the group type.

    <p><b>Examples:</b>
    <pre>

    # OPTION 1: Create the group using the TCL Procedure. Useful if the
    # only attribute you need to specify is the group name
    
    db_transaction {
        set group_id [group::new -group_name "Author" $group_type]
    }
    
    
    # OPTION 2: Create the group using the TCL API with a templating
    # form. Useful when there are multiple attributes to specify for the
    # group
    
    template::form create add_group
    template::element create add_group group_name -value "Publisher"
    
    db_transaction {
        set group_id [group::new -form_id add_group $group_type ]
    }
    
    # OPTION 3: Create the group using the PL/SQL package automatically
    # created for it
    
    # creating the new group
    set group_id [db_exec_plsql add_group "
      begin
        :1 := ${group_type}.new (group_name => 'Editor');
      end;
    "]
    
    </pre>

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

    @return <code>group_id</code> of the newly created group

    @param form_id The form id from templating form system (see
    example above)

    @param group_name The name of this group. Note that if
    group_name is specified explicitly, this name will be used even if
    there is a group_name attribute in the form specified by
    <code>form_id</code>.

    @param group_type The type of group we are creating. Defaults to group
                      which is what you want in most cases.

    @param group_name The name of this group. This is a required
    variable, though it may be specified either explicitly or through
    <code>form_id</code>

} {

    # We select out the name of the primary key. Note that the
    # primary key is equivalent to group_id as this is a subtype of
    # acs_group
    	
    if { ![db_0or1row package_select {
        select t.package_name, lower(t.id_column) as id_column
          from acs_object_types t
         where t.object_type = :group_type
    }] } {
        error "Object type \"$group_type\" does not exist"
    }

    set var_list [list]
    lappend var_list [list context_id $context_id]
    lappend var_list [list $id_column $group_id]
    if { ![empty_string_p $group_name] } {
        lappend var_list [list group_name $group_name]
    }

    return [package_instantiate_object \
    	-creation_user $creation_user \
    	-creation_ip $creation_ip \
    	-package_name $package_name \
    	-start_with "group" \
    	-var_list $var_list \
    	-form_id $form_id \
    	-variable_prefix $variable_prefix \
    	$group_type]

}

ad_proc group::delete { group_id } {
    Deletes the group specified by group_id, including all
    relational segments specified for the group and any relational
    constraint that depends on this group in any way.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

    @return <code>object_type</code> of the deleted group, if it
            was actually deleted. Returns the empty string if the
            object didn't exist to begin with

    @param group_id The group to delete

} {
    if { ![db_0or1row package_select {
        select t.package_name, t.object_type
        from acs_object_types t
        where t.object_type = (select o.object_type 
                                 from acs_objects o 
                                where o.object_id = :group_id)
    }] } {
        # No package means the object doesn't exist. We're done :)
        return
    }

    # Maybe the relational constraint deletion should be moved to
    # the acs_group package...
    
    db_exec_plsql delete_group "
      BEGIN 
        -- the acs_group package takes care of segments referred
        -- to by rel_constraints.rel_segment. We delete the ones
        -- references by rel_constraints.required_rel_segment here.

        for row in (select cons.constraint_id
                      from rel_constraints cons, rel_segments segs
                     where segs.segment_id = cons.required_rel_segment
                       and segs.group_id = :group_id) loop

            rel_segment.del(row.constraint_id);

        end loop;

        -- delete the actual group
        ${package_name}.del(:group_id); 
      END;
    "

    return $object_type
}

ad_proc -public group::get {
    {-group_id:required}
    {-array:required}
} {
    Get basic info about a group: group_name, join_policy.
    
    @param array The name of an array in the caller's namespace where the info gets delivered.

    @see group::get_element
} {
    upvar 1 $array row
    db_1row group_info {
        select group_name, join_policy
        from   groups
        where  group_id = :group_id
    } -column_array row
}

ad_proc -public group::get_element {
    {-group_id:required}
    {-element:required}
} {
    Get an element from the basic info about a group: group_name, join_policy.

    @see group::get
} {
    group::get -group_id $group_id -array row
    return $row($element)
}

ad_proc -public group::permission_p { 
    { -user_id "" }
    { -privilege "read" }
    group_id
} {
    THIS PROC SHOULD GO AWAY! All calls to group::permission_p can be 
    replaced with party::permission_p

    Wrapper for ad_permission to allow us to bypass having to
    specify the read privilege

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

} {
    return [party::permission_p -user_id $user_id -privilege $privilege $group_id]
}

ad_proc -public group::join_policy {
    {-group_id:required}
} {
    Returns a group's join policy ('open', 'closed', or 'needs approval')

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 10/2000

} {
    return [db_string select_join_policy {
        select join_policy from groups where group_id = :group_id
    }]
}

ad_proc -public group::update {
    {-group_id:required}
    {-array:required}
} {
    Updates a group.
    
    @param group_id The ID of the group to update.

    @param array    Name of array containing the columns to update.
                    Valid columns are group_name, join_policy. 
                    Valid join_policy values are 'open', 'closed', 'needs approval'.

} {
    upvar $array row
    
    # Construct clauses for the update statement
    set columns { group_name join_policy }
    set set_clauses [list]
    foreach name [array names row] {
        if { [lsearch -exact $columns $name] == -1 } {
            error "Attribute '$name' isn't valid for groups."
        }
        lappend set_clauses "$name = :$name"
        set $name $row($name)
    }

    if { [llength $set_clauses] == 0 } {
        # No rows to update
        return
    }

    db_dml update_group "
        update groups
        set    [join $set_clauses ", "]
        where  group_id = :group_id
    "
}

ad_proc -public group::possible_member_states {} {
    Returns the list of possible member states: approved, needs approval, banned, rejected, deleted.
} {
    return [list approved "needs approval" banned rejected deleted]
}

ad_proc -public group::get_member_state_pretty {
    {-member_state:required}
} {
    Returns the pretty-name of a member state.
} {
    array set message_key_array {
        approved #acs-kernel.member_state_approved#
        "needs approval" #acs-kernel.member_state_needs_approval#
        banned #acs-kernel.member_state_banned#
        rejected #acs-kernel.member_state_rejected#
        deleted #acs-kernel.member_state_deleted#
    }

    return [lang::util::localize $message_key_array($member_state)]
}

ad_proc -public group::get_join_policy_options {} {
    Returns a list of valid join policies in a format suitable for a form builder drop-down.
} {
    return [list \
                [list [_ acs-kernel.common_open] "open"] \
                [list [_ acs-kernel.common_needs_approval] "needs approval"] \
                [list [_ acs-kernel.common_closed] "closed"]]
}

ad_proc -public group::default_member_state {
    { -join_policy "" }
    { -create_p "" }
    -no_complain:boolean
} {
    If user has 'create' privilege on group_id OR 
       the group's join policy is 'open', 
    then default_member_state will return "approved".  

    If the group's join policy is 'needs approval'
    then default_member_state will return 'needs approval'.

    If the group's join policy is closed
    then an error will be thrown, unless the no_complain flag is
    set, in which case empty string is returned.

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 10/2000
    
    @param join_policy - the group's join policy 
                         (one of 'open', 'closed', or 'needs approval')

    @param create_p - 1 if the user has 'create' privilege on the group, 
                      0 otherwise.
} {
    if {$create_p || [string equal $join_policy open]} {
        return "approved"
    }

    if {[string equal $join_policy "needs approval"]} {
        return "needs approval"
    }

    if {$no_complain_p} {
        error "group::default_member_state - user is not a group admin and join policy is $join_policy."
    }

    return ""
}


ad_proc -public group::member_p {
    { -user_id "" }
    { -group_name "" }
    { -group_id "" }
    -cascade:boolean
} {
    Return 1 if the user is a member of the group specified.
    You can specify a group name or group id.
    If cascade is true, check to see if the user is
    a member of the group by virtue of any other component group.
    (e.g. if group B is a component of group A then if a user
     is a member of group B then he is automatically a member of A
     also.)
    If cascade is false, then the user must have specifically
    been granted membership on the group in question.
} {
    if { [empty_string_p $user_id] } {
	set user_id [ad_conn user_id]
    }

    if { [empty_string_p $group_name] && [empty_string_p $group_id] } {
	return 0
    }

    if { ![empty_string_p $group_name] } {
	set group_id [db_string group_id_from_name {} -default {}]
	if { [empty_string_p $group_id] } {
	    return 0
	}
    }

    set cascade [db_boolean $cascade_p]
    set result [db_string user_is_member {} -default "f"]
    
    return [template::util::is_true $result]
}


ad_proc -public group::get_rel_types_options {
    {-group_id:required}
    {-object_type "person"}
} {
    Get the valid relationship-types for this group in a format suitable for a select widget in the form builder.
    The label used is the name of the role for object two.

    @param group_id The ID of the group for which to get options.

    @param object_type The object type which must occupy side two of the relationship. Typically 'person' or 'group'.
    
    @return a list of lists with label (role two pretty name) and ID (rel_type)
} {
    # LARS:
    # The query has a hack to make sure 'membership_rel' appears before all other rel types
    set rel_types [list]
    db_foreach select_rel_types {} {
        # Localize the name
        lappend rel_types [list [lang::util::localize $pretty_name] $rel_type]
    }
    return $rel_types
}

ad_proc -public group::admin_p {
    {-group_id:required}
    {-user_id:required}
} {
    set admin_rel_id [relation::get_id \
                          -object_id_one $group_id \
                          -object_id_two $user_id \
                          -rel_type "admin_rel"]

    # The party is an admin if the call above returned something non-empty
    return [expr ![empty_string_p $admin_rel_id]]
}


ad_proc -public group::add_member {
    {-group_id:required}
    {-user_id:required}
    {-rel_type ""}
    {-member_state ""}
} {
    Adds a user to a group, checking that the rel_type is permissible given the user's privileges, 
    Can default both the rel_type and the member_state to their relevant values.
} {       
    set admin_p [permission::permission_p -object_id $group_id -privilege "admin"]
    
    # Only admins can add non-membership_rel members
    if { [empty_string_p $rel_type] || \
             (![empty_string_p $rel_type] && ![string equal $rel_type "membership_rel"] && \
                  ![permission::permission_p -object_id $group_id -privilege "admin"]) } {
        set rel_type "membership_rel"
    }
    
    group::get -group_id $group_id -array group
    set create_p [group::permission_p -privilege create $group_id]
    
    if { [string equal $group(join_policy) "closed"] && !$create_p } {
        error "You do not have permission to add members to the group '$group(group_name)'"
    }

    if { [empty_string_p $member_state] } {
        set member_state [group::default_member_state \
                              -join_policy $group(join_policy) \
                              -create_p $create_p]
    }
    
    relation_add -member_state $member_state $rel_type $group_id $user_id
}
