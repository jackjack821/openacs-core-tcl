ad_page_contract {

    Search for localized messages containing a certain substring, 
    in order to help translators ensure consistent terminology.

} {
    locale
    search_locale:optional
    q:optional
}

# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [ad_locale_get_label $current_locale]
set default_locale_label [ad_locale_get_label $default_locale]

set page_title "Search Messages"
set context [list [list "package-list?[export_vars { locale }]" $locale_label] $page_title]

set default_locale en_US

set search_locales [list]
lappend search_locales [list "Current locale - [ad_locale_get_label $locale]" $locale ]
lappend search_locales [list "Master locale - [ad_locale_get_label $default_locale]" $default_locale]

set submit_p 0

ad_form -name search -action message-search -form {
    {locale:text(hidden) {value $locale}}
}

if { ![string equal $default_locale $current_locale] } {
    ad_form -extend -name search -form {
        {search_locale:text(select)
            {options $search_locales}
            {label "Search locale"}
        }
    }
} else {
    ad_form -extend -name search -form {
        {search_locale:text(hidden)
            {value $current_locale}
        }
    }
}

ad_form -extend -name search -form {
    {q:text 
        {label "Search for"}
    }
} -on_request {
    # locale will be set now
} 

if { [exists_and_not_null search_locale] && [exists_and_not_null q] } {
    set submit_p 1

    set search_string "%$q%"

    db_multirow -extend { 
        package_url
        edit_url
        message_key_pretty
    } messages select_messages {} {
        set edit_url "edit-localized-message?[export_vars { locale package_key message_key {return_url {[ad_return_url]} } }]"
        set package_url "message-list?[export_vars { locale package_key }]"
        set message_key_pretty "$package_key.$message_key"
    }

    if { ![string equal $current_locale $default_locale] } {
        if { [string equal $default_locale $search_locale] } {
            set other_locale $locale_label
            set other_search_url "[ad_conn url]?[export_vars { locale q {search_locale $current_locale} }]"
        } else {
            set other_locale $default_locale_label
            set other_search_url "[ad_conn url]?[export_vars { locale q {search_locale $default_locale} }]"
        }
    }
}


