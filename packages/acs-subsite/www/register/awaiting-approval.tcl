ad_page_contract {
    @cvs-id $Id$
} {
    user_id:integer
} -properties {
    system_name:onevalue
}
 
set bind_vars [ad_tcl_vars_to_ns_set user_id]

if {![db_0or1row register_member_state_information "select member_state, email, email_verified_p, rel_id
from cc_users where user_id = :user_id 
and  (member_state is null or member_state = 'rejected' or member_state = 'needs approval')"]} {
    ad_return_error "[_ acs-subsite.lt_Couldnt_find_your_rec]" "[_ acs-subsite.lt_User_id_user_id_is_no]"
    return
}


if {![ad_parameter RegistrationRequiresApprovalP "security" 0]} {
    # we are not using the "approval" system
    # they should not be in this state

    db_dml register_member_state_authorized_set "update membership_rels set member_state = 'approved' where rel_id = :rel_id"

    if {$email_verified_p == "t"} {
	# we don't require email verification
        ad_returnredirect "index?[export_url_vars email]"
        ad_script_abort
    } else {
        ad_returnredirect "awaiting-email-verification?[export_url_vars user_id]"
        ad_script_abort
    }

    # try to login again with this new state
}

set system_name [ad_system_name]
