ad_page_contract {			# 
    Merge two users accounts

    TODO: Support to merge more than two accounts at the same time

    @cvs-id $Id$
} {
    user_id
    user_id_from_search
} -properties {
    context:onevalue
    first_names:onevalue
    last_name:onevalue
} -validate {
    if_the_logged_in_user_is_crazy {
	# Just for security reasons...
	set current_user_id [ad_conn user_id]
	if { [string equal $current_user_id $user_id] || [string equal $current_user_id $user_id_from_search] } {
	    ad_complain "You can't merge yourself"
	}
    }
}

set context [list [list "./" "Merge"] "Merge"]

#
# Information of user_id_one
#
if { [db_0or1row one_user_portrait { *SQL* }] } {
    set one_img_src "[subsite::get_element -element url]shared/portrait-bits.tcl?user_id=$user_id"
} else {
    set one_img_src "/resources/acs-admin/not_available.gif"
}

db_1row one_get_info { *SQL* }

db_multirow -extend {one_item_object_url} one_user_contributions one_user_contributions { *SQL* } {
    set one_item_object_url  "[site_node::get_url_from_object_id $object_id]"
}

set user_id_one_items [callback MergeShowUserInfo -user_id $user_id ]
if { ![empty_string_p $user_id_one_items] } {
    set user_id_one_items_html "<ul><li>User Items<ul>"
    foreach item $user_id_one_items {
	append user_one_items_html "<li>$item</li>"
    }
    append user_id_one_items_html "</ul></li></ul>"
} else {
    set user_id_one_items_html ""
}

#
# Information of user_id_two
#
if { [db_0or1row two_user_portrait { *SQL* }] } {
    set two_img_src "[subsite::get_element -element url]shared/portrait-bits.tcl?user_id=$user_id_from_search"
} else {
    set two_img_src "/resources/acs-admin/not_available.gif"
}

db_1row two_get_info { *SQL* }

db_multirow -extend {two_item_object_url} two_user_contributions two_user_contributions { *SQL* } {
    set two_item_object_url "[site_node::get_url_from_object_id $object_id]"
}

set user_id_two_items [callback MergeShowUserInfo -user_id $user_id_from_search ]
if { ![empty_string_p $user_id_two_items] } {
    set user_id_two_items_html "<ul><li>User Items<ul>"
    foreach item $user_id_two_items {
	append user_two_items_html "<li>$item</li>"
    }
    append user_id_two_items_html "</ul></li></ul>"
} else {
    set user_id_two_items_html ""
}

