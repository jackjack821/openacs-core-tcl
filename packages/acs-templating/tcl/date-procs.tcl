# Date widgets for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Author: Stanislav Freidin (sfreidin@arsdigita.com)
#
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Prepare an array to map symbolic month names to their indices

# Dispatch procedure for the date object
ad_proc -public template::util::date { command args } {
  eval template::util::date::$command $args
}

ad_proc -public template::util::date::init {} {
  variable month_data
  variable fragment_widgets
  variable fragment_formats
  variable token_exp

  array set month_data { 
    1 {January Jan 31} 
    2 {February Feb 28} 
    3 {March Mar 31} 
    4 {April Apr 30} 
    5 {May May 31} 
    6 {June Jun 30} 
    7 {July Jul 31} 
    8 {August Aug 31} 
    9 {September Sep 30} 
   10 {October Oct 31} 
   11 {November Nov 30} 
   12 {December Dec 31}
  }

  # Forward lookup
  array set fragment_widgets {
    YYYY {dateFragment year 4 Year}
      YY {dateFragment short_year 2 Year} 
      MM {dateFragment month 2 Month}
     MON {monthFragment month short Month}
   MONTH {monthFragment month long Month}
      DD {dateFragment day 2 Day}
    HH12 {dateFragment short_hours 2 {12-Hour}}  
    HH24 {dateFragment hours 2 {24-Hour}}
      MI {dateFragment minutes 2 Minutes}
      SS {dateFragment seconds 2 Seconds}
      AM {ampmFragment ampm 2 Meridian}
  }

  # Reverse lookup
  foreach key [array names fragment_widgets] {
    set fragment_formats([lindex $fragment_widgets($key) 1]) $key
  } 

  # Expression to match any valid format token
  set token_exp "([join [array names fragment_widgets] |])(t*)"
}

# Return the specified month name (short or long)
ad_proc -public template::util::date::monthName { month length } {
  variable month_data

  if { [string equal $length long] } {
    set index 0
  } else {
    set index 1
  }

  set month [template::util::leadingTrim $month]

  if { [info exists month_data($month)] } {
    return [lindex $month_data($month) $index]
  } else {
    return ""
  }
}

# Return the number of days in a month, accounting for leap years
# IS THE LEAP YEAR CODE CORRECT ?

ad_proc -public template::util::date::daysInMonth { month {year 0} } {
  variable month_data
  set month_desc $month_data($month)
  set days [lindex $month_desc 2]
  
  if { $month == 2 && (
          ([expr $year % 4] == 0 && [expr $year % 100] != 0) ||
          [expr $year % 400] == 0
        ) } {
    return [expr $days + 1]
  } else {
    return $days
  } 
}  

# Create a new Date object
# I chose to implement the date objects as lists instead of 
# arrays, because arrays are not first-class in TCL

ad_proc -public template::util::date::create {
  {year {}} {month {}} {day {}} {hours {}} 
  {minutes {}} {seconds {}} {format "DD MONTH YYYY"}
} {
  return [list $year $month $day $hours $minutes $seconds $format]
}

# Create a new date with some predefined value
# Basically, create and set the date
ad_proc -public template::util::date::acquire { type { value "" } } {
  set the_date [template::util::date::create]
  return [template::util::date::set_property $type $the_date $value]
}

# Create a new Date object for the current date
ad_proc -public template::util::date::today {} {

  set now [clock format [clock seconds] -format "%Y %m %d"]
  set today [list]

  foreach v $now {
    # trim leading zeros to avoid octal problem
    lappend today [template::util::leadingTrim $v]
  }

  return [eval create $today]
}

# Create a new Date object for the current date and time
ad_proc -public template::util::date::now {} {

  set now [clock format [clock seconds] -format "%Y %m %d %H %M %S"]
  set today [list]

  foreach v $now {
    lappend today [template::util::leadingTrim $v]
  }

  return [eval create $today]
}

# Access properties of the Date object
# Is it better to name them symbolically, as opposed to 
# using the format string codes ?

ad_proc -public template::util::date::get_property { what date } {

  variable month_data

  switch $what {
    year       { return [lindex $date 0] }
    month      { return [lindex $date 1] }
    day        { return [lindex $date 2] }
    hours      { return [lindex $date 3] }
    minutes    { return [lindex $date 4] }
    seconds    { return [lindex $date 5] }
    format     { return [lindex $date 6] }
    long_month_name {
      if { [string equal [lindex $date 1] {}] } {
        return {}
      } else {
        return [monthName [lindex $date 1] long]
      }
    }
    short_month_name {
      if { [string equal [lindex $date 1] {}] } {
        return {}
      } else {
        return [monthName [lindex $date 1] short]
      }
    }
    days_in_month {
      if { [string equal [lindex $date 1] {}] || \
           [string equal [lindex $date 0] {}]} {
        return 31
      } else {
        return [daysInMonth \
               [lindex $date 1] [lindex $date 0]]
      }
    }
    short_year {
      if { [string equal [lindex $date 0] {}] } {
        return {}
      } else {
	  return [expr [lindex $date 0] % 100]
      }
    }
    short_hours {
      if { [string equal [lindex $date 3] {}] } {
        return {}
      } else {    
        set value [expr [lindex $date 3] % 12]
	if { $value == 0 } {
          return 12
	} else {
          return $value
	}
      }
    }
    ampm {
      if { [string equal [lindex $date 3] {}] } {
        return {}
      } else { 
        if { [lindex $date 3] > 11 } {
          return "pm"
        } else {
          return "am"
        }
      }
    }
    not_null {
      for { set i 0 } { $i < 6 } { incr i } {
        if { ![string equal [lindex $date $i] {}] } {
          return 1
        } 
      }
      return 0
    }
    sql_date {
      set value ""
      set format ""
      set space ""
      foreach { index sql_form } { 0 YYYY 1 MM 2 DD 3 HH24 4 MI 5 SS } {
        set piece [lindex $date $index]
        if { ![string equal $piece {}] } {
          append value $space
          append value $piece 
          append format $space
          append format $sql_form
          set space " "
	}
      }
      return "to_date('$value', '$format')"
    }
    linear_date {
      # Return a date in format "YYYY MM DD HH24 MI SS"
      # For use with karl's non-working form builder API
      set clipped_date [lrange $date 0 5]
      set ret [list]
      foreach fragment $clipped_date {
        if { [string equal $fragment {}] } {
          lappend ret 0
	} else {
          lappend ret $fragment
	}
      }
      return $ret
    }
    clock {
      set value ""
      # Unreliable !
      unpack $date
      if { ![string equal $year {}] && \
           ![string equal $month {}] && \
           ![string equal $day {}] } {
        append value "$month/$day/$year"
      }
      if { ![string equal $hours {}] && \
           ![string equal $minutes {}] } {
        append value " ${hours}:${minutes}"
        if { ![string equal $seconds {}] } {
          append value ":$seconds"
	}
      }
      return [clock scan $value]
    }
  }
}

# Perform date comparison; same syntax as string compare

ad_proc -public template::util::date::compare { date1 date2 } {

  set str_1 [lrange $date1 0 5]
  set str_2 [lrange $date2 0 5]

  return [string compare $date1 $date2]
}

# mutate properties of the Date object

ad_proc -public template::util::date::set_property { what date value } {

  # Erase leading zeroes from the value, but make sure that 00
  # is not completely erased
  set value [template::util::leadingTrim $value]

  switch $what {
    year       { return [lreplace $date 0 0 $value] }
    month      { return [lreplace $date 1 1 $value] }
    day        { return [lreplace $date 2 2 $value] }
    hours      { return [lreplace $date 3 3 $value] }
    minutes    { return [lreplace $date 4 4 $value] }
    seconds    { return [lreplace $date 5 5 $value] }
    format     { return [lreplace $date 6 6 $value] }
    short_year {
      if { $value < 69 } {
        return [lreplace $date 0 0 [expr $value + 2000]]
      } else {
        return [lreplace $date 0 0 [expr $value + 1900]]  
      }
    }
    short_hours {
      return [lreplace $date 3 3 $value]
    }
    ampm {
      if { [string equal [lindex $date 3] {}] } {
        return $date
      } else { 
        set hours [lindex $date 3]
        if { [string equal $value pm] && $hours < 12 } {
          return [lreplace $date 3 3 [expr $hours + 12]]
        } elseif { [string equal $value am] } {
          return [lreplace $date 3 3 [expr $hours % 12]]
	} else {
          return $date
        }
      }
    }
    clock {
      set old_date [clock format $value -format "%Y %m %d %H %M %S"]
      set new_date [list]
      foreach field $old_date {
        lappend new_date [template::util::leadingTrim $field]
      }
      lappend new_date [lindex $date 6]
      return $new_date
    }
    sql_date {
      set old_format [lindex $date 6]
      set new_date [list]
      foreach fragment $value {
        lappend new_date [template::util::leadingTrim $fragment]
      }
      lappend new_date $old_format
      return $new_date
    }
    now {
      return [template::util::date set_property clock $date [clock seconds]]
    }
  }

}

# Get the default ranges for all the numeric fields of a Date object

ad_proc -public template::util::date::defaultInterval { what } {
  switch $what {
    year        { return [list 2000 2010 1 ] }
    month       { return [list 1 12 1] }
    day         { return [list 1 31 1] }
    hours       { return [list 0 23 1] }
    minutes     { return [list 0 59 5] }
    seconds     { return [list 0 59 5] }
    short_year  { return [list 0 10 1] }
    short_hours { return [list 1 12 1] }
  }
}


# Set the variables for each field of the date object in 
# the calling frame
ad_proc -public template::util::date::unpack { date } {
  uplevel {
    set year    [lindex $date 0]
    set month   [lindex $date 1]
    set day     [lindex $date 2]
    set hours   [lindex $date 3]
    set minutes [lindex $date 4]
    set seconds [lindex $date 5]
    set format  [lindex $date 6]
  }
}

# Check if a value is less than zero, but return false
# if the value is an empty string
ad_proc -public template::util::negative { value } {
  if { [string equal $value {}] } {
    return 0
  } else {
    return [expr $value < 0]
  }
}

# Validate a date object. Return 1 if the object is valid,
# 0 otherwise. Set the error_ref variable to contain
# an error message, if any

ad_proc -public template::util::date::validate { date error_ref } {

  # If the date is empty, it's valid
  if { ![get_property not_null $date] } {
    return 1
  }

  variable fragment_formats

  upvar $error_ref error_msg

  unpack $date

  set error_msg ""
  set return_code 1

  foreach {field exp} { year "YYYY|YY" month "MM|MON|MONTH" day "DD" 
                      hours "HH24|HH12" minutes "MI" seconds "SS" } {

    # If the field is required, but missing, report an error
    if {  [string equal [set $field] {}] } {
      if { [regexp $exp $format match] } {
        append error_msg "No value supplied for $field<br>"
        set return_code 0
      }
    } else {
      # fields should only be integers
      if { ![regexp {^[0-9]+$} [set $field] match] } {
        append error_msg "The $field must be a non-negative integer<br>"  
        set return_code 0
        set $field {}
      }
    }
  }

  if { [template::util::negative $year] } {
    append error_msg "Year must be positive<br>"
    set return_code 0
  }

  if { ![string equal $month {}] } {
    if { $month < 1 || $month > 12 } {
      append error_msg "Month must be between 1 and 12<br>"
      set return_code 0
    } else {
      if { $year > 0 } { 
        if { ![string equal $day {}] } {
          set maxdays [get_property days_in_month $date]
          if { $day < 1 || $day > $maxdays } {
            append error_msg "The day must be between 1 and $maxdays for "
            append error_msg "the month of 
                              [get_property long_month_name $date] <br>"
            set return_code 0
	  }
        }
      }
    }
  }

  if { [template::util::negative $hours] || $hours > 23 } {
    append error_msg "Hours must be between 0 and 23<br>"
    set return_code 0
  } 

  if { [template::util::negative $minutes] || $minutes > 59 } {
    append error_msg "Minutes must be between 0 and 59<br>"
    set return_code 0
  } 

  if { [template::util::negative $seconds] || $seconds > 59 } {
    append error_msg "Seconds must be between 0 and 59<br>"
    set return_code 0
  } 

  return $return_code
}

# Pad a string with leading zeroes

ad_proc -public template::util::leadingPad { string size } {
  
  if { [string equal $string {}] } {
    return {}
  }

  set ret [string repeat "0" [expr $size - [string length $string]]]
  append ret $string
  return $ret

}  

# Trim the leading zeroes from the value, but preserve the value
# as "0" if it is "00"
ad_proc -public template::util::leadingTrim { value } {
  set empty [string equal $value {}]
  set value [string trimleft $value 0]
  if { !$empty && [string equal $value {}] } {
    set value 0
  }
  return $value
}

# Create an html fragment to display a numeric range widget
# interval_def is in form { start stop interval }

ad_proc -public template::widget::numericRange { name interval_def size {value ""} } {
  
  set options [list [list "--" {}]]

  for { set i [lindex $interval_def 0] } \
      { $i <= [lindex $interval_def 1] } \
      { incr i [lindex $interval_def 2] } {
    lappend options [list [template::util::leadingPad $i $size] $i]
  }

  return [template::widget::menu $name $options [list $value] {}]
}

# Create an input widget for the given date fragment
# If type is "t", uses a text widget for the fragment, with the given
# size.
# Otherwise, determines the proper widget based on the element flags,
# which may be text or a picklist

ad_proc -public template::widget::dateFragment {
  element_reference fragment size type value } {

  upvar $element_reference element
  
  set value [template::util::date::get_property $fragment $value]
  set value [template::util::leadingTrim $value]

  if { [info exists element(${fragment}_interval)] } {
    set interval $element(${fragment}_interval)
  } else {
     # Display text entry for some elements, or if the type is text
     if { [string equal $type t] ||
          [regexp "year|short_year" $fragment] } {
       return "<input type=text name=$element(name).$fragment size=$size 
     maxlength=$size value=\"[template::util::leadingPad $value $size]\">\n"
     } else {
     # Use a default range for others
       set interval [template::util::date::defaultInterval $fragment]
     }
  }

  return [template::widget::numericRange "$element(name).$fragment" \
           $interval $size $value]
}

# Create a widget that shows the am/pm selection
ad_proc -public template::widget::ampmFragment {
  element_reference fragment size type value } {

  upvar $element_reference element

  set value [template::util::date::get_property $fragment $value]

  return [template::widget::menu \
    "$element(name).$fragment" { {A.M. am} {P.M. pm}} $value {}]
}

# Create a month entry widget with short or long month names

ad_proc -public template::widget::monthFragment { 
  element_reference fragment size type value } {

  variable ::template::util::date::month_data

  upvar $element_reference element

  set value [template::util::date::get_property $fragment $value]

  set options [list [list "--" {}]]
  for { set i 1 } { $i <= 12 } { incr i } {
    lappend options [list [template::util::date::monthName $i $size] $i]
  }
 
  return [template::widget::menu \
   "$element(name).$fragment" $options $value {} ]
}

# Create a date entry widget according to a format string
# The format string should contain the following fields, separated
# by / \ - : . or whitespace:
# string   meaning
# YYYY     4-digit year
# YY       2-digit year
# MM       2-digit month
# MON      month name, short (i.e. "Jan")
# MONTH    month name, long (i.e. "January")
# DD       day of month
# HH12     12-hour hour
# HH24     24-hour hour
# MI       minutes
# SS       seconds
# AM       am/pm flag
# Any format field may be followed by "t", in which case a text 
# widget will be used to represent the field.
# the array in range_ref determines interval ranges; the keys
# are the date fields and the values are in form {start stop interval}

ad_proc -public template::widget::date { element_reference tag_attributes } {

  variable ::template::util::date::fragment_widgets

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set output "<!-- date $element(name) begin -->\n"

  if { ! [info exists element(format)] } { 
    set element(format) "DD MONTH YYYY" 
  }

  # Choose a pre-selected format, if any
  switch $element(format) {
    long     { set element(format) "YYYY/MM/DD HH24:MI:SS" }
    short    { set element(format) "YYYY/MM/DD"}
    time     { set element(format) "HH24:MI:SS"}
    american { set element(format) "MM/DD/YY"}
    expiration {
      set element(format) "MM/YY"
      set current_year [clock format [clock seconds] -format "%Y"]
      set current_year [expr $current_year % 100]
      set element(short_year_interval) \
        [list $current_year [expr $current_year + 10] 1]
      set element(help) 1 
    }
  }

  # Just remember the format for now - in the future, allow
  # the user to enter a freeform format
  append output "<input type=hidden name=$element(name).format "
  append output "value=\"$element(format)\">\n"
  append output "<table border=0 cellpadding=0 cellspacing=2>\n<tr>"

  # Prepare the value to set defaults on the form
  if { [info exists element(value)] && 
       [template::util::date::get_property not_null $element(value)] } {
    set value $element(value)
    foreach v $value {
      lappend trim_value [template::util::leadingTrim $v]
    }
    set value $trim_value
  } else {
    set value {}
  }

  # Keep taking tokens off the top of the string until out
  # of tokens
  set format_string $element(format)

  set tokens [list]

  while { ![string equal $format_string {}] } {

    # Snip off the next token
    regexp {([^/\-.: ]*)([/\-.: ]*)(.*)} \
          $format_string match word sep format_string
    # Extract the trailing "t", if any
    regexp -nocase $template::util::date::token_exp $word \
          match token type

    append output "<td nowrap>"
    
    lappend tokens $token

    # Output the widget
    set fragment_def $template::util::date::fragment_widgets([string toupper $token])
    set fragment [lindex $fragment_def 1]
    append output [template::widget::[lindex $fragment_def 0] \
                     element \
                     $fragment \
                     [lindex $fragment_def 2] \
                     $type \
                     $value]

    # Output the separator
    if { [string equal $sep " "] } {
      append output "&nbsp;"
    } else {
      append output "$sep"
    }

    append output "</td>\n"
  }

  append output "</tr>\n"

  # Append help text under each widget, if neccessary
  if { [info exists element(help)] } {
    append output "<tr>" 
    foreach token $tokens {
      set fragment_def $template::util::date::fragment_widgets($token)
      append output "<td nowrap align=center><font size=\"-2\">[lindex $fragment_def 3]</font></td>"
    }
    append output "</tr>\n"
  } 

  append output "</table>\n"

  append output "<!-- date $element(name) end -->\n"
  
  return $output

}

# Collect a Date object from the form

ad_proc -public template::data::transform::date { element_ref } {

  upvar $element_ref element
  set element_id $element(id)

  set the_date [template::util::date::create \
   {} {} {} {} {} {} [ns_queryget "$element_id.format"]]
  set have_values 0

  foreach field { 
    year short_year month day 
    short_hours hours minutes seconds ampm
  } {
     set key "$element_id.$field"    
     if { [ns_queryexists $key] } {
       set value [ns_queryget $key]
       # Coerce values to non-negative integers
       if { ![string equal $field ampm] } {
	 if { ![regexp {[0-9]+} $value value] } {
           set value {}
         }
       }
       # If the value is not null, set it
       if { ![string equal $value {}] } {
         set the_date [template::util::date::set_property $field $the_date $value]
         if { ![string equal $field ampm] } {
           set have_values 1
	 }
       }
     }
  }

  if { $have_values } {
    return [list $the_date]
  } else {
    return {}
  }
}

# Initialize the months array 

template::util::date::init
