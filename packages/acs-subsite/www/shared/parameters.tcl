ad_page_contract {
    Parameters page.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-13
    @cvs-id $Id$
} {
    {package_id {[ad_conn package_id]}}
    {return_url {[ad_conn url]}}
}

permission::require_permission -object_id $package_id -privilege admin

db_1row select_instance_name {
    select instance_name, package_key
    from   apm_packages
    where  package_id = :package_id
}

set package_url [site_node::get_url_from_object_id -object_id $package_id]

set page_title "$instance_name Parameters"

set context [list $page_title]

ad_require_permission $package_id admin

set form {
    {return_url:text(hidden),optional}
    {package_id:integer(hidden),optional}
}

set display_warning_p 0
set counter 0
db_foreach select_params {} {
    if { [empty_string_p $section_name] } {
        set section_name "Main"
    } else {
        set section_name [string map {_ { } - { }} $section_name]
        set section_name "[string toupper [string index $section_name 0]][string range $section_name 1 end]"
    }
    
    set elm [list ${parameter_name}:text,optional \
                 [list label $parameter_name] \
                 [list help_text $description] \
                 [list section $section_name] \
                 {html {size 50}}]

    set file_val [ad_parameter_from_file $parameter_name $package_key]
    if { ![empty_string_p $file_val] } { 
        set display_warning_p 1 
        lappend elm [list after_html "<br><span style=\"color: red; font-weight: bold;\">$file_val (*)</span>"]
    } 
    
    lappend form $elm
    set param($parameter_name) $attr_value
    
    incr counter
}

if { $counter > 0 } {
    ad_form -name parameters -cancel_url $return_url -form $form -on_request {
        foreach name [array names param] {
            set $name $param($name)
        }
    } -on_submit {
        db_foreach select_params_set {} {
            if { [info exists $c__parameter_name]} {
                parameter::set_value \
                    -package_id $package_id \
                    -parameter $c__parameter_name \
                    -value [set $c__parameter_name]
            }
        }
    } -after_submit {
        ad_returnredirect $return_url
        ad_script_abort
    }
}
