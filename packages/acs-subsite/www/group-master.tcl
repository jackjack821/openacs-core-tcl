# Expects properties:
#   title
#   focus
#   header_stuff
#   section

if { ![info exists section] } {
    set section {}
}

if { ![info exists header_stuff] } {
    set header_stuff {}
}

# This will set 'sections' and 'subsections' multirows
subsite::define_pageflow -section $section
subsite::get_section_info -array section_info

# Find the subsite we belong to
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)
set subsite_name $subsite_sitenode(instance_name)

# Where to find the stylesheet
set css_url "/resoources/acs-subsite/group-master.css"

# Context bar
if { [template::util::is_nil no_context_p] } {
    if { ![template::util::is_nil context] } {
        set context_bar [eval ad_context_bar -from_node $subsite_node_id $context]
    }
    if [template::util::is_nil context_bar] { 
        set context_bar [ad_context_bar -from_node $subsite_node_id]
    }
} else {
    set context_bar {}
}

