ad_page_contract {
    Add a new user to the system, if the email doesn't already exist.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
} {
    email
}

auth::require_login

set group_id [application_group::group_id_from_package_id]

set admin_p [permission::permission_p -object_id $group_id -privilege "admin"]

if { !$admin_p } {
    # If not admin, user must be member of group, and members must be allowed to invite other members
    if { ![parameter::get -parameter "MembersCanInviteMembersP" -default 0] || \
             ![group::member_p -group_id $group_id] } {
        
        ad_return_forbidden "Cannot invite members" "I'm sorry, but you're not allowed to invite members to this group"
        ad_script_abort
    }
}

set page_title "Inivite Member to [ad_conn instance_name]"
set context [list [list "." "Members"] "Invite"]


# Check if email is already known on the system
set party_id [db_string select_party { select party_id from parties where lower(email) = lower(:email) } -default {}]

if { ![empty_string_p $party_id] } {
    # Yes, is it a user?
    set user_id [db_string select_user { select user_id from users where user_id = :party_id } -default {}]

    if { [empty_string_p $user_id] } {
        # This is a party, but it's not a user

        acs_object_type::get -object_type [acs_object_type $party_id] -array object_type
        # TODO: Move this to the form, by moving the form to an include template
        ad_return_complaint 1 "<li>This email belongs to a $object_type(pretty_name) on the system. We cannot create a new user with this email."
        ad_script_abort
    } else {
        # Already a user, but not a member of this subsite, and may not be a member of the main site (registered users)

        # We need to know if we're on the main site below
        set main_site_p [string equal [site_node::get_url -node_id [ad_conn node_id]] "/"]
        
        # Check to see if the user is a member of the main site (registered user)
        set registered_user_id [db_string select_user { select user_id from cc_users where user_id = :party_id } -default {}]

        if { [empty_string_p $registered_user_id] } {
            # User exists, but is not member of main site. Requires SW-admin to remedy.
            if { [acs_user::site_wide_admin_p] } {
                set main_site_id [site_node::get_element -url / -element object_id]
                group::add_member \
                    -group_id [application_group::group_id_from_package_id -package_id $main_site_id] \
                    -user_id $party_id
            } else {
                # TODO: Move this to the form, by moving the form to an include template
                ad_return_complaint 1 "<li>User has an acccount on the system, but has been removed from the main site. Only a site-wide administrator can re-add the user."
                ad_script_abort
            }
        }

        # The user is now a registered user (member of main site)
        if { $main_site_p } {
            # Already a member.
        } else {
            group::add_member \
                -group_id $group_id \
                -user_id $party_id
        }
    }
    ad_returnredirect .
    ad_script_abort
}
