ad_library {
    Rich text input widget and datatype for OpenACS templating system.

    @author Lars Pind (lars@pinds.com)
    @creation-date 2003-01-27
    @cvs-id $Id$
}

namespace eval template::util::richtext {}

ad_proc -public template::util::richtext { command args } {
    Dispatch procedure for the richtext object
} {
  eval template::util::richtext::$command $args
}

ad_proc -public template::util::richtext::create {
    {contents {}}
    {format {}}
} {
    return [list $contents $format]
}

ad_proc -public template::util::richtext::acquire { type { value "" } } {
    Create a new richtext value with some predefined value
    Basically, create and set the richtext value
} {
  set richtext_list [template::util::richtext::create]
  return [template::util::richtext::set_property $type $richtext_list $value]
}

ad_proc -public template::util::richtext::formats {} {
    Returns a list of valid richtext formats
} {
    return { text/enhanced text/plain text/html text/fixed-width }
}

ad_proc -public template::util::richtext::format_options {} {
    Returns a formatting option list
} {
    return { 
        {"Enhanced Text" text/enhanced}
        {"Plain Text" text/plain}
        {"Fixed-width Text" text/fixed-width}
        {"HTML" text/html}
    }
}

ad_proc -public template::data::validate::richtext { value_ref message_ref } {

    upvar 2 $message_ref message $value_ref value

    # a richtext is a 2 element list consisting of { contents format }
    set contents  [lindex $value 0]
    set format    [lindex $value 1]

    if { [lsearch [template::util::richtext::formats] $format] == -1 } {
	set message "Invalid format, '$format'."
	return 0
    }

    # enhanced text and HTML needs to be security checked
    if { [lsearch { text/enhanced text/html } $format] != -1 } {
        set check_result [ad_html_security_check $contents]
        if { ![empty_string_p $check_result] } {
            set message $check_result
            return 0
        }
    }

    return 1
}    

ad_proc -public template::data::transform::richtext { element_ref } {

    upvar $element_ref element
    set element_id $element(id)

    set contents [ns_queryget $element_id]
    set format [ns_queryget $element_id.format]

    set richtext_list [list $contents $format]
    
    return [list $richtext_list]
}

ad_proc -public template::util::richtext::set_property { what richtext_list value } {

    # There's no internal error checking, just like the date version ...

    set contents [lindex $richtext_list 0]
    set format   [lindex $richtext_list 1]

    switch $what {
        contents {
            $ Replace contents with value
            return [list $value $format]
        }
        format {
            # Replace format with value
            return [list $contents $value]
        }
    }
}

ad_proc -public template::util::richtext::get_property { what richtext_list } {

    # There's no internal error checking, just like the date version ... 

    set contents  [lindex $richtext_list 0]
    set format    [lindex $richtext_list 1]

    switch $what {
        contents {
            return $contents
        }
        format {
            return $format
        }
        html_value {
            return [ad_html_text_convert -from $format -to "text/html" -- $contents]
        }
    }
}

ad_proc -public template::widget::richtext { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set output {}

  if { [string equal $element(mode) "edit"] } {
      append output {
<script language="javascript">
<!--
function formatStr (v) {
    if (!document.selection) return;
    var str = document.selection.createRange().text;
    if (!str) return;
    document.selection.createRange().text = '<' + v + '>' + str + '</' + v + '>';
}

function insertLink () {
    if (!document.selection) return;
    var str = document.selection.createRange().text;
    if (!str) return;
    var my_link = prompt('Enter URL:', 'http://');
    if (my_link != null)
        document.selection.createRange().text = '<a href="' + my_link + '">' + str + '</a>';
}

if (document.selection) {
    document.write('<table border="0" cellspacing="0" cellpadding="0" width="107">');
    document.write('<tr>');
    document.write('<td width="24"><a href="javascript:formatStr(\'b\')"><img src="/shared/bold-button.gif" alt="bold" width="24" height="18" border="0"></a></td>');
    document.write('<td width="24"><a href="javascript:formatStr(\'i\')"><img src="/shared/italic-button.gif" alt="italic" width="24" height="18" border="0"></a></td>');
    document.write('<td width="24"><a href="javascript:formatStr(\'u\')"><img src="/shared/underline-button.gif" alt="underline" width="24" height="18" border="0"></a></td>');
    document.write('<td width="26"><a href="javascript:insertLink()"><img src="/shared/url-button.gif" alt="link" width="26" height="18" border="0"></a></td>');
    document.write('</tr>');
    document.write('</table>');
}
//-->
</script>
      }

      if { [info exists element(value)] } {
          set contents [template::util::richtext::get_property contents $element(value)]
          set format   [template::util::richtext::get_property format $element(value)]
      } else {
          set contents {}
          set format {}
      }

      append output [textarea_internal "$element(id)" attributes $contents]
      append output "<br>Format: [menu "$element(id).format" [template::util::richtext::format_options] $format {}]"

  } else {
      # Display mode
      if { [info exists element(value)] } {
          append output [template::util::richtext::get_property html_value $element(value)] $element(mode)]
      }
  }
      
  return $output
}
