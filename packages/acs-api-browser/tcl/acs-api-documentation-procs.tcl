# /packages/acs-core/api-documentation-procs.tcl

ad_library {

    Routines for generating API documentation.

    @author Jon Salz (jsalz@mit.edu)
    @author Lars Pind (lars@arsdigita.com)
    @creation-date 21 Jun 2000
    @cvs-id $Id$

}

ad_proc -private api_first_sentence { string } {

    Returns the first sentence of a string.

} {

    if { [regexp {^(.+?\.)\s} $string "" sentence] } {
	return $sentence
    }
    return $string
}

ad_proc -public api_read_script_documentation {
    path
} {

    Reads the contract from a Tcl content page.

    @param path the path of the Tcl file to examine, relative to the
        ACS root directory.
    @return a list representation of the documentation element array, or
        an empty list if the file does not contain a <code>doc_page_contract</code>
        block.
    @error if the file does not exist.

} {
    # First, examine the file to determine whether the first non-comment
    # line begins with the string "ad_page_contract".
    set has_contract_p 0

    if { ![file exists "[acs_root_dir]/$path"] } {
	return -code error "File $path does not exist"
    }

    set file [open "[acs_root_dir]/$path" "r"]
    while { [gets $file line] >= 0 } {
	# Eliminate any comment characters.
	regsub -all {#.*$} $line "" line
	set line [string trim $line]
	if { ![empty_string_p $line] } {
	    set has_contract_p [regexp {^ad_page_contract\s} $line]
	    break
	}
    }
    close $file

    if { !$has_contract_p } {
	return [list]
    } 

    doc_set_page_documentation_mode 1
    set errno [catch { source "[acs_root_dir]/$path" } error]
    doc_set_page_documentation_mode 0
    if { $errno == 1 } {
	global errorInfo
	if { [regexp {^ad_page_contract documentation} $errorInfo] } {
	    array set doc_elements $error
	}
    } else {
	global errorCode
	global errorInfo
	return -code $errno -errorcode $errorCode -errorinfo $errorInfo $error
 }

    if { [info exists doc_elements] } {
	return [array get doc_elements]
    }
    return [list]
}

ad_proc -private api_format_author_list { authors } {

    Generates an HTML-formatted list of authors (including <code>&lt;dt&gt;</code> and
    <code>&lt;dd&gt;</code> tags).

    @param authors the list of author strings.
    @return the formatted list, or an empty string if there are no authors.

} {
    if { [llength $authors] == 0 } {
	return ""
    }
    append out "<dt><b>Author[ad_decode [llength $authors] 1 "" "s"]:</b>\n"
    foreach author $authors {
	append out "<dd>[api_format_author $author]\n"
    }
    return $out
}


ad_proc -private api_format_changelog_change { change } {
    Formats the change log line: turns email addresses in parenthesis into links.
} { 
    regsub {\(([^ \n\r\t]+@[^ \n\r\t]+\.[^ \n\r\t]+)\)} $change {(<a href="mailto:\1">\1</a>)} change
    return $change
}

ad_proc -private api_format_changelog_list { changelog } {
    Format the change log info
} {
    append out "<dt><b>Changelog:</b>\n"
    foreach change $changelog {
	append out "<dd>[api_format_changelog_change $change]\n"
    }
    return $out
}


ad_proc -private api_format_common_elements { doc_elements_var } {
    upvar $doc_elements_var doc_elements

    set out ""

    if { [info exists doc_elements(author)] } {
	append out [api_format_author_list $doc_elements(author)]
    }
    if { [info exists doc_elements(creation-date)] } {
	append out "<dt><b>Created:</b>\n<dd>[lindex $doc_elements(creation-date) 0]\n"
    }
    if { [info exists doc_elements(change-log)] } {
	append out [api_format_changelog_list $doc_elements(change-log)]
    }
    if { [info exists doc_elements(cvs-id)] } {
	append out "<dt><b>CVS ID:</b>\n<dd><code>[ns_quotehtml [lindex $doc_elements(cvs-id) 0]]</code>\n"
    }

    return $out
}

ad_proc -public api_script_documentation {
    { -format text/html }
    path
} {

    Generates formatted documentation for a content page. Sources the file
    to obtain the comment or contract at the beginning.

    @param format the type of documentation to generate. Currently, only
        <code>text/html</code> is supported.
    @param path the path of the Tcl file to examine, relative to the
        ACS root directory.
    @return the formatted documentation string.
    @error if the file does not exist.

} {
    append out "<h3>[file tail $path]</h3>\n"

    # If it's not a Tcl file, we can't do a heck of a lot yet. Eventually
    # we'll be able to handle ADPs, at least.
    if { ![string equal [file extension $path] ".tcl"] } {
	append out "<blockquote><i>Delivered as [ns_guesstype $path]</i></blockquote>\n"
	return $out
    }

    if { [catch { array set doc_elements [api_read_script_documentation $path] } error] } {
	append out "<blockquote><i>Unable to read $path: [ns_quotehtml $error]</i></blockquote>\n"
	return $out
    }

    array set params [list]

    if { [info exists doc_elements(param)] } {
	foreach param $doc_elements(param) {
	    if { [regexp {^([^ \t]+)[ \t](.+)$} $param "" name value] } {
		set params($name) $value
	    }
	}
    }
	
    append out "<blockquote>"
    if { [info exists doc_elements(main)] } {
	append out [lindex $doc_elements(main) 0]
    } else {
	append out "<i>Does not contain a contract.</i>"
    }
    append out "<dl>\n"
    # XXX: This does not work at the moment. -bmq
#     if { [array size doc_elements] > 0 } {
#         array set as_flags $doc_elements(as_flags)
# 	array set as_filters $doc_elements(as_filters)
#         array set as_default_value $doc_elements(as_default_value)

#         if { [llength $doc_elements(as_arg_names)] > 0 } {
# 	    append out "<dt><b>Query Parameters:</b><dd>\n"
# 	    foreach arg_name $doc_elements(as_arg_names) {
# 		append out "<b>$arg_name</b>"
# 		set notes [list]
# 		if { [info exists as_default_value($arg_name)] } {
# 		    lappend notes "defaults to <code>\"$as_default_value($arg_name)\"</code>"
# 		} 
#  		set notes [concat $notes $as_flags($arg_name)]
# 		foreach filter $as_filters($arg_name) {
# 		    set filter_proc [ad_page_contract_filter_proc $filter]
# 		    lappend notes "<a href=\"[api_proc_url $filter_proc]\">$filter</a>"
# 		}
# 		if { [llength $notes] > 0 } {
# 		    append out " ([join $notes ", "])"
# 		}
# 		if { [info exists params($arg_name)] } {
# 		    append out " - $params($arg_name)"
# 		}
# 		append out "<br>\n"
# 	    }
# 	    append out "</dd>\n"
# 	}
# 	if { [info exists doc_elements(type)] && ![empty_string_p $doc_elements(type)] } {
# 	    append out "<dt><b>Returns Type:</b><dd><a href=\"type-view?type=$doc_elements(type)\">$doc_elements(type)</a>\n"
# 	}
# 	# XXX: Need to support "Returns Properties:"
#     }
    append out "<dt><b>Location:</b><dd>$path\n"
    append out [api_format_common_elements doc_elements]

    append out "</dl></blockquote>"

    return $out
}

ad_proc -private api_format_author { author_string } {
    if { [regexp {^[^ \n\r\t]+$} $author_string] && \
	    [string first "@" $author_string] >= 0 && \
	    [string first ":" $author_string] < 0 } {
	return "<a href=\"mailto:$author_string\">$author_string</a>"
    } elseif { [regexp {^([^\(\)]+)\s+\((.+)\)$} [string trim $author_string] {} name email] } {
	return "$name &lt;<a href=\"mailto:$email\">$email</a>&gt;"
    }
    return $author_string
}

ad_proc -public api_library_documentation {
    { -format text/html }
    path
} {

    Generates formatted documentation for a Tcl library file (just the header,
    describing what the library does).

    @param path the path to the file, relative to the ACS path root.

} {
    if { ![string equal $format "text/html"] } {
	return -code error "Only text/html documentation is currently supported"
    }

    set out "<h3>[file tail $path]</h3>"
    
    if { [nsv_exists api_library_doc $path] } {
	array set doc_elements [nsv_get api_library_doc $path]
	append out "<blockquote>\n"
	append out [lindex $doc_elements(main) 0]

	append out "<dl>\n"
	append out "<dt><b>Location:</b>\n<dd>$path\n"
	if { [info exists doc_elements(creation-date)] } {
	    append out "<dt><b>Created:</b>\n<dd>[lindex $doc_elements(creation-date) 0]\n"
	}
	if { [info exists doc_elements(author)] } {
	    append out "<dt><b>Author[ad_decode [llength $doc_elements(author)] 1 "" "s"]:</b>\n"
	    foreach author $doc_elements(author) {
		append out "<dd>[api_format_author $author]\n"
	    }
	}
	if { [info exists doc_elements(cvs-id)] } {
	    append out "<dt><b>CVS Identification:</b>\n<dd><code>[ns_quotehtml [lindex $doc_elements(cvs-id) 0]]</code>\n"
	}
	append out "</dl>\n"
	append out "</blockquote>\n"
    }

    return $out
}

ad_proc -public api_type_documentation {
    type
} {
    array set doc_elements [nsv_get doc_type_doc $type]
    append out "<h3>$type</h3>\n"

    array set properties [nsv_get doc_type_properties $type]

    append out "<blockquote>[lindex $doc_elements(main) 0]

<dl>
<dt><b>Properties:</b>
<dd>
"

    array set property_doc [list]
    if { [info exists doc_elements(property)] } {
	foreach property $doc_elements(property) {
	    if { [regexp {^([^ \t]+)[ \t](.+)$} $property "" name value] } {
		set property_doc($name) $value
	    }
	}
    }

    foreach property [lsort [array names properties]] {
	set info $properties($property)
	set type [lindex $info 0]
	append out "<b>$property</b>"
	if { ![string equal $type "onevalue"] } {
	    append out " ($type)"
	}
	if { [info exists property_doc($property)] } {
	    append out " - $property_doc($property)"
	}
	if { [string equal $type "onerow"] } {
	    append out "<br>\n"
	} else {
	    set columns [lindex $info 1]
	    append out "<ul type=disc>\n"
	    foreach column $columns {
		append out "<li><b>$column</b>"
		if { [info exists property_doc($property.$column)] } {
		    append out " - $property_doc($property.$column)"
		}
	    }
	    append out "</ul>\n"
	}
    }

    append out [api_format_common_elements doc_elements]

    append out "<dt><b>Location:</b><dd>$doc_elements(script)\n"

    append out "</dl></blockquote>\n"

    return $out
}

ad_proc -private api_set_public {
    version_id
    { public_p "" }
} {
    
    Gets or sets the user's public/private preferences for a given
    package.

    @param version_id the version of the package
    @param public_p if empty, return the user's preferred setting or the default (1) if no preference found. If not empty, set the user's preference to public_p
    @return public_p

} {
    set public_property_name "api,package,$version_id,public_p"
    if { [empty_string_p $public_p] } {
	set public_p [ad_get_client_property acs-api-browser $public_property_name]
	if { [empty_string_p $public_p] } {
	    set public_p 1
	}
    } else {
	ad_set_client_property acs-api-browser $public_property_name $public_p
    }
    return $public_p
}

ad_proc -public api_proc_documentation {
    { -format text/html }
    -script:boolean
    -source:boolean
    proc_name
} {

    Generates formatted documentation for a procedure.

    @param format the type of documentation to generate. Currently, only
        <code>text/html</code> and <code>text/plain</text> is supported.
    @param script include information about what script this proc lives in?
    @param source include the source code for the script?
    @param proc_name the name of the procedure for which to generate documentation.
    @return the formatted documentation string.
    @error if the procedure is not defined.    

} {
    if { ![string equal $format "text/html"] && \
            ![string equal $format "text/plain"] } {
	return -code error "Only text/html and text/plain documentation are currently supported"
    }
    array set doc_elements [nsv_get api_proc_doc $proc_name]
    array set flags $doc_elements(flags)
    array set default_values $doc_elements(default_values)

    if { $script_p } {
	append out "<h3>[api_proc_pretty_name $proc_name]</h3>"
    } else {
	append out "<h3>[api_proc_pretty_name -link $proc_name]</h3>"
    }

    lappend command_line $proc_name
    foreach switch $doc_elements(switches) {
	if { [lsearch $flags($switch) "boolean"] >= 0 } {
	    lappend command_line "\[ -$switch \]"
	} elseif { [lsearch $flags($switch) "required"] >= 0 } {
	    lappend command_line "-$switch <i>$switch</i>"
	} else {
	    lappend command_line "\[ -$switch <i>$switch</i> \]"
	}
    }

    set counter 0
    foreach positional $doc_elements(positionals) {
	if { [info exists default_values($positional)] } {
	    lappend command_line "\[ <i>$positional</i> \]"
	} else {
	    lappend command_line "<i>$positional</i>"
	}
    }
    if { $doc_elements(varargs_p) } {
	lappend command_line "\[ <i>args</i>... \]"
    }
    append out "[util_wrap_list $command_line]\n<blockquote>\n"

    if { $script_p } {
	append out "Defined in <a href=\"/api-doc/procs-file-view?path=[ns_urlencode $doc_elements(script)]\">$doc_elements(script)</a><p>"
    }

    if { $doc_elements(deprecated_p) } {
	append out "<b><i>Deprecated."
	if { $doc_elements(warn_p) } {
	    append out " Invoking this procedure generates a warning."
	}
	append out "</i></b><p>\n"
    }

    append out "[lindex $doc_elements(main) 0]

<p>
<dl>
"

    if { [info exists doc_elements(param)] } {
	foreach param $doc_elements(param) {
	    if { [regexp {^([^ \t]+)[ \t](.+)$} $param "" name value] } {
		set params($name) $value
	    }
	}
    }

    if { [llength $doc_elements(switches)] > 0 } {
	append out "<p><dt><b>Switches:</b></dt><dd>\n"
	foreach switch $doc_elements(switches) {
	    append out "<b>-$switch</b>"
	    if { [lsearch $flags($switch) "boolean"] >= 0 } {
		append out " (boolean)"
	    } elseif { [info exists default_values($switch)] && \
		    ![empty_string_p $default_values($switch)] } {
		append out " (defaults to <code>\"$default_values($switch)\"</code>)"
	    } elseif { ![lsearch $flags($switch) "required"] >= 0 } {
		append out " (optional)"
	    }
	    if { [info exists params($switch)] } {
		append out " - $params($switch)"
	    }
	    append out "<br>\n"
	}
	append out "</dd>\n"
    }

    if { [llength $doc_elements(positionals)] > 0 } {
	append out "<p><dt><b>Parameters:</b></dt><dd>\n"
	foreach positional $doc_elements(positionals) {
	    append out "<b>$positional</b>"
	    if { [info exists default_values($positional)] } {
		if { [empty_string_p $default_values($positional)] } {
		    append out " (optional)"
		} else {
		    append out " (defaults to <code>\"$default_values($positional)\"</code>)"
		}
	    }
	    if { [info exists params($positional)] } {
		append out " - $params($positional)"
	    }
	    append out "<br>\n"
	}
	append out "</dd>\n"
    }

    if { [info exists doc_elements(return)] } {
	append out "<dt><b>Returns:</b></dt><dd>[join $doc_elements(return) "<br>"]</dd>\n"
    }

    if { [info exists doc_elements(error)] } {
	append out "<dt><b>Error:</b></dt><dd>[join $doc_elements(error) "<br>"]</dd>\n"
    }

    append out [api_format_common_elements doc_elements]

    if { $source_p } {
	append out "<p><dt><b>Source code:</b></dt><dd>
<pre>[ns_quotehtml [info body $proc_name]]<pre>
</dd><p>\n"
    }

    # No "see also" yet.

    append out "</dl></blockquote>"

    return $out
}

ad_proc api_proc_pretty_name { 
    -link:boolean
    proc 
} {
    Return a pretty version of a proc name
} {
    if { $link_p } {
	append out "<a href=\"[api_proc_url $proc]\">$proc</a>"
    } else {	
	append out "$proc"
    }
    array set doc_elements [nsv_get api_proc_doc $proc]
    if { $doc_elements(public_p) } {
	append out " (public)"
    }
    if { $doc_elements(private_p) } {
	append out " (private)"
    }
    return $out
}

ad_proc -private ad_sort_by_score_proc {l1 l2} {
    basically a -1,0,1 result comparing the second element of the
    list inputs then the first. (second is int)
} {
    if {[lindex $l1 1] == [lindex $l2 1]} {
	return [string compare [lindex $l1 0] [lindex $l2 0]]
    } else {
	if {[lindex $l1 1] > [lindex $l2 1]} {
	    return -1
	} else {
	    return 1
	}
    }
}

ad_proc -private ad_sort_by_second_string_proc {l1 l2} {
    basically a -1,0,1 result comparing the second element of the
    list inputs then the first (both strings)
} {
    if {[string equal [lindex $l1 1] [lindex $l2 1]]} {
	return [string compare [lindex $l1 0] [lindex $l2 0]]
    } else {
	return [string compare [lindex $l1 1] [lindex $l2 1]]
    }
}

ad_proc -private ad_sort_by_first_string_proc {l1 l2} {
    basically a -1,0,1 result comparing the second element of the
    list inputs then the first.  (both strings)
} {
    if {[string equal [lindex $l1 0] [lindex $l2 0]]} {
	return [string compare [lindex $l1 1] [lindex $l2 1]]
    } else {
	return [string compare [lindex $l1 0] [lindex $l2 0]]
    }
}

ad_proc -private ad_keywords_score {keywords string_to_search} {
    returns number of keywords found in string to search.  
    No additional score for repeats
} {
    # turn keywords into space-separated things
    # replace one or more commads with a space
    regsub -all {,+} $keywords " " keywords
    
    set score 0
    foreach word $keywords {
	# turns out that "" is never found in a search, so we
	# don't really have to special case $word == ""
	if {[string match -nocase "*$word*" $string_to_search]} {
	    incr score
	}
    }
    return $score
}

ad_proc -public api_apropos_functions { string } {
    Returns the functions in the system that contain string in their name 
    and have been defined using ad_proc.
} {
    set matches [list]
    foreach function [nsv_array names api_proc_doc] {
        if [string match -nocase *$string* $function] {
            array set doc_elements [nsv_get api_proc_doc $function]
            lappend matches [list "$function" "$doc_elements(positionals)"]
        }
    }
    return $matches
}

ad_proc -public api_describe_function { 
    { -format text/plain }
    proc 
} {
    Describes the functions in the system that contain string and that
    have been defined using ad_proc.  The description includes the
    documentation string, if any.
} {
    set matches [list]
    foreach function [nsv_array names api_proc_doc] {
        if {[string match -nocase $proc $function]} {
            array set doc_elements [nsv_get api_proc_doc $function]
            switch $format {
                text/plain {
                    lappend matches [ad_html_to_text [api_proc_documentation -script $function]]
                }
                default {
                    lappend matches [api_proc_documentation -script $function]
                }
            }                    
        }
    }
    switch $format {
        text/plain {
            set matches [join $matches "\n"]
        }
        default {
            set matches [join $matches "\n<p>\n"]
        }
    }
    return $matches
}

####################
#
# Linking to api-documentation
#
####################

#
# procs for linking to libraries, pages, etc, should go here too.
#

ad_proc api_proc_url { proc } {
    Returns the URL of the page that documents the given proc.

    @author Lars Pind (lars@pinds.com)
    @creation-date 14 July 2000
} {
    return "/api-doc/proc-view?proc=[ns_urlencode $proc]"
}

ad_proc api_proc_link { proc } {
    Returns a full HTML link to the documentation for the proc.

    @author Lars Pind (lars@pinds.com)
    @creation-date 14 July 2000
} {
    return "<a href=\"[api_proc_url $proc]\">$proc</a>"
}
