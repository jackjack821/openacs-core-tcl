# /packages/mbryzek-subsite/tcl/group-procs.tcl

ad_library {

    Procs to manage groups

    @author mbryzek@arsdigita.com
    @creation-date Thu Dec  7 18:13:56 2000
    @cvs-id $Id$

}


namespace eval group {

    ad_proc new { 
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

    ad_proc delete { group_id } {
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

                rel_segment.delete(row.constraint_id);

            end loop;

	    -- delete the actual group
	    ${package_name}.delete(:group_id); 
	  END;
        "

	return $object_type
    }


    ad_proc -public permission_p { 
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

    ad_proc -public join_policy {
	{ -group_id "" }
    } {
	Returns a group's join policy ('open', 'closed', or 'needs approval')

	@author Oumi Mehrotra (oumi@arsdigita.com)
	@creation-date 10/2000

    } {

	set join_policy [db_string select_join_policy {
	    select join_policy from groups where group_id = :group_id
	}]

    }

    ad_proc -public possible_member_states {

    } {

    } {
	return [list approved "needs approval" banned rejected deleted]
    }

    ad_proc -public default_member_state {
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


    ad_proc -public member_p {
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

    if {[empty_string_p $user_id]} {
	set user_id [ad_verify_and_get_user_id]
    }

    if {[empty_string_p $group_name] && [empty_string_p $group_id]} {
	return 0
    }

    if {$cascade_p} {
	set cascade t
    } else {
	set cascade f
    }
    

    if {![empty_string_p $group_name]} {
	set group_id [db_string group_id_from_name "
	  select group_id from groups where group_name=:group_name" -default ""]
	if {[empty_string_p $group_id]} {
	    return 0
	}
    }

    set result [db_string user_is_member "
	  select acs_group.member_p(:user_id,:group_id, :cascade) 
            from dual" -default "f"]

    if { [string equal $result "f"] } { return 0 }
    if { [string equal $result "t"] } { return 1 }
}
}


