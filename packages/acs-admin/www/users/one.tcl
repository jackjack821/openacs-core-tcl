ad_page_contract {
    One user view by an admin
    rewritten by philg@mit.edu on October 31, 1999
    makes heavy use of procedures in /tcl/ad-user-contributions-summary.tcl
    modified by mobin January 27, 2000 5:08 am
    
    @cvs-id $Id$
} {
    user_id
} -properties {
    context:onevalue
    first_names:onevalue
    last_name:onevalue
    email:onevalue
    screen_name:onevalue
    user_id:onevalue
    registration_date:onevalue
    last_date:onevalue
    last_visit:onevalue
    export_edit_vars:onevalue
    portrait_p:onevalue
    portrait_title:onevalue
    user_finite_state_links:onevalue
}

if ![db_0or1row user_info "select first_names, last_name, email, coalesce(screen_name,'&lt none set up &gt') as screen_name, creation_date, creation_ip, last_visit, member_state, email_verified_p, url
from cc_users
where user_id = :user_id"] {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was deleted?"
    return
}

#
# RBM: Check if the requested user is a site-wide admin and warn the 
# viewer in that case (so that a ban/deletion can be avoided).
#

set site_wide_admin_p [acs_user::site_wide_admin_p -user_id $user_id]
set warning_p 0

if { $site_wide_admin_p } {
    set warning_p 1
}

set public_link [acs_community_member_url -user_id $user_id]
set sec_context_root [acs_magic_object "security_context_root"] 
if [db_0or1row user_is_admin "select privilege from acs_permissions where object_id = :sec_context_root and grantee_id = :user_id and privilege = 'admin'"] {
    set admin_p 1
} else {
    set admin_p 0
}

set return_url "/acs-admin/users/one?user_id=$user_id"

set context [list [list "./" "Users"] "One User"]
set export_edit_vars [export_url_vars user_id return_url]
set registration_date [util_AnsiDatetoPrettyDate $creation_date] 

set portrait_p 0
if {[db_0or1row get_item_id "select live_revision as revision_id, nvl(title,'view this portrait') portrait_title
from acs_rels a, cr_items c, cr_revisions cr 
where a.object_id_two = c.item_id
and c.live_revision = cr.revision_id
and a.object_id_one = :user_id
and a.rel_type = 'user_portrait_rel'"]} {
    set portrait_p 1
}

set user_finite_state_links "([join [ad_registration_finite_state_machine_admin_links $member_state $email_verified_p $user_id] " | "])"


# XXX Make sure to make the following into links and this looks okay

db_multirow user_contributions  user_contributions "select at.pretty_name, at.pretty_plural, a.creation_date, acs_object.name(a.object_id) object_name
from acs_objects a, acs_object_types at
where a.object_type = at.object_type
and a.creation_user = :user_id
order by object_name, creation_date"

# cro@ncacasi.org 2002-02-20 
# Boy is this query wacked, but I think I am starting to understand
# how this groups thing works.
# Find out which groups this user belongs to where he was added to the group
# directly (e.g. his membership is not by virtue of the group being
# a component of another group).
db_multirow direct_group_membership direct_group_membership "
  select group_id, rel_id, party_names.party_name as group_name
    from (select /*+ ORDERED */ DISTINCT rels.rel_id, object_id_one as group_id, 
                 object_id_two
            from acs_rels rels, all_object_party_privilege_map perm
           where perm.object_id = rels.rel_id
                 and perm.privilege = 'read'
                 and rels.rel_type = 'membership_rel'
                 and rels.object_id_two = :user_id) r, 
         party_names 
   where r.group_id = party_names.party_id
order by lower(party_names.party_name)"

# And also get the list of all groups he is a member of, direct or
# inherited.
db_multirow all_group_membership all_group_membership "
  select groups.group_id, groups.group_name
     from groups, group_member_map gm
     where groups.group_id = gm.group_id and gm.member_id=:user_id
  order by lower(groups.group_name)"


ad_return_template



# The code from below is from pre-ACS 4.0 and should be revised for entry later

# it looks like we should be doing 0or1row but actually
# we might be in an ACS installation where users_demographics
# isn't used at all

#  set contact_info [ad_user_contact_info $user_id "site_admin"]

#  if ![empty_string_p $contact_info] {
#      append whole_page "<h3>Contact Info</h3>\n\n$contact_info\n
#  <ul>
#  <li><a href=contact-edit?[export_url_vars user_id]>Edit contact information</a>
#  </ul>"
#  } else {
#      append whole_page "<h3>Contact Info</h3>\n\n$contact_info\n
#  <ul>
#  <li><a href=contact-edit?[export_url_vars user_id]>Add contact information</a>
#  </ul>"
#  }

#  if [db_table_exists users_demographics] {
#      if [db_0or1row user_demographics "select 
#      ud.*,
#      u.first_names as referring_user_first_names,
#      u.last_name as referring_user_last_name
#      from users_demographics ud, users u
#      where ud.user_id = $user_id
#      and ud.referred_by = u.user_id(+)"] {
#  	# the table exists and there is a row for this user
#  	set demographic_items ""
#  	for {set i 0} {$i<[ns_set size $selection]} {incr i} {
#  	    set varname [ns_set key $selection $i]
#  	    set varvalue [ns_set value $selection $i]
#  	    if { $varname != "user_id" && ![empty_string_p $varvalue] } {
#  		append demographic_items "<li>$varname: $varvalue\n"
#  	    }
#  	}
#  	if ![empty_string_p $demographic_items] {
#  	    append whole_page "<h3>Demographics</h3>\n\n<ul>$demographic_items</ul>\n"
	    
#  	}
#      }
#  }

#  if {[db_table_exists categories] && [db_table_exists users_interests]} {
#      set category_items ""
#      db_foreach users_interests "select c.category 
#      from categories c, users_interests ui 
#      where ui.user_id = $user_id
#      and c.category_id = ui.category_id" {
#  	append category_items "<LI>$category\n"
#      }

#      if ![empty_string_p $category_items] {
#  	append whole_page "<H3>Interests</H3>\n\n<ul>\n\n$category_items\n\n</ul>"
#      }
#  }

#  # randyg is brilliant! we can recycle the same handle here because the
#  # inner argument is evaluated before the outer one. this should actually
#  # be done with the db api. 12 june 00, richardl@arsdigita.com

#  if { [im_enabled_p] && [ad_user_group_member $db [im_employee_group_id] $user_id] } {
#      # We are running an intranet enabled acs and this user is a member of the 
#      # employees group. Offer a link to the employee administration page
#      set intranet_admin_link "<li><a href=\"[im_url_stub]/employees/admin/view?[export_url_vars user_id]\">Update this user's employee information</a><p>"
#  } else {
#      set intranet_admin_link ""
#  }

