# Form element procedures for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)
#          Stanislav Freidin (sfreidin@arsdigita.com)

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_proc -public template::element { command form_id element_id args } {

  eval template::element::$command $form_id $element_id $args
}

# @public create

# Append an element to a form object.  If a submission is in progress,
# values for the element are prepared and validated.

# @param form_id    The identifier of the form to which the element is to
#                   be added.  The form must have been previously created
#                   with a <tt>form create</tt> statement.
# @param element_id A keyword identifier for the element that is unique
#                   in the context of the form.

# @option widget    The name of an input widget for the element.  Valid
#                   widgets must have a rendering procedure defined in 
#                   the <tt>template::widget</tt> namespace.
# @option datatype  The name of a datatype for the element values.  Valid
#                   datatypes must have a validation procedure defined in
#                   the <tt>template::data::validate</tt> namespace.
# @option html      A list of name-value attribute pairs to include in
#                   the HTML tag for widget.  Typically used for additional
#                   formatting options, such as <tt>cols</tt> or <tt>rows</tt>,
#                   or for JavaScript handlers.

# @option options   A list of options for select lists and button groups 
#                   (check boxes or radio buttons).  The list contains 
#                   two-element lists in the form 
#                   { {label value} {label value} {label value} ...}

# @option value     The default value of the element
# @option values    The default values of the element, where multiple values
#                   are allowed (checkbox groups and multiselect widgets)
# @option validate  A list of custom validation blocks in the form
#                   { name { expression } { message } \
#                     name { expression } { message } ...}
#                   where name is a unique identifier for the validation step,
#                   expression is a block to Tcl code that evaluates to
#                   1 or 0, and message is to be displayed to the user when 
#                   the validation step fails.
# @option optional  A flag indicating that no value is required for this
#                   element.  If a default value is specified, the default
#                   is used instead.

ad_proc -public template::element::create { form_id element_id args } {

  set level [template::adp_level]

  # add the element to the element list
  upvar #$level $form_id:elements elements $form_id:properties form_properties
  if { ! [info exists elements] } {
    error "Form $form_id does not exist"
  }

  lappend elements $form_id:$element_id
  lappend form_properties(element_names) $element_id

  # add the reference to the elements lookup array for the form
  upvar #$level $form_id:$element_id opts

  if [info exists opts] {
      error "Element '$element_id' already exists in form '$form_id'."
  }

  set opts(id) $element_id
  set opts(form_id) $form_id

  # ensure minimal defaults for element parameters
  variable defaults
  array set opts $defaults

  template::util::get_opts $args

  # set the form section
  set opts(section) $form_properties(section)

  # set a name if none specified
  if { ! [info exists opts(name)] } { set opts(name) $opts(id) }

  # set a label if none specified
  if { ! [info exists opts(label)] } { set opts(label) $element_id }

  # If the widget is a submit widget, remember it
  # All submit widgets are optional
  if { [string equal $opts(widget) submit] || \
       [string equal $opts(widget) button] } {
    set form_properties(has_submit) 1
    set opts(optional) 1
    if { ! [info exists opts(value)] } { set opts(value) $opts(label) }
    if { ! [info exists opts(label)] } { set opts(label) $opts(value) }
  }

  # Remember that the element has not been rendered yet
  set opts(is_rendered) f

  copy_value_to_values_if_defined

  # check for submission
  if { [template::form is_submission $form_id] || [info exists opts(param)] } {
    validate $form_id $element_id
  }

}

# @public set_properties

# Modify properties of an existing element.  The same options may be
# used as with the create command.  Most commonly used to set the
# default value for an element when a form page is initially requested.

# @param form_id     The identifier of the form containing the element.
# @param element_id  The unique identifier of the element.

# @see create

ad_proc -public template::element::set_properties { form_id element_id args } {
  get_reference

  # create a reference to opts as expected by get_opts
  upvar 0 element opts

  template::util::get_opts $args

  copy_value_to_values_if_defined
}

# @public set_value

# Sets the value of an element

# @param form_id     The identifier of the form containing the element.
# @param element_id  The unique identifier of the element.
# @param value       The value to apply

ad_proc -public template::element::set_value { form_id element_id value } {

  get_reference

  set element(value) $value
  set element(values) [list $value]
}

# @public get_value

# Retrieves the current value of an element.  Typically used following
# a valid form submission to retrieve the submitted value.

# @param form_id     The identifier of the form containing the element.
# @param element_id  The unique identifier of the element.

# @return The current value of the element.
# @see get_values

ad_proc -public template::element::get_value { form_id element_id } {

  get_reference

  if { [info exists element(value)] } {
    return $element(value)
  } else {
    return ""
  }
}

# @public get_values

# Retrieves the list current values for an element.  Typically used
# following a valid form submission where multiple values may have
# been submitted for a single element (i.e. for a checkbox group or
# multiple select box).

# @param form_id     The identifier of the form containing the element.
# @param element_id  The unique identifier of the element.

# @return A list of current values for the element.
# @see get_value

ad_proc -public template::element::get_values { form_id element_id } {

  get_reference

  return $element(values)
}

# @public get_property

# Retrieves the specified property of the element, such as value,
# datatype, widget, etc.

# @param form_id     The identifier of the form containing the element.
# @param element_id  The unique identifier of the element.
# @param property    The property to be retreived

# @return The value of the property, or "" if the property does not exist
# @see set_properties

ad_proc -public template::element::get_property { form_id element_id property } {

  get_reference

  if { ![info exists element($property)] } {
    return ""
  } else {
    return $element($property)
  }
}

# @private validate

# Validates element values according to 3 criteria: (1) required
# elements must have a not-null value; (2) values must
# match the element's declared datatype; (3) values must pass
# all special validation filters specified with the -validate option
# when the element was created.  If validation fails for any reason,
# one or more messages is added to the error list for the form,
# causing the submission to be invalidated and returned to the user
# for correction.

# @param form_id     The identifier of the form containing the element.
# @param element_id  The unique identifier of the element.

ad_proc -public template::element::validate { form_id element_id } {

  set level [template::adp_level]

  # use an array to hold error messages for this form
  upvar #$level $form_id:error formerror $form_id:$element_id element

  # set values [querygetall $element(id) $element(datatype)]
  set values [querygetall element]
  set is_optional [info exists element(optional)]

  # if the element is optional and the value is an empty string, then ignore
  if { $is_optional && [string equal [lindex $values 0] {}] } {

    set values [list]

    # also clobber the value(s) for a submit widget
    if { [string equal $element(widget) submit] } {
      if { [info exists element(value)] } { unset element(value) }
      if { [info exists element(values)] } { unset element(values) }
    }
  }

  # if no values were submitted then look for values specified in the
  # declaration (either values or value)
  if { ! [llength $values] && [info exists element(values)] } {
    set values $element(values)
  }

  # set a label for use in the template
  set label $element(label)
  if { [string equal $label {}] } {
    set label $element(name)
  }

  set is_inform [string equal $element(widget) inform]

  # Check for required element
  if { ! $is_inform  && ! $is_optional && ! [llength $values] } {

    # no value was submitted for a required element
    set formerror($element_id) "$label is required"
    set formerror($element_id:required) "$label is required"

    if { [lsearch -exact {hidden submit} $element(widget)] > -1 } {
       ns_log Notice "No value for element $label"
     }
  }

  # Prepare custom validation filters

  if { [info exists element(validate)] } {
    
    set v_length [llength $element(validate)]

    if { $v_length == 2 } {

      # a single anonymous validation check was specified
      set element(validate) [linsert $element(validate) 0 "anonymous"]

    } elseif { [expr $v_length % 3] } {

      error "Invalid number of parameters to validate option: 
             $element(validate) (Length is $v_length)"
    }

  } else {

    set element(validate) [list]
  }

  set v_errors [list]

  foreach value $values {
  
    # something was submitted, now check if it is valid

    if { $is_optional && [empty_string_p $value] } {
       # This is an optional field and it's empty... skip validation
       # (else things like the integer test will fail)
       continue
    }

    if { ! [template::data::validate $element(datatype) value message] } {

      # the submission is invalid
      lappend v_errors $message
      set formerror($element_id:data) $message

      if { [lsearch -exact {hidden submit} $element(widget)] } {
	ns_log Notice "Invalid value for element $label: $message"
      }
    }

    foreach { v_name v_code v_message } $element(validate) {

      if { ! [eval $v_code] } {
      
	# value is invalid according to custom validation code
	lappend v_errors [subst $v_message]
	set formerror($element_id:$v_name) [subst $v_message]
      }
    }
  }

  if { [llength $v_errors] } {
    # concatenate all validation errors encountered while looping over values
    set formerror($element_id) [join $v_errors "<br>\n"]
  }

  # make the value be the previously submitted value when returning the form
  set element(values) $values

  # be careful not to clobber a default value if one has been specified
  if { [llength $values] || ! [info exists element(value)] } {
    set element(value) [lindex $values 0]
  }
}

# @public set_error

# Manually set an error message for an element.  This may be used to
# implement validation filters that involve more than one form element
# ("Sorry, blue is not available for the model you selected, please
# choose another color.")

# @param form_id     The identifier of the form containing the element.
# @param element_id  The unique identifier of the element with which
#                    the error message should be associated in the form
#                    template.
# @param message     The text of the error message.

ad_proc -public template::element::set_error { form_id element_id message } {

  set level [template::adp_level]

  upvar #$level $form_id:error formerror

  # set the message
  set formerror($element_id) $message
}

# Get all values for an element, performing any transformation defined
# for the datatype.

ad_proc -public template::element::querygetall { element_ref } {

  upvar $element_ref element

  set datatype $element(datatype)

  set transform_proc "::template::data::transform::$datatype"

  if { [string equal [info procs $transform_proc] {}] } {

    set values [ns_querygetall $element(id)]

    # QUIRK: ns_querygetall returns a single-element list {{}} for no values
    if { [string equal $values {{}}] } { set values [list] }

  } else {
    set values [template::data::transform::$datatype element]
  }
 
  return $values
}

# @public exists

# Determine if an element exists in a specified form

# @param form_id     The identifier of the form containing the element.
# @param element_id  The unique identifier of the element within the form.

# @return 1 if the element exists in the form, or 0 otherwise

ad_proc -public template::element::exists { form_id element_id } {

  set level [template::adp_level]

  upvar #$level $form_id:$element_id element_properties

  return [info exists element_properties]
}

# @private get_reference

# Gets a reference to the array containing the properties of an
# element, and throws and error if the element does not exist.  Called
# at the beginning of several of the element commands.

ad_proc -public template::element::get_reference {} {

  uplevel {

    set level [template::adp_level]
    upvar #$level $form_id:$element_id element

    if { ! [array exists element] } {
      error "Element \"$element_id\" does not exist in form \"$form_id\""
    }
  }
}

# @private render

# Generate the HTML for a particular form widget.

# @param form_id        The identifier of the form containing the element.
# @param element_id     The unique identifier of the element within the form.
# @param tag_attributes A name-value list of addditional HTML
#                       attributes to include in the tag, such as JavaScript
#                       handlers or special formatting (i.e. ROWS and COLS
#                       for a TEXTAREA).

# @return A string containing the HTML for an INPUT, SELECT or TEXTAREA
#         form element.

ad_proc -public template::element::render { form_id element_id tag_attributes } {

  get_reference

  # Remember that the element has been rendered already
  set element(is_rendered) t

  return [template::widget::$element(widget) element $tag_attributes]
}

# @private render_help

# Render the -help_text text

# @param form_id        The identifier of the form containing the element.
# @param element_id     The unique identifier of the element within the form.
# @param tag_attributes Reserved for future use.

ad_proc -public template::element::render_help { form_id element_id tag_attributes } {

  get_reference

  return $element(help_text)
}

# @private options

# Prepares a multirow data source for use within a formgroup

# @param form_id        The identifier of the form containing the element.
# @param element_id     The unique identifier of the element within the form.
# @param tag_attributes A name-value list of addditional HTML
#                       attributes to include in the INPUT tags for each
#                       radio button or checkbox, such as JavaScript
#                       handlers or special formatting.

ad_proc -public template::element::options { form_id element_id tag_attributes } {

  get_reference

  if { ! [info exists element(options)] } {
    error "No options specified for element $element_id in form $form_id"
  }

  # Remember that the element has been rendered already
  set element(is_rendered) t

  # render the widget once with a placeholder for value
  set element(value) "\$value"
  lappend tag_attributes "\$checked" ""
  set widget [template::widget::$element(widget) element $tag_attributes]

  set options $element(options)
  if { [info exists element(values)] } {
    template::util::list_to_lookup $element(values) values 
  }

  # the data source is named formgroup by convention

  upvar #$level formgroup:rowcount rowcount
  set rowcount [llength $options]

  # Create a widget entry for each checkbox in the group
  for { set i 1 } { $i <= $rowcount } { incr i } {

    upvar #$level formgroup:$i formgroup
    
    set option [lindex $options [expr $i - 1]]
    set value [lindex $option 1]

    if { ![info exists values($value)] } {
      set checked ""
    } else {
      set checked "checked"
    }

    set formgroup(label)   [lindex $option 0]
    set formgroup(widget)  [subst $widget]
    set formgroup(rownum)  $i
    set formgroup(checked) $checked
    set formgroup(option)  $value
  }
}



# @private copy_value_to_values_if_defined

# define values from value, if the latter is more defined

ad_proc -public template::element::copy_value_to_values_if_defined {} {
  upvar opts opts
  # values is always defined, init to "" from template::element::defaults
  if { [info exists opts(value)] && [llength $opts(values)] == 0 } {
    if { [string equal opts(value) {}] } {
      set opts(values) [list]
    } else {
      set opts(values) [list $opts(value)]
    }
  }
}
