# Form widgets for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)
#          Stanislav Freidin (sfreidin@arsdigita.com)
     
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

namespace eval template {}
namespace eval template::widget {}
namespace eval template::data {}
namespace eval template::data::transform {}

ad_proc -public template::widget {} {
    The template::widget namespace contains the code 
    for the various input widgets.

    @see template::widget::ampmFragment
    @see template::widget::button
    @see template::widget::checkbox
    @see template::widget::comment
    @see template::widget::currency
    @see template::widget::date
    @see template::widget::dateFragment
    @see template::widget::file
    @see template::widget::hidden
    @see template::widget::inform
    @see template::widget::input
    @see template::widget::menu
    @see template::widget::monthFragment
    @see template::widget::multiselect
    @see template::widget::numericRange
    @see template::widget::password
    @see template::widget::party_search
    @see template::widget::radio
    @see template::util::richtext
    @see template::widget::search
    @see template::widget::select
    @see template::widget::submit
    @see template::widget::text
    @see template::widget::textarea
    @see template::widget::block
    @see template::element::create
} -


ad_proc -public template::widget::party_search { element_reference tag_attributes } {

    A widget that searches for parties (persons, groups and relational_segments) and lets
    the user select one from the search results.

    <p>

    It only searches in all parties from the system currently. It should propably be extended to
    allow to restrict the search to a specific subsite, as well as searching only 
    for groups or persons.

    @author Tilmann Singer
} {

    upvar $element_reference element

    if { ![info exists element(options)] } {
        
        # initial submission or no data (no options): a text box
        set output [input text element $tag_attributes]

    } else {

        set output "<input type=\"hidden\" name=\"$element(id):select\" value=\"t\" />"
        append output "<input type=\"hidden\" name=\"$element(id):search_string\" value=\"$element(search_string)\" />"

        if { ![info exists element(confirmed_p)] } {
            append output "<input type=\"hidden\" name=\"$element(id):confirmed_p\" value=\"t\" />"
        }
            
        append output [select $element_reference $tag_attributes]
    }
    return $output
}

ad_proc -public template::data::validate::party_search { value_ref message_ref } {
    return 1
}

ad_proc -public template::data::transform::party_search { element_ref } {

    upvar $element_ref element
    set element_id $element(id)

    set value [string trim [ns_queryget $element_id]]

    if { [empty_string_p $value] } {
        template::element::set_error $element(form_id) $element_id "Please enter a search string."
        return [list]
    }

    if { [string equal $value ":search:"] } {
        # user has selected 'search again' previously
        template::element::set_error $element(form_id) $element_id "Please enter a search string."
        return [list]
    }
     
    if { [ns_queryexists $element_id:search_string] } {
        # request comes from a page with a select widget and the
        # search string has been passed as hidden value
        set search_string [ns_queryget $element_id:search_string]
        set element(search_string) $search_string

        # the value to be returned
        set value [ns_queryget $element_id]
    } else {
        # request is an initial search
        set search_string $value
        set element(search_string) $value
    }

    # search in persons
    set persons [db_list_of_lists search_persons {}]

    # search in groups and relsegs
    set groups_relsegs [db_list_of_lists search_groups_relsegs {}]

    if { [llength $persons] == 0 && [llength $groups_relsegs] == 0 } {
        # no search results so return text entry back to the user

        catch { unset element(options) }

        template::element::set_error $element(form_id) $element_id "
        No matches were found for \"$search_string\".<br>Please
        try again."

    } else {
        # we need to return a select list

        set options [list]

        if { [llength $persons] > 0 } {
            set options $persons
            set options [concat $options [list [list "---" ""]]]
        }
        if { [llength $groups_relsegs] > 0 } {
            set options [concat $options $groups_relsegs]
            set options [concat $options [list [list "---" ""]]]
        }
        set element(options) [concat $options { { "Search again..." ":search:" } }]
        if { ![info exists value] } {
            # set value to first item
            set value [lindex [lindex $options 0] 1]
        }

        if { ![ns_queryexists $element_id:confirmed_p] } {
            template::element::set_error $element(form_id) $element_id "Please choose an entry."
        }
    }

    if { [info exists element(result_datatype)] &&
         [ns_queryexists $element_id:select] } {
        set element(datatype) $element(result_datatype)
    }

    return $value
}


ad_proc -public template::widget::search { element_reference tag_attributes } {

  upvar $element_reference element

  if { ! [info exists element(options)] } {
    
    # initial submission or no data (no options): a text box
    set output [input text element $tag_attributes]

  } else {

    # options provided so use a select list
    # include an extra hidden element to indicate that the 
    # value is being selected as opposed to entered

    set output "\n<input type=\"hidden\" name=\"$element(id):select\" value=\"t\" />"
    append output [select element $tag_attributes]

  }


  return $output
}

ad_proc -public template::widget::textarea { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }
  array set attributes $tag_attributes
    
  if { [info exists element(value)] } {
      set value $element(value)
  } else {
      set value {}
  }

  if { [info exists element(mode)] } {
      set mode $element(mode)
  } else {
      set mode {}
  }


  set output [textarea_internal $element(name) attributes $value $mode]

  # Spell-checker
  array set spellcheck [template::util::spellcheck::spellcheck_properties -element_ref element]
  
  if { [string equal $element(mode) "edit"] && $spellcheck(render_p) } {
      append output "<br>[_ acs-templating.Spellcheck]: 
[menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] $spellcheck(selected_option) {}]"
  }   

  return $output
}

ad_proc -public template::widget::textarea_internal { 
    name 
    attribute_reference
    {value {}}
    {mode edit}
} {
  upvar $attribute_reference attributes

  if { ![string equal $mode "edit"] } {
    set output {}
    if { ![empty_string_p value] } {
      append output "[ad_quotehtml $value]<input type=\"hidden\" name=\"$name\" value=\"[ad_quotehtml $value]\">"
    }
  } else {
    set output "<textarea name=\"$name\""
    
    foreach attribute_name [array names attributes] {
      if { [string equal $attributes($attribute_name) {}] } {
        append output " $attribute_name"
      } else {
        append output " $attribute_name=\"$attributes($attribute_name)\""
      }
    }
    
    append output ">[ad_quotehtml $value]</textarea>"
  }
  
  return $output
}



ad_proc -public template::widget::inform { element_reference tag_attributes } {
    A static information widget that does not submit any data
} {

  upvar $element_reference element

  if { [info exists element(value)] } {
      return "$element(value)[input hidden element $tag_attributes]"
  } else {
      return [input hidden element $tag_attributes]
  }
}

ad_proc -public template::widget::input { type element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  if { ( [string equal $type "checkbox"] || [string equal $type "radio"] ) && [info exists element(value)] } {
      # This can be used in the form template in a <label for="id">...</label> tag.
      set attributes(id) "$element(form_id):elements:$element(name):$element(value)"
  }
  
  # Handle display mode of visible normal form elements, i.e. not hidden, not submit, not button, not clear
  if { ![string equal $element(mode) "edit"] && [lsearch -exact { hidden submit button clear checkbox radio } $type] == -1 } {
      set output ""
      if { [info exists element(value)] } {
          append output [ad_quotehtml $element(value)]
          append output "<input type=\"hidden\" name=\"$element(name)\" value=\"[ad_quotehtml $element(value)]\">"
      }
  } else {
      set output "<input type=\"$type\" name=\"$element(name)\""

      if { ![string equal $element(mode) "edit"] && [lsearch -exact { hidden submit button clear } $type] == -1 } {
          append output " disabled"
      }

    if { [info exists element(value)] } {
      append output " value=\"[template::util::quote_html $element(value)]\""
    } 

    foreach name [array names attributes] {
      if { [string equal $attributes($name) {}] } {
        append output " $name"
      } else {
        append output " $name=\"$attributes($name)\""
      }
    }

    if { [info exists element(maxlength)] } {
        append output " maxlength=\"$element(maxlength)\""
    }
    
    append output " />"
  }

  return $output
}

ad_proc -public template::widget::text { element_reference tag_attributes } {

  upvar $element_reference element

  # Spell-checker
  array set spellcheck [template::util::spellcheck::spellcheck_properties -element_ref element]
  
  if { [string equal $element(mode) "edit"] && $spellcheck(render_p) } {
      return "[input text element $tag_attributes] <br>[_ acs-templating.Spellcheck]: 
[menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] $spellcheck(selected_option) {}]"
  } else {
      return [input text element $tag_attributes]
  }
}



ad_proc -public template::widget::file { element_reference tag_attributes } {

  upvar $element_reference element

  return [input file element $tag_attributes]
}



ad_proc -public template::widget::password { element_reference tag_attributes } {

  upvar $element_reference element

  return [input password element $tag_attributes]
}


ad_proc -public template::widget::hidden { element_reference tag_attributes } {

  upvar $element_reference element

  return [input hidden element $tag_attributes]
}

ad_proc -public template::widget::submit { element_reference tag_attributes } {

  upvar $element_reference element

  # always ignore value for submit widget
  set element(value) $element(label) 

  return [input submit element $tag_attributes]
}

ad_proc -public template::widget::attachment { element_reference tag_attributes } {

    upvar $element_reference element

    set output [input file element $tag_attributes]

    set element(name) $element(attach_name)
    set element(label) $element(attach_label)
    set element(html) $element(attach_html)

    append output [submit element $tag_attributes]

    return $output
}

ad_proc -public template::widget::checkbox { element_reference tag_attributes } {

  upvar $element_reference element

  return [input checkbox element $tag_attributes]
}

ad_proc -public template::widget::radio { element_reference tag_attributes } {

  upvar $element_reference element

  return [input radio element $tag_attributes]
}

ad_proc -public template::widget::button { element_reference tag_attributes } {

  upvar $element_reference element

  return [input button element $tag_attributes]
}

ad_proc -public template::widget::menu { 
    widget_name
    options_list
    values_list
    attribute_reference
    {mode edit}
} {

  upvar $attribute_reference attributes
  
  # Create an array for easier testing of selected values
  template::util::list_to_lookup $values_list values 

  if { ![string equal $mode "edit"] } {
    set selected_list [list]
    set output {}
    
    foreach option $options_list {
      
      set label [lindex $option 0]
      set value [lindex $option 1]
      
      if { [info exists values($value)] } {
        lappend selected_list $label
        append output "<input type=\"hidden\" name=\"$widget_name\" value=\"[ad_quotehtml $value]\">"
      }
    }
    
    append output [join $selected_list ", "]
  } else {
    set output "<select name=\"$widget_name\" "
  
    foreach name [array names attributes] {
      if { [string equal $attributes($name) {}] } {
        append output " $name"
      } else {
        append output " $name=\"$attributes($name)\""
      }
    }
  
    append output ">\n"
  
    foreach option $options_list {

      set label [lindex $option 0]
      set value [lindex $option 1]

      append output " <option value=\"[template::util::quote_html $value]\""
        
      if { [info exists values($value)] } {
        append output " selected=\"selected\""
      }

      append output ">$label</option>\n"
    }
  
    append output "</select>"
  }

  return $output
}

ad_proc -public template::widget::select { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  return [template::widget::menu \
    $element(name) $element(options) $element(values) attributes $element(mode)]
}

ad_proc -public template::widget::multiselect { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set attributes(multiple) {}

  # Determine the size automatically for a multiselect
  if { ! [info exists attributes(size)] } {
  
    set size [llength $element(options)]
    if { $size > 8 } {
      set size 8
    }
    set attributes(size) $size
  }

  return [template::widget::menu \
    $element(name) $element(options) $element(values) attributes $element(mode)]
}

ad_proc -public template::data::transform::search { element_ref } {

  upvar $element_ref element
  set element_id $element(id)

  set value [ns_queryget $element_id]

  # there will no value for the initial request or if the form
  # is submitted with no search criteria (text box blank)
  if { [string equal $value {}] } { return [list] } 

  if { [string equal $value ":search:"] } { 
      if { [info exists element(options)] } {
          unset element(options)
      }
      template::element::set_error $element(form_id) $element_id "
        Please enter a search string."
      return [list]
  }

  # check for a value that has been entered rather than selected
  if { ! [ns_queryexists $element_id:select] } {

    # perform a search based on the value
    if { ! [info exists element(search_query)] } { 
      error "No search query specified for search widget"
    }

    set query $element(search_query)

    set options [db_list_of_lists get_options $query]

    set option_count [llength $options]

    if { $option_count == 0 } {

      # no search results so return text entry back to the user

      if { [info exists element(options)] } {
          unset element(options)
      }

      template::element::set_error $element(form_id) $element_id "
        No matches were found for \"$value\".<br>Please
        try again."

    } elseif { $option_count == 1 } {

      # only one option so just reset the value
      set value [lindex [lindex $options 0] 1]

    } else {

      # need to return a select list
      set element(options) [concat $options { { "Search again..." ":search:" } }]
      template::element::set_error $element(form_id) $element_id "
        More than one match was found for \"$value\".<br>Please
        choose one from the list."

      set value [lindex [lindex $options 0] 1]
    }
  }

  if { [info exists element(result_datatype)] &&
       [ns_queryexists $element_id:select] } {
    set element(datatype) $element(result_datatype)
  }

  return [list $value]
}

ad_proc -public template::widget::comment { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set output {}

  if { [info exists element(history)] } {
      append output "$element(history)"
  }

  if { [string equal $element(mode) "edit"] } {
      if { [info exists element(header)] } {
          append output "<p><b>$element(header)</b></p>"
      }
      
      append output [textarea $element_reference $tag_attributes]

      if { [info exists element(format_element)] && [info exists element(format_options)] } {
          append output "<br>Format: [menu $element(format_element) $element(format_options) {} {}]"
      }
  }
      
  return $output
}

ad_proc -public template::widget::block { element_reference tag_attributes } {
    widget for blocks of radio-buttoned questions
} {
    upvar $element_reference element
    
    if { [info exists element(html)] } {
	array set attributes $element(html)
    }
    
    if { [info exists element(value)] } {
	set value $element(value)
    } else {
	set value {}
    }

    array set attributes $tag_attributes
    
    set output ""
    set options $element(options)
    set count 0
    foreach option $options {
	if {$count == 0} {
	    # answer descriptions in a list: {{desc1 no_of_answers} {desc2 no_of_answers} ...}
	    append output "<tr align=center><td></td><td></td>"
	    foreach answer_desc $option {
		set answer_description [lindex $answer_desc 0]
		set no_of_answers [lindex $answer_desc 1]
		append output "<th colspan=\"[expr $no_of_answers + 1]\" align=\"center\">$answer_description</td>"
	    }
	    append output "</tr>"
	} elseif {$count == 1} {
	    append output "<tr><td><span style=\"font-weight: bold\">[lindex $option 0]</span></td>"
	    foreach answer_set [lindex $option 1] {
		append output "<td>required?</td>"
		foreach answer $answer_set {
		    append output "<td>$answer</td>"
		}
	    }
	    append output "</tr>"
	} else {
	    append output "<tr><td><span style=\"font-weight: bold\">[lindex $option 0]</span></td>"
	    foreach question [lindex $option 1] {
		set name [lindex $question 0]
		set required_p [lindex $question 1]
		append output "<td>[ad_decode $required_p "t" "<span style=\"color: #f00;\">*</span>" "&nbsp;"]</td>"
		foreach choice [lindex $question 2] {
		    if {[lsearch -exact $value $choice]==-1} {
			append output "<td><input type=\"radio\" name=\"$name\" value=\"$choice\"></td>"
		    } else {
			append output "<td><input type=\"radio\" name=\"$name\" value=\"$choice\" checked></td>"
		    }
		}
	    }
	    append output "</tr>"
	}
	incr count
    }
    return "<table>$output</table>"
    
}

