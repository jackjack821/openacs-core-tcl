namespace eval template {}

ad_library {

    Provides procedures needed to determine mime type required for the
client browser, as
    well as other additional header information.

    @author Shan Shan Huang (shuang@arsdigita.com)
    @creation-date 12 January 2001
    @cvs-id $Id$
}  

ad_proc -public template::register_mime_type { mime_type file_extension
header_preamble } {
  if { [info exists template_extension($mime_type)] } {
    nsv_unset template_extension($mime_type)
  } 
  if { [info exists template_header_preamble($mime_type)] } {
    unset template_header_preamble($mime_type)
  }

  nsv_set template_extension $mime_type $file_extension
  nsv_set template_header_preamble $mime_type $header_preamble
}

ad_proc -public template::get_mime_template_extension { mime_type } {
  if { [nsv_exists template_extension $mime_type] } {
    return [nsv_get template_extension $mime_type]
  } else {
    return "adp"
  }
}

ad_proc -public template::get_mime_header_preamble { mime_type } {
  if { [nsv_exists template_header_preamble $mime_type] } {
    return [nsv_get template_header_preamble $mime_type]
  } else {
    return ""
  }
}

ad_proc -public template::get_mime_type {} {
    if {[ns_conn isconnected]} {
        set mime_type [ns_set iget [ns_conn outputheaders] "content-type"]
    } else { 
        set mime_type {} 
    }
    if { [empty_string_p $mime_type] } {
        set mime_type "text/html"
    }

    return $mime_type
}
