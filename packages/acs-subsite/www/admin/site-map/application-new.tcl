ad_page_contract {
    Create and mount a new application.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-05-28
    @cvs-id $Id$
}

set page_title "New Application"
set context [list [list "." "Site Map"] $page_title]

set packages [db_list_of_lists package_types {}]

ad_form -name application -cancel_url . -form {
    {package_key:text(select)
        {label "Application"}
        {options $packages}
        {help_text "The type of application you want to add."}
    }
    {instance_name:text
        {label "Application name"}
        {help_text "The human-readable name of your application."}
        {html {size 50}}
    }
    {folder:text,optional
        {label "URL folder name"}
        {help_text "This should be a short string, all lowercase, with hyphens instead of spaces, whicn will be used in the URL of the new application. If you leave this blank, we will generate one for you from name of the application."}
        {html {size 30}}
        {validate {
            empty_or_not_exists 
            {expr \[empty_string_p \$value\] || \[catch { site_node::get_from_url -url "[ad_conn package_url]\$value/" -exact }\]}
            {This folder name is already used.}
        }}
    }
} -on_submit {
    # Get the node ID of this subsite
    set node_id [ad_conn node_id]

    # Autogenerate folder name
    if { [empty_string_p $folder] } {
        set existing_urls [db_list existing_urls {}]

        set folder [util_text_to_url \
                      -existing_urls $existing_urls \
                      -text $instance_name]
    }

    if { [catch {
        site_node::instantiate_and_mount \
            -parent_node_id $node_id \
            -node_name $folder \
            -package_name $instance_name \
            -package_key $package_key
    } errsmg] } {
        ad_return_error "Problem Creating Application" "We had a problem creating the application."
    }

    ad_returnredirect .
    ad_script_abort
}
