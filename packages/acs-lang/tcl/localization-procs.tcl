#/packages/lang/tcl/localization-procs.tcl
ad_library {

    Routines for localizing numbers, dates and monetary amounts
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 30 September 2000
    @author Jeff Davis (davis@xarg.net) 
    @author Ashok Argent-Katwala (akatwala@arsdigita.com)
    @cvs-id $Id$
}


ad_proc -private ad_locale_escape_vars_if_not_null {
    list
} {
    Processes a list of variables before they are passed into
    a regexp command.

    @param list   List of variable names
} {
    foreach lm $list {
	upvar $lm foreign_var
	if { [exists_and_not_null foreign_var] } {
	    set foreign_var "\[$foreign_var\]"
	}
    }
}

ad_proc -public lc_parse_number { 
    num 
    locale 
    {integer_only_p 0}
} {
    Converts a number to its canonical 
    representation by stripping everything but the 
    decimal seperator and triming left 0's so it 
    won't be octal. It can process the following types of numbers:
    <ul>
    <li>Just digits (allows leading zeros).
    <li>Digits with a valid thousands separator, used consistently (leading zeros not allowed)
    <li>Either of the above with a decimal separator plus optional digits after the decimal marker
    </ul>
    The valid separators are taken from the given locale. Does not handle localized signed numbers in this version.
    The sign may only be placed before the number (with/without whitespace).
    Also allows the empty string, returning same.

    @param num      Localized number
    @param locale   Locale
    @param integer_only_p True if only integers returned
    @error          If unsupported locale or not a number
    @return         Canonical form of the number

} {
    if {[empty_string_p $num]} {
	return ""
    }

    # Any (usable) locale will have to have a decimal separator
    if {![nsv_exists locale "$locale,decimal_point"]} {
	error "Unsupported Locale"
    }

    set dec [nsv_get locale "$locale,decimal_point"]
    set thou [nsv_get locale "$locale,mon_thousands_sep"][nsv_get locale "$locale,thousands_sep"]
    set neg [nsv_get locale "$locale,negative_sign"]
    set pos [nsv_get locale "$locale,positive_sign"]

    ad_locale_escape_vars_if_not_null {dec thou neg pos}

    # Pattern actually looks like this (separators notwithstanding):
    # {^\ *([-]|[+])?\ *([0-9]+|[1-9][0-9]{1,2}([,][0-9]{3})+)([.][0-9]*)?\ *$}

    set pattern "^\\ *($neg|$pos)?\\ *((\[0-9\]+|\[1-9\]\[0-9\]{0,2}($thou\[0-9\]\{3\})+)"

    if {$integer_only_p} {
	append pattern "?)(${dec}0*)?"
    } else {
	append pattern "?($dec\[0-9\]*)?)"
    }

    append pattern "\\ *\$"

    set is_valid_number  [regexp -- $pattern $num match sign number]

    if {!$is_valid_number} {
	error "Not a number $num"
    } else {

	regsub -all "$thou" $number "" number

	if {!$integer_only_p} {
	    regsub -all "$dec" $number "." number
	}


	# Strip leading zeros
	regexp -- "0*(\[0-9\.\]+)" $number match number
	
	# if number is real and mod(number)<1, then we have pulled off the leading zero; i.e. 0.231 -> .231 -- this is still fine for tcl though...
	# Last pathological case
	if {![string compare "." $number]} {
	    set number 0
	}

	if {[string match "\\\\\\${sign}" $neg]} {
	    set number -$number
	}

	return $number
    }
}


ad_proc -private lc_sepfmt { 
    num 
    {grouping {3}}
    {sep ,} 
    {num_re {[0-9]}}
} { 
    Called by lc_numeric and lc_monetary.
    <p>
    Takes a grouping specifier and 
    inserts the given seperator into the string. 
    Given a separator of : 
    and a number of 123456789 it returns:
    <pre>
    grouping         Formatted Value
    {3 -1}               123456:789     
    {3}                  123:456:789    
    {3 2 -1}             1234:56:789    
    {3 2}                12:34:56:789   
    {-1}                 123456789      
    </pre>

    @param num        Number
    @param grouping   Grouping specifier
    @param sep        Thousands separator
    @param num_re     Regular expression for valid numbers
    @return           Number formatted with thousand separator
} {
    # with empty seperator or grouping string we behave 
    # posixly
    if {[empty_string_p $grouping] 
        || [empty_string_p $sep] } { 
        return $num
    }
    
    set match "^(-?$num_re+)("
    set group [lindex $grouping 0]
    
    while { 1 && $group > 0} { 
        set re "$match[string repeat $num_re $group])"
        if { ![regsub -- $re $num "\\1$sep\\2" num] } { 
            break 
        } 
        if {[llength $grouping] > 1} { 
            set grouping [lrange $grouping 1 end]
        }
        set group [lindex $grouping 0]
    } 
    return $num 
}


ad_proc -public lc_numeric {
    num 
    {fmt {}} 
    {locale ""}
} { 

    Given a number and a locale return a formatted version of the number
    for that locale.

    @param num      Number in canonical form
    @param fmt      Format string used by the tcl format 
                    command (should be restricted to the form "%.Nf" if present).
    @param locale   Locale
    @return         Localized form of the number

} { 
    if { ![exists_and_not_null locale] } {
        set locale [ad_conn locale]
    }
    
    if {![empty_string_p $fmt]} { 
        set out [format $fmt $num]
    } else { 
        set out $num
    }

    set sep [nsv_get locale "$locale,thousands_sep"]
    set dec [nsv_get locale "$locale,decimal_point"]
    set grouping [nsv_get locale "$locale,grouping"]
    
    regsub {\.} $out $dec out

    return [lc_sepfmt $out $grouping $sep]
}

ad_proc -public lc_monetary_currency {
    { -label_p 0 }
    { -style local }
    num currency locale
} {
    Formats a monetary amount, based on information held on given currency (ISO code), e.g. GBP, USD.

    @param label_p     Set switch to a true value if you want to specify the label used for the currency.
    @param style       Set to int to display the ISO code as the currency label. Otherwise displays
                       an HTML entity for the currency. The label parameter must be true for this
                       flag to take effect.
    @param num         Number to format as a monetary amount.
    @param currency    ISO currency code.
    @param locale      Locale used for formatting the number.
    @return            Formatted monetary amount
} {

    set row_returned [db_0or1row lc_currency_select {}]

    if { !$row_returned } {
	ns_log Notice "Unsupported monetary currency, defaulting digits to 2"
	set fractional_digits 2
	set html_entity ""
    }
    
    if { $label_p } {
	if {[string compare $style int] == 0} {
	    set use_as_label $currency
	} else {
	    set use_as_label $html_entity
	}
    } else {
	set use_as_label ""
    }
    
    return [lc_monetary -- $num $locale $fractional_digits $use_as_label]
}


ad_proc -private lc_monetary {
    { -label_p 0 }
    { -style local }
    num 
    locale 
    {forced_frac_digits ""} 
    {forced_currency_symbol ""}
} { 
    Formats a monetary amount.

    @param label       Specify this switch if you want to specify the label used for the currency.
    @param style       Set to int to display the ISO code as the currency label. Otherwise displays
                       an HTML entity for the currency. The label parameter must be specified for this
                       flag to take effect.
    @param num         Number to format as a monetary amount. If this number could be negative
                       you should put &quot;--&quot; in your call before it.
    @param currency    ISO currency code.
    @param locale      Locale used for formatting the number.
    @return            Formatted monetary amount
} { 

    if {![empty_string_p $forced_frac_digits] && [string is integer $forced_frac_digits]} {
	set dig $forced_frac_digits
    } else {
	# look up the digits
	if {[string compare $style int] == 0} { 
	    set dig [nsv_get locale "$locale,int_frac_digits"]
	} else { 
	    set dig [nsv_get locale "$locale,frac_digits"]
	}
    }

    # figure out if negative 
    if {$num < 0} { 
        set num [expr abs($num)]
        set neg 1
    } else { 
        set neg 0
    }
    
    # generate formatted number
    set out [format "%.${dig}f" $num]

    # look up the label if needed 
    if {[empty_string_p $forced_currency_symbol]} {
	if {$label_p} {
	    if {[string compare $style int] == 0} { 
		set sym [nsv_get locale "$locale,int_curr_symbol"]
	    } else { 
		set sym [nsv_get locale "$locale,currency_symbol"]
	    }
	} else { 
	    set sym {}
	}
    } else {
	set sym $forced_currency_symbol
    }

    # signorama
    if {$neg} { 
        set cs_precedes [nsv_get locale "$locale,n_cs_precedes"]
        set sep_by_space [nsv_get locale "$locale,n_sep_by_space"]
        set sign_pos [nsv_get locale "$locale,n_sign_posn"]
        set sign [nsv_get locale "$locale,negative_sign"]
    } else {
        set cs_precedes [nsv_get locale "$locale,p_cs_precedes"]
        set sep_by_space [nsv_get locale "$locale,p_sep_by_space"]
        set sign_pos [nsv_get locale "$locale,p_sign_posn"]
        set sign [nsv_get locale "$locale,positive_sign"]
    } 
    
    # decimal seperator
    set dec [nsv_get locale "$locale,mon_decimal_point"]
    regsub {\.} $out $dec out

    # commify
    set sep [nsv_get locale "$locale,mon_thousands_sep"]
    set grouping [nsv_get locale "$locale,mon_grouping"]
    set num [lc_sepfmt $out $grouping $sep]
    
    return [subst [nsv_get locale "money:$cs_precedes$sign_pos$sep_by_space"]]
}    

ad_proc -public clock_to_ansi {
    seconds
} {
    Convert a time in the Tcl internal clock seeconds format to ANSI format, usable by lc_time_fmt.
    
    @author Lars Pind (lars@pinds.com)
    @return ANSI (YYYY-MM-DD HH24:MI:SS) formatted date.
    @see lc_time_fmt
} {
    return [clock format $seconds -format "%Y-%m-%d %H:%M:%S"]
}

ad_proc -public lc_get  {
    key
} {
    Get a certain format string for the current locale.
    @param key the key of for the format string you want.
    @return the format string for the current locale.
    @see packages/acs-lang/tcl/localization-data-init.tcl
    @author Lars Pind (lars@pinds.com)
} {
    return [nsv_get locale "[ad_conn locale],$key"]
}

ad_proc -public lc_time_fmt {
    datetime 
    fmt 
    {locale ""}
} {
    Formats a time for the specified locale.

    @param datetime        Strictly in the form &quot;YYYY-MM-DD HH24:MI:SS&quot;.
                           Formulae for calculating day of week from the Calendar FAQ 
                           (<a href="http://www.tondering.dk/claus/calendar.html">http://www.tondering.dk/claus/calendar.html</a>)
    @param fmt             An ISO 14652 LC_TIME style formatting string:
    <pre>    
      %a           FDCC-set's abbreviated weekday name.
      %A           FDCC-set's full weekday name.
      %b           FDCC-set's abbreviated month name.
      %B           FDCC-set's full month name.
      %c           FDCC-set's appropriate date and time
                   representation.
      %C           Century (a year divided by 100 and truncated to
                   integer) as decimal number (00-99).
      %d           Day of the month as a decimal number (01-31).
      %D           Date in the format mm/dd/yy.
      %e           Day of the month as a decimal number (1-31 in at
                   two-digit field with leading <space> fill).
      %f           Weekday as a decimal number (1(Monday)-7).
      %F           is replaced by the date in the format YYYY-MM-DD
                   (ISO 8601 format)
      %h           A synonym for %b.
      %H           Hour (24-hour clock) as a decimal number (00-23).
      %I           Hour (12-hour clock) as a decimal number (01-12).
      %j           Day of the year as a decimal number (001-366).
      %m           Month as a decimal number (01-13).
      %M           Minute as a decimal number (00-59).
      %n           A <newline> character.
      %p           FDCC-set's equivalent of either AM or PM.
      %r           12-hour clock time (01-12) using the AM/PM
                   notation.
      %q           Long date without weekday (OpenACS addition to the standard)
      %Q           Long date with weekday (OpenACS addition to the standard)
      %S           Seconds as a decimal number (00-61).
      %t           A <tab> character.
      %T           24-hour clock time in the format HH:MM:SS.
      %u           Week number of the year as a decimal number with
                   two digits and leading zero, according to "week"
                   keyword.
      %U           Week number of the year (Sunday as the first day of
                   the week) as a decimal number (00-53).
      %w           Weekday as a decimal number (0(Sunday)-6).
      %W           Week number of the year (Monday as the first day of
                   the week) as a decimal number (00-53).
      %x           FDCC-set's appropriate date representation.
      %X           FDCC-set's appropriate time representation.
      %y           Year (offset from %C) as a decimal number (00-99).
      %Y           Year with century as a decimal number.
      %Z           Time-zone name, or no characters if no time zone is
                   determinable.
      %%           A <percent-sign> character.
    </pre>
    See also <pre>man strftime</pre> on a UNIX shell prompt for more of these abbreviations.
    @param locale          Locale identifier must be in the locale database
    @error                 Fails if given a non-existant locale or a malformed datetime
                           Doesn't check for impossible dates. Ask it for 29 Feb 1999 and it will tell you it was a Monday
                           (1st March was a Monday, it wasn't a leap year). Also it only works with the Gregorian calendar -
                           but that's reasonable, but could be a problem if you are running a seriously historical site 
                           (or have an 'on this day in history' style page that goes back a good few hundred years).
    @return                A date formatted for a locale
} {
    if { [empty_string_p $datetime] } {
        return ""
    }

    if { ![exists_and_not_null locale] } {
        set locale [ad_conn locale]
    }
    
    # Some initialisation...
    # Now, expect d_fmt, t_fmt and d_t_fmt to exist of the form in ISO spec
    # Rip $date into $lc_time_* as numbers, no leading zeroes
    set matchdate {([0-9]{4})\-0?(1?[0-9])\-0?([1-3]?[0-9])}
    set matchtime {0?([1-2]?[0-9]):0?([1-5]?[0-9]):0?([1-6]?[0-9])}
    set matchfull "$matchdate $matchtime"
    
    if {![nsv_exists locale "$locale,d_t_fmt"]} {
	ns_log Error "Unsupported locale: $locale; using site-wide default."
        set locale [lang::system::locale -site_wide]
        if {![nsv_exists locale "$locale,d_t_fmt"]} {
            error "Site-Wide locale $locale doesn't have date and time formats defined."
        }
    }
    
    set lc_time_p 1
    if {![regexp -- $matchfull $datetime match lc_time_year lc_time_month lc_time_days lc_time_hours lc_time_minutes lc_time_seconds]} {
	if {[regexp -- $matchdate $datetime match lc_time_year lc_time_month lc_time_days]} {
	    set lc_time_hours 0
	    set lc_time_minutes 0
	    set lc_time_seconds 0
	} else {
	    error "Invalid date: $datetime"
	}
    }

    set a [expr (14 - $lc_time_month) / 12]
    set y [expr $lc_time_year - $a]
    set m [expr $lc_time_month + 12*$a - 2]
    
    # day_no becomes 0 for Sunday, through to 6 for Saturday. Perfect for addressing zero-based lists pulled from locale info.
    set lc_time_day_no [expr (($lc_time_days + $y + ($y/4) - ($y / 100) + ($y / 400)) + ((31*$m) / 12)) % 7]

    # Strange that there is no localian way to get d_t_fmt_ampm out with %wotsit
    # Localian composites are dealt with in while loop below.
    set to_process $fmt
    
    # Unsupported number things
    set percent_match(W) ""
    set percent_match(U) ""
    set percent_match(u) ""
    set percent_match(j) ""
    
    # Composites, now directly expanded, note that writing for %r specifically would be quicker than what we have here.
    set percent_match(T) {[lc_leading_zeros $lc_time_hours 2]:[lc_leading_zeros $lc_time_minutes 2]:[lc_leading_zeros $lc_time_seconds 2]}
    set percent_match(D) {[lc_leading_zeros $lc_time_month 2]/[lc_leading_zeros $lc_time_month 2]/[lc_leading_zeros [expr $lc_time_year%100] 2]}
    set percent_match(F) {${lc_time_year}-[lc_leading_zeros $lc_time_month 2]-[lc_leading_zeros $lc_time_days 2]}
    set percent_match(r) {[lc_leading_zeros [lc_time_drop_meridian $lc_time_hours] 2]:[lc_leading_zeros $lc_time_minutes 2] [lc_time_name_meridian $locale $lc_time_hours]}

    # Direct Subst
    set percent_match(e) {[lc_leading_space $lc_time_days]}
    set percent_match(f) {[lc_wrap_sunday $lc_time_day_no]}
    set percent_match(Y) {$lc_time_year}

    # Plus padding
    set percent_match(d) {[lc_leading_zeros $lc_time_days 2]}
    set percent_match(H) {[lc_leading_zeros $lc_time_hours 2]}
    set percent_match(S) {[lc_leading_zeros $lc_time_seconds 2]}
    set percent_match(m) {[lc_leading_zeros $lc_time_month 2]}
    set percent_match(M) {[lc_leading_zeros $lc_time_minutes 2]}

    # Calculable values (based on assumptions above)
    set percent_match(C) {[expr int($lc_time_year/100)]}
    set percent_match(I) {[lc_leading_zeros [lc_time_drop_meridian $lc_time_hours] 2]}
    set percent_match(w) {[expr $lc_time_day_no]}
    set percent_match(y) {[lc_leading_zeros [expr $lc_time_year%100] 2]}
    set percent_match(Z) {}

    # Straight (localian) lookups
    set percent_match(a) {[lindex [nsv_get locale "$locale,abday"] $lc_time_day_no]}
    set percent_match(A) {[lindex [nsv_get locale "$locale,day"] $lc_time_day_no]}
    set percent_match(b) {[lindex [nsv_get locale "$locale,abmon"] [expr $lc_time_month-1]]}
    set percent_match(h) {[lindex [nsv_get locale "$locale,abmon"] [expr $lc_time_month-1]]}
    set percent_match(B) {[lindex [nsv_get locale "$locale,mon"] [expr $lc_time_month-1]]}
    set percent_match(p) {[lc_time_name_meridian $locale $lc_time_hours]}

    # Finally, static string replacements
    set percent_match(t) {\t}
    set percent_match(n) {\n}
    set percent_match(%) {%}
    
    set transformed_string ""
    while {[regexp -- {^(.*?)%(.)(.*)$} $to_process match done_portion percent_modifier remaining]} {
	
	switch -exact -- $percent_modifier {
	    x {
		append transformed_string $done_portion
		set to_process "[nsv_get locale "$locale,d_fmt"]$remaining"
	    }
	    X {
		append transformed_string $done_portion
		set to_process "[nsv_get locale "$locale,t_fmt"]$remaining"
	    }
	    c {
		append transformed_string $done_portion
		set to_process "[nsv_get locale "$locale,d_t_fmt"]$remaining"	
	    }
	    q {
		append transformed_string $done_portion
		set to_process "[nsv_get locale "$locale,dlong_fmt"]$remaining"	
	    }
	    Q {
		append transformed_string $done_portion
		set to_process "[nsv_get locale "$locale,dlongweekday_fmt"]$remaining"	
	    }
	    default {
		append transformed_string "${done_portion}[subst $percent_match($percent_modifier)]"
		set to_process $remaining
	    }
	}
    }
    
    # What is left to_process must be (%.)-less, so it should be included without transformation.
    append transformed_string $to_process
    
    return $transformed_string
}
    


ad_proc -public lc_time_utc_to_local {
    time_value 
    {tz ""}
} {
    Converts a Universal Time to local time for the specified timezone.

    @param time_value        UTC time in the ISO datetime format.
    @param tz                Timezone that must exist in tz_data table.
    @return                  Local time
} {
    if { [empty_string_p $tz] } {
        set tz [lang::conn::timezone]
    }

    set local_time $time_value

    if {[catch {
	set local_time [db_exec_plsql utc_to_local {}]
    } errmsg]
    } {
	ns_log Notice "Query exploded on time conversion from UTC, probably just an invalid date, $time_value: $errmsg"
    }

    if {[empty_string_p $local_time]} {
	# If no conversion possible, log it and assume local is as given (i.e. UTC)	    
	ns_log Notice "Timezone adjustment in ad_localization.tcl found no conversion to UTC for $time_value $tz"	
    }

    return $local_time
}

ad_proc -public lc_time_local_to_utc {
    time_value 
    {tz ""}
} {
    Converts a local time to a UTC time for the specified timezone.

    @param time_value        Local time in the ISO datetime format, YYYY-MM-DD HH24:MI:SS
    @param tz                Timezone that must exist in tz_data table.
    @return                  UTC time.
} {
    if { [empty_string_p $tz] } {
        set tz [lang::conn::timezone]
    }

    set utc_time $time_value
    if {[catch {
	set utc_time [db_exec_plsql local_to_utc {}]
    } errmsg]
    } {
	ns_log Notice "Query exploded on time conversion to UTC, probably just an invalid date, $time_value: $errmsg"
    }

    if {[empty_string_p $utc_time]} {
	# If no conversion possible, log it and assume local is as given (i.e. UTC)	    
	ns_log Notice "Timezone adjustment in ad_localization.tcl found no conversion to local time for $time_value $tz"	
    }

    return $utc_time
}

ad_proc -public lc_list_all_timezones { } {
    @return list of pairs containing all  timezone names and offsets.
    Data drawn from acs-reference package timezones table
} {
    return [db_list_of_lists all_timezones {}]
}



ad_proc -private lc_time_drop_meridian { hours } {
    Converts HH24 to HH12.
} {
    if {$hours>12} {
	incr hours -12
    } elseif {$hours==0} {
	set hours 12
    }
    return $hours
}

ad_proc -private lc_wrap_sunday { day_no } {
    To go from 0(Sun) - 6(Sat)
    to 1(Mon) - 7(Sun)
} {
    if {$day_no==0} {
	return 7
    } else {
	return $day_no
    }
}

ad_proc -private lc_time_name_meridian { locale hours } {
    Returns locale data depending on AM or PM.
} {
    if {$hours > 11} {
	return [nsv_get locale "$locale,pm_str"]
    } else {
	return [nsv_get locale "$locale,am_str"]
    }
}

ad_proc -private lc_leading_space {num} {
    Inserts a leading space for numbers less than 10.
} {
    if {$num < 10} {
	return " $num"
    } else {
	return $num
    }
}


ad_proc -private lc_leading_zeros {
    the_integer 
    n_desired_digits
} {
    Adds leading zeros to an integer to give it the desired number of digits
} {
    return [format "%0${n_desired_digits}d" $the_integer]
}
