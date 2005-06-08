ad_page_contract {
    Merge two users accounts

    TODO: Support to merge more than two accounts at the same time

    @cvs-id $Id$
} {
    to_user_id:integer
    from_user_id:integer
    merge_p
} -properties {
    context:onevalue
} -validate {
    if_diff_authority {
	set from_authority_id [db_string gettoa "select authority_id from cc_users where user_id = :from_user_id"]
	set to_authority_id [db_string getfroma "select authority_id from cc_users where user_id = :to_user_id"]
	if { ![string equal $from_authority_id $to_authority_id] } {
	    ad_complain "Merge only works for users of the same authority"
	} 
    }
    if_the_logged_in_user_is_crazy {
	# Just for security reasons...
	set current_user_id [ad_conn user_id]
	if { [string equal $current_user_id $to_user_id] || [string equal $current_user_id $from_user_id] } {
	    ad_complain "You can't merge yourself"
	}
    }
}

set context [list [list "./" "Merge"] "Merge"]

if { !$merge_p } {
    ad_returnredirect "/acs-admin/users"
} else {
    set final_results [callback MergePackageUser -from_user_id $from_user_id -to_user_id $to_user_id]

    set temp "<ul>"
    foreach res $final_results {
	append temp "<li>$res</li>"
    }

    set impl_id [auth::authority::get_element -authority_id $to_authority_id -element "auth_impl_id"]
    set parameters [list $from_user_id $to_user_id $to_authority_id]
    set user_res [acs_sc::invoke \
		      -error \
		      -contract "auth_authentication" \
		      -impl_id $impl_id \
		      -operation MergeUser \
		      -call_args $parameters]


    foreach item $user_res {
	append temp "<li>$item</li>"
    }

    append temp "</ul>"

    set msg "Merge is done"
    ns_log Notice $msg
}

