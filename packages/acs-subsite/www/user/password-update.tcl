ad_page_contract {
    Let's the user change his/her password.  Asks
    for old password, new password, and confirmation.
    
    @cvs-id $Id$
} {
    {user_id {[ad_conn untrusted_user_id]}}
    {return_url ""}
    {old_password ""}
}
# This is a bit confusing, but old_password is what we get passed in here,
# whereas password_old is the form element.


# Redirect to HTTPS if so configured
if { [security::RestrictLoginToSSLP] } {
    security::require_secure_conn
}

if { ![empty_string_p $old_password] } {
    # If old_password is set, this is a user who has had his password recovered,
    # so they won't be authenticated yet.
} else {
    set level [ad_decode [security::RestrictLoginToSSLP] 1 "secure" "ok"]

    # If the user is changing passwords for another user, they need to be account ok
    set account_status [ad_decode $user_id [ad_conn untrusted_user_id] "closed" "ok"]

    auth::require_login \
        -level $level \
        -account_status $account_status
}


if { ![auth::password::can_change_p -user_id $user_id] } {
    ad_return_error "Not supported" "Changing password is not supported."
}

set admin_p [permission::permission_p -object_id $user_id -privilege admin]

if { !$admin_p } {
    permission::require_permission -party_id $user_id -object_id $user_id -privilege write
}



set page_title [_ acs-subsite.Update_Password]
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

set system_name [ad_system_name]
set site_link [ad_site_home_link]



acs_user::get -user_id $user_id -array user

ad_form -name update -edit_buttons [list [list [_ acs-kernel.common_update] "ok"]] -form {
    {user_id:integer(hidden)}
    {return_url:text(hidden),optional}
    {old_password:text(hidden),optional}
}

if { [exists_and_not_null old_password] } {
    set focus "update.password_1"
} else {
    ad_form -extend -name update -form {
        {password_old:text(password)
            {label {[_ acs-subsite.Current_Password]}}
        }
    }
    set focus "update.password_old"
}

ad_form -extend -name update -form {
    {password_1:text(password)
        {label {[_ acs-subsite.New_Password]}}
        {html {size 20}}
    }
    {password_2:text(password)
        {label {[_ acs-subsite.Confirm]}}
        {html {size 20}}
    }
} -on_request {
    
} -validate {
    {password_1
        { [string equal $password_1 $password_2] }
        { Passwords don't match }
    }
} -on_submit {
    
    if { [exists_and_not_null old_password] } {
        set password_old $old_password
    }
    
    array set result [auth::password::change \
                          -user_id $user_id \
                          -old_password $password_old \
                          -new_password $password_1]
    
    switch $result(password_status) {
        ok {
            # Continue
        }
        old_password_bad {
            if { ![exists_and_not_null old_password] } {
                form set_error update password_old $result(password_message)
            } else {
                # This hack causes the form to reload as if submitted, but with the old password showing
                ad_returnredirect [export_vars -base [ad_conn url] -entire_form -exclude { old_password } -override { { password_old $old_password } }]
                ad_script_abort
            }
            break
        }
        default {
            form set_error update password_1 $result(password_message)
            break
        }
    }

    # If the account was closed, it might be open now
    if { [string equal [ad_conn account_status] "closed"] } {
        auth::verify_account_status
    }
    
} -after_submit {
    if { [empty_string_p $return_url] } {
        set return_url [ad_pvt_home]
        set continue_label "Return to [ad_pvt_home_name]"
    } else {
        set continue_label "Continue"
    }
    set message "You have successfully chosen a new Password."
    set continue_url $return_url

    ad_return_template /packages/acs-subsite/www/register/display-message
}
