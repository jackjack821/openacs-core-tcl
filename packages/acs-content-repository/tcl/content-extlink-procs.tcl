# packages/acs-content-repository/tcl/content-extlink-procs.tcl 

ad_library {
    
    Procedures for content_extlink
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-09
    @arch-tag: f8f62c6c-bf3b-46d9-8e1e-fa5e60ba1c05
    @cvs-id $Id$
}

namespace eval ::content::extlink {}

ad_proc -public content::extlink::copy {
    -extlink_id:required
    -target_folder_id:required
    -creation_user:required
    {-creation_ip ""}
} {
    @param extlink_id extlink to copy
    @param target_folder_id folder to copy extlink into
    @param creation_user 
    @param creation_ip
} {
    return [package_exec_plsql -var_list [list \
        extlink_id $extlink_id \
        target_folder_id $target_folder_id \
        creation_user $creation_user \
        creation_ip $creation_ip \
    ] content_extlink copy]
}


ad_proc -public content::extlink::del {
    -extlink_id:required
} {
    @param extlink_id item_id of extlink to delete
} {
    return [package_exec_plsql -var_list [list \
        extlink_id $extlink_id \
    ] content_extlink del]
}


ad_proc -public content::extlink::is_extlink {
    -item_id:required
} {
    @param item_id item_id to check

    @return 1 if extlink, otherwise 0
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_extlink is_extlink]
}
