# /packages/mbryzek-subsite/tcl/relation-procs.tcl

ad_library {

    Helpers for dealing with relations

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 16:46:11 2000
    @cvs-id $Id$

}

ad_proc -public relation_permission_p {
    { -user_id "" }
    { -privilege "read" }
    rel_id
} {
    Wrapper for ad_permission_p that lets us default to read permission

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

} {
    return [ad_permission_p -user_id $user_id $rel_id $privilege]
}


ad_proc -public relation_add {
    { -form_id "" }
    { -extra_vars "" }
    { -variable_prefix "" }
    { -creation_user "" }
    { -creation_ip "" }
    { -member_state "" }
    rel_type
    object_id_one
    object_id_two
} {
    Creates a new relation of the specified type between the two
    objects. Throws an error if the new relation violates a relational
    constraint.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @author Ben Adida (ben@openforce.net)
    @creation-date 1/5/2001

    @param form_id         The form id from templating form system

    @param extra_vars      An ns_set of extra variables

    @param variable_prefix Only form elements that begin with the 
                           specified prefix will be processed.

    @param creation_user   The user who is creating the relation

    @param creation_ip

    @param member_state    Only used for membership_relations.
                           See column membership_rels.member_state 
                           for more info.

    @return The <code>rel_id</code> of the new relation

} {
    set var_list [list \
	    [list object_id_one $object_id_one] \
	    [list object_id_two $object_id_two]]

    # Note that we don't explicitly check whether rel_type is a type of 
    # membership relation before adding the member_state variable.  The 
    # package_instantiate_object proc will ignore the member_state variable
    # if the rel_type's plsql package doesn't support it.
    if {![empty_string_p $member_state]} {
	lappend var_list [list member_state $member_state]
    }

    # We use db_transaction inside this proc to roll back the insert
    # in case of a violation

    db_transaction {

	set rel_id [package_instantiate_object \
		-creation_user $creation_user \
		-creation_ip $creation_ip \
		-start_with "relationship" \
		-form_id $form_id \
		-extra_vars $extra_vars \
		-variable_prefix $variable_prefix \
		-var_list $var_list \
		$rel_type]

	# Check to see if constraints are violated because of this new
	# relation
	set violated_err_msg [db_string select_rel_violation {
	    select rel_constraint.violation(:rel_id) from dual
	} -default ""]

	if { ![empty_string_p $violated_err_msg] } {
	    error $violated_err_msg
	}
    } on_error {
	return -code error $errmsg
    }

    return $rel_id

}


ad_proc -public relation_remove {
    rel_id
} {
    Removes the specified relation. Throws an error if we violate a
    relational constraint by removing this relation.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 1/5/2001

    @return 1 if we delete anything. 0 otherwise (e.g. when the
              relation was already deleted)

} {

    # Pull out the segment_id and the party_id (object_id_two) from
    # acs_rels. Note the outer joins since the segment may not exist.
    if { ![db_0or1row select_rel_info {}] } {
        # Relation doesn't exist
	return 0
    }

    # Check if we would violate some constraint by removing this relation.
    # This query basically says: Does there exist a segment, to which
    # this party is an element (with any relationship type), that
    # depends on this party being in this segment? That's tough to
    # parse. Another way to say the same things is: Is there some constraint
    # that requires this segment? If so, is the user a member of the segment
    # on which that constraint is defined? If so, we cannot remove this
    # relation. Note that this segment is defined by joining against
    # acs_rels to find the group and rel_type for this relation.

    if { ![empty_string_p $segment_id] } {
	if { [relation_segment_has_dependant -segment_id $segment_id -party_id $party_id] } {
	    error "Relational constraints violated by removing this relation"
	}
    }

    db_exec_plsql relation_delete "begin ${package_name}.delete(:rel_id); end;"

    return 1
}



ad_proc -public relation_segment_has_dependant {
    { -rel_id "" }
    { -segment_id "" }
    { -party_id "" }
} {
    Returns 1 if the specified segment/party combination has a
    dependant (meaning a constraint would be violated if we removed this
    relation). 0 otherwise. Either <code>rel_id</code> or
    <code>segment_id</code> and <code>party_id</code> must be
    specified. <code>rel_id</code> takes precedence.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

} {

    if { ![empty_string_p $rel_id] } {
	if { ![db_0or1row select_rel_info {}] } {
	    # There is either no relation or no segment... thus no dependants
	    return 0
	}
    }

    if { [empty_string_p $segment_id] || [empty_string_p $party_id] } {
	error "Both of segment_id and party_id must be specified in call to relation_segment_has_dependant"
    }

    return [db_string others_depend_p {}]
}


ad_proc -public relation_type_is_valid_to_group_p {
    { -group_id "" }
    rel_type
} {
    Returns 1 if group $group_id allows elements through a relation of 
    type $rel_type, or 0 otherwise.

    If there are no relational constraints that prevent $group_id from being
    on side one of a relation of type $rel_type, then 1 is returned.

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 2000-02-07
    
    @param group_id - if unspecified, then we use
                      [application_group::group_id_from_package_id]
    @param rel_type
} {
    if {[empty_string_p $group_id]} {
	set group_id [application_group::group_id_from_package_id]
    }

    return [db_string rel_type_valid_p {}]
    
}


ad_proc relation_types_valid_to_group_multirow {
    {-datasource_name object_types}
    {-start_with acs_rel}
    {-group_id ""}
} {
    creates multirow datasource containing relationship types starting with
    the $start_with relationship type.  The datasource has columns that are 
    identical to the party::types_allowed_in_group_multirow, which is why
    the columns are broadly named "object_*" instead of "rel_*".  A common
    template can be used for generating select widgets etc. for both
    this datasource and the party::types_allowed_in_groups_multirow datasource.

    All subtypes of $start_with are returned, but the "valid_p" column in the
    datasource indicates whether the type is a valid one for $group_id.

    If -group_id is not specified or is specified null, then the current
    application_group will be used 
    (determined from [application_group::group_id_from_package_id]).

    Includes fields that are useful for
    presentation in a hierarchical select widget:
    <ul>
    <li> object_type
    <li> object_type_enc - encoded object type
    <li> indent          - an html indentation string
    <li> pretty_name     - pretty name of object type
    </ul>

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 2000-02-07
    
    @param datasource_name
    @param start_with
    @param group_id - if unspecified, then 
                      [applcation_group::group_id_from_package_id] is used.
} {

    if {[empty_string_p $group_id]} {
	set group_id [application_group::group_id_from_package_id]
    }

    template::multirow create $datasource_name \
	    object_type object_type_enc indent pretty_name valid_p

    db_foreach select_sub_rel_types {} {
	template::multirow append $datasource_name $object_type [ad_urlencode $object_type] $indent $pretty_name $valid_p
    }

}


ad_proc -public relation_required_segments_multirow {
    { -datasource_name "" }
    { -group_id "" }
    { -rel_type "membership_rel" }
    { -rel_side "two" }
} {
    Sets up a multirow datasource.
    Also returns a list containing the most essential information.
} {
    if {[empty_string_p $group_id]} {
	set group_id [application_group::group_id_from_package_id]
    }

    template::multirow create $datasource_name \
	    segment_id group_id rel_type rel_type_enc \
	    rel_type_pretty_name group_name join_policy


    set group_rel_type_list [list]

    db_foreach select_required_rel_segments {} {
	template::multirow append $datasource_name $segment_id $group_id $rel_type [ad_urlencode $rel_type] $rel_type_pretty_name $group_name $join_policy

	lappend group_rel_type_list [list $group_id $rel_type]
    }
    return $group_rel_type_list
}
