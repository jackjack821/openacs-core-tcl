# ADP to Tcl Compiler for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)
#          Stanislav Freidin (sfreidin@arsdigita.com)
# Based on the original ADP to Tcl compiler by Jon Salz (jsalz@mit.edu)

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_proc -private template::adp_parse { __adp_stub __args } {
    Execute procedures to prepare data sources and then to output
    template.

    @param __adp_stub   The root (without the file extension) of the
                        absolute path to the template and associated code.
    @param __args       One list containing any number of key-value pairs 
                        passed to an included template from its container.  
                        All data sources may be passed by reference.
} {
  # declare any variables passed in to an include or master
  # TODO: call adp_set_vars instead.

  foreach {__key __value} $__args {
    if {[string match "&*" $__key]} {	# "&" triggers call by reference
      if {[string compare "&" $__key]} {
	set __name [string range $__key 1 end]
      } else {
	set __name $__value
      }
      upvar \#[adp_level] $__value $__name \
	  $__value:rowcount $__name:rowcount \
	  $__value:columns  $__name:columns
      # upvar :rowcount and :columns just in case it is a multirow
      if { [info exists $__name:rowcount] } {
	for { set __i 0 } { $__i <= [set $__name:rowcount] } { incr __i } {
	  upvar \#[adp_level] $__value:$__i $__name:$__i
	}
      }
    } else {				# not "&" => normal arg (no reference)
      set $__key $__value
    }
  }

  # set the stack frame at which the template is being parsed so that
  # other procedures can reference variables cleanly
  variable parse_level
  lappend parse_level [info level]

  # execute the code to prepare the data sources for a template
  if { [catch { adp_prepare } errMsg] } {

    # return without rendering any HTML if the code aborts
    if { [string equal $errMsg ADP_ABORT] } { 
      return "" 
    } else {
      global errorInfo errorCode
      error $errMsg $errorInfo $errorCode
    }
  }
  # if we get here, adp_prepare ran without throwing an error.
  # and errMsg contains its return value

  # initialize the ADP output
  set __adp_output ""

  set mime_type [get_mime_type]
  set template_extension [get_mime_template_extension $mime_type]

  # generate ADP output if a template exists (otherwise assume plain Tcl page)

  if {[file exists "$__adp_stub.$template_extension"]} { # it's a templated page

    # ensure that template output procedure exists and is up-to-date
    template::adp_init $template_extension $__adp_stub
  
    # get result of template output procedure into __adp_output
    template::code::${template_extension}::$__adp_stub
  
    # call the master template if one has been defined
    if { [info exists __adp_master] } {

      # pass properties on to master template
      set __adp_output [template::adp_parse $__adp_master \
        [concat [list __adp_slave $__adp_output] [array get __adp_properties]]]
    }
  } {
    # no template;  errMsg tells us if adp_prepare at least found a script.
    if !$errMsg { error "No script or template found for page '$__adp_stub'"}
  }

  # pop off parse level
  template::util::lpop parse_level

  return $__adp_output				; # empty in non-templated page
}

ad_proc -private template::adp_set_vars {} {
    Set variables passes from a container template, including onerow and
    multirow data sources.  This code must be executed in the same stack frame
    as adp_parse, but is in a separate proc to improve code readability.
} {
  uplevel {
    set __adp_level [adp_level 2]
    foreach {__adp_key __adp_value} $args {
      
      set __adp_expr {^@([A-Za-z0-9_]+)\.\*@$}
      if { [regexp  $__adp_expr $__adp_value __adp_x __adp_name] } {

	upvar #$__adp_level $__adp_name $__adp_key
	if { ! [array exists $__adp_key] } { 

	  upvar #$__adp_level $__adp_name:rowcount $__adp_key:rowcount
	
	  if { [info exists $__adp_key:rowcount] } { 

	    set size [set $__adp_key:rowcount]

	    for { set i 1 } { $i <= [set $__adp_key:rowcount] } { incr i } {
	      upvar #$__adp_level $__adp_name:$i $__adp_key:$i
	    }
	  }
	}
      } else {
	set $__adp_key $__adp_value 
      }
    }
  }
}
# Terminates processing of a template and throws away all output.

ad_proc -public template::adp_abort {} {
  Terminates processing of a template and throws away all output.
} { 
  error ADP_ABORT 
}

ad_proc -public template::adp_eval { coderef } {
    Evaluates a chunk of compiled template code in the calling stack frame.
    The resulting output is placed in __adp_output in the calling frame,
    and also returned for convenience.

    @return The output produced by the compiled template code.
} {
  upvar $coderef code

  eval "uplevel {

    variable ::template::parse_level
    lappend ::template::parse_level \[info level\]

    $code

    template::util::lpop ::template::parse_level
  }"

  upvar __adp_output output

  return $output
}

ad_proc -public template::adp_level { { up "" } } {
    Get the stack frame level at which the template is being evaluated.
    This is used extensively for obtaining references to data sources,
    as well template objects such as forms and wizards

    @param up A relative reference to the "parse level" of interest.
    	    Useful in the context of an included template to reach into the
    	    stack frame in which the container template is being parsed, for
    	    accessing data sources or other objects.  The default is the 
              highest parse level.

    @return A number, as returned by [info level], representing the stack frame
            in which a template is being parsed.
} {
  set result ""

  variable parse_level
  # when serving a page, this variable is always defined.
  # but we need to check it for the case of isolated compilation

  if { [info exists parse_level] } {
    if { [string equal $up "" ] } {
      set result [lindex $parse_level end]
    } else {
      set result [lindex $parse_level [expr [llength $parse_level] - $up]]
    }
  }

  return $result
}


ad_proc -public template::adp_levels {} {
    @return all stack frame levels
} {
  variable parse_level
  if { [info exists parse_level] } {return $parse_level}
  return ""
}

ad_proc -private template::adp_prepare {} {
    Executes the code to prepare the data sources for a template.  The
    code is executed in the stack frame of the calling procedure
    (adp_parse) so that variables are accessible when the compiled
    template code is executed.  If the preparation code executes the
    set_file command, the procedure will recurse and execute the code
    for the next template as well.

    @return boolean (0 or 1): whether the (ultimate) script was found.
} {
  uplevel {

    if { [file exists $__adp_stub.tcl] } {

      # ensure that data source preparation procedure exists and is up-to-date
      adp_init tcl $__adp_stub

      # remember the file_stub in case the procedure changes it
      set __adp_remember_stub $__adp_stub

      # execute data source preparation procedure
      code::tcl::$__adp_stub

      # propagate aborting
      global request_aborted
      if [info exists request_aborted] {
	ns_log warning "propagating abortion from $__adp_remember_stub.tcl\
          (status [lindex $request_aborted 0]): '[lindex $request_aborted 1]')"
	adp_abort
      }
     
      # if the file has changed than prepare again
      if { ! [string equal $__adp_stub $__adp_remember_stub] } {
	adp_prepare;			# propagate result up
      } { return 1 }
    }
    return 0
  }
}

ad_proc -public template::set_file { path } {
    Set the path of the template to render.  This is typically used to
    implement multiple "skins" on a common set of data sources.  The
    initial code (which may be in a .tcl file not associated with a .adp
    file) sets up any number of data sources, and then calls set_file to
    specify the template to actually render.  Any code associated with
    the specified template is executed in the same stack frame as the
    initial code, so that each "skin" may reference additional specific
    data or logic as necessary.

    @param path The root (sans file extension) of the absolute path to the 
                next template to parse.
} {
  set level [adp_level]

  upvar #$level __adp_stub file_stub
  set file_stub $path
}

ad_proc -private template::adp_init { type file_stub } {
    Ensures that both data source tcl files and compiled adp templates
    are wrapped in procedures in the current interpreter.  Procedures
    are cached in byte code form in the interpreter, so this is more
    efficient than sourcing a tcl file or parsing the template every
    time.  Also checks the modification time on the source file to
    ensure that the procedure is up-to-date.

    @param type       Either adp (template) or tcl (code)
    @param file_stub  The root (sans file extension) of the absolute path
                      to the .adp or .tcl file to source.
} { 
  # this will return the name of the proc if it exists
  set proc_name [info procs ::template::mtimes::${type}::$file_stub]

  set pkg_id [apm_package_id_from_key acs-templating]
  set refresh_cache [ad_parameter -package_id $pkg_id RefreshCache dummy\
			 "when needed"]

  if {[string equal $proc_name {}] || [string compare $refresh_cache "never"]} {
    set mtime [file mtime $file_stub.$type]
    if {[string equal $proc_name {}] || $mtime != [$proc_name]
	|| [string equal $refresh_cache "always"]} {

      # either the procedure does not already exist or is not up-to-date

      switch -exact $type {

	tcl {
	  set code [template::util::read_file $file_stub.tcl]
	}
	default { # works for adp and wdp
	  set code [adp_compile -file $file_stub.$type]
	}
      }

      # wrap the code for both types of files within an uplevel in
      # the declared procedure, so that data sources are set in the 
      # same frame as the code that outputs the template.

      proc ::template::code::${type}::$file_stub {} "
    	uplevel {
    	  $code
    	}
      "
      proc ::template::mtimes::${type}::$file_stub {} "return $mtime"
    }
  }
}

ad_proc -public template::adp_compile { source_type source } {
    Converts an ADP template into a chunk of Tcl code.  Caching this code
    avoids the need to reparse the ADP template with each request.

    @param source_type Indicates the source of the Tcl code to compile.
                       Valid options are -string or -file
    @param source      A string containing either the template itself (for
                       -string) or the path to the file containing the 
                       template (for -file)

    @return The compiled code.
} {
  variable parse_list
  # initialize the compiled code
  set parse_list [list "set __adp_output \"\""]

  switch -exact -- $source_type {
    -file { set chunk [template::util::read_file $source] }
    -string { set chunk $source }
    default { error "Source type must be -string or -file" } 
  }

  # substitute <% ... %> blocks with registered tags so they can be handled 
  # by our proc rather than evaluated.

  regsub -all {<%} $chunk {<tcl>} chunk
  # avoid substituting when it is a percentage attribute to an HTML tag.
  regsub -all {([^0-9])%>} $chunk {\1</tcl>} chunk
  # warn about the first ambiguity in the source
  if [regexp {[0-9]+%>} $chunk match] {
    ns_log warning "ambiguous '$match'; write tcl ecapes with a space like\
      <% set x 50 %> and HTML tags with proper quoting, like <hr width=\"50%\">\
      when compiling ADP source: template::adp_compile $source_type {$source}"
  }

  # recursively parse the template
  adp_compile_chunk $chunk

  # ensure that code returns with the output 
  lappend parse_list "set __adp_output"

  # the parse list now contains the code
  set code [join $parse_list "\n"]

  # substitute array variable references
  set pattern {([^\\])@([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)@}
  # loop to handle the case of adjacent variable references, like @a@@b@
  while {[regsub -all $pattern $code {\1$\2(\3)} code]} {}

  # substitute simple variable references
  while {[regsub -all {([^\\])@([a-zA-Z0-9_:]+)@} $code {\1${\2}} code]} {}

  # unescape protected @ references
  set code [string map { \\@ @ } $code]

  return $code
}

ad_proc -private template::adp_compile_chunk { chunk } {
    Parses a single chunk of a template.  A chunk is either the entire
    template or the portion of a template contained within a balanced
    tag.  This procedure does not return the compiled chunk; compiled
    code is assembled in the template::parse_list variable.

    @param chunk   A string containing markup, potentially with embedded
                   ATS tags.
} {
  # parse the template chunk inside the tag
  set remaining [ns_adp_parse -string $chunk]

  # add everything from either the beginning of the chunk or the
  # last balanced tag in the chunk to the list

  if { ! [string is space $remaining] } {
    # protect double quotes, brackets, the dollar sign, and backslash
    regsub -all {[\]\[""\\$]} $remaining {\\&} quoted

    adp_append_string $quoted
  }
}

ad_proc -private template::adp_append_string { s } {
    Adds a line of code that appends a string to the Tcl output
    from the compiler.

    @param s   A string containing markup that does not contain any embedded
               ATS tags.  Variable references and procedure calls are
               interpreted as for any double-quoted string in Tcl.
} {
  adp_append_code "append __adp_output \"$s\""
}

ad_proc -private template::adp_append_code { code { nobreak "" } } {
    Adds a line of code to the Tcl output from the compiler.

    @param code       A line of Tcl code

    @option nobreak   Flag indicating that code should be appended to the
    		      current last line rather than adding a new line, for 
                      cases where code must continue on the same line, such 
                      as the else tag
} {
  if { [string is space $code] } { return }

  variable parse_list

  if { [string equal $nobreak -nobreak] } {

    set last_line [lindex $parse_list end]
    append last_line " $code"
    set parse_list [lreplace $parse_list end end $last_line]

  } else {

    lappend parse_list $code
  }
}

ad_proc -private template::adp_puts { text } {
    Add text to the ADP currently being rendered.  May be used within escaped
    Tcl code in the template to add to the output.

    @param text A string containing text or markup.
} {
  upvar __adp_output __adp_output

  append __adp_output $text
}

ad_proc -private template::adp_tag_init { {tag_name ""} } {
    Called at the beginning of every tag handler to flush the ADP buffer of
    output accumulated from the last tag (or from the beginning of the file).

    @param tag_name  The name of the tag.  Used for debugging purposes only.
} {
  # add everything either from the beginning of the template or from
  # the last balanced tag up to the current point in the template

  set chunk [ns_adp_dump]

  if { ! [string is space $chunk] } {
    # protect double quotes, brackets, the dollar sign, and backslash
    regsub -all {[\]\[""\\$]} $chunk {\\&} quoted
    adp_append_string $quoted
  }

  # flush the output buffer so that the next dump will only catch
  # the next chunk of the template

  ns_adp_trunc
}

ad_proc -private template::tag_attribute { 
    tag 
    attribute
} {
    Return an attribute from a tag that has already been processed.

    @author Lee Denison (lee@runtime-collective.com)
    @creation-date 2002-01-30

    @return the value of the tag's attribute
    @param tag the tag identifier
    @param attribute the attribute name
} {
    return [ns_set get $tag $attribute]
}

ad_proc -private template::current_tag {} {
    Return the top level tag from the stack.
    
    @author Lee Denison (lee@runtime-collective.com)
    @creation-date 2002-01-30

    @return the tag from the top of the tag stack.
} {
  variable tag_stack

  return [lindex [lindex $tag_stack end] 1]
}
    
ad_proc -private template::enclosing_tag { 
    tag 
} {
    Reach back into the tag stack for the last enclosing instance of a tag.  
    
    Typically used where the usage of a tag depends on its context, such
    as the "group" tag within a "multiple" tag.

    @author Lee Denison (lee@runtime-collective.com)
    @creation-date 2002-01-30

    @return the tag identifier for the enclosing tag
    @param tag the type (eg. multiple) of the enclosing tag to look for.
} {
  set name ""

  variable tag_stack

  set last [expr [llength $tag_stack] - 2]

  for { set i $last } { $i >= 0 } { incr i -1 } {

    set pair [lindex $tag_stack $i]

    if { [string equal [lindex $pair 0] $tag] } {
      set name [lindex $pair 1]
      break
    }
  }

  return $name
}

ad_proc -private -deprecated template::get_enclosing_tag { tag } {
    Reach back into the tag stack for the last enclosing instance of a tag.  
    Typically used where the usage of a tag depends on its context, such
    as the "group" tag within a "multiple" tag.
   
    Deprecated, use:
    <pre>
  set tag [template::enclosing_tag &lt;tag-type&gt;]
  set attribute [template::tag_attribute tag &lt;attribute&gt;]
    </pre>
    @param tag  The name of the enclosing tag to look for.

  @see template::enclosing_tag
  @see template::tag_attribute
} {
  set name ""

  variable tag_stack

  set last [expr [llength $tag_stack] - 1]

  for { set i $last } { $i >= 0 } { incr i -1 } {

    set pair [lindex $tag_stack $i]

    if { [string equal [lindex $pair 0] $tag] } {
      set name [ns_set get [lindex $pair 1] name]
      break
    }
  }

  return $name
}

ad_proc -private template::get_attribute { tag params name { default "" } } {
    Retrieves a named attribute value from the parameter set passed to a
    tag handler.  If a default is not specified, assumes the attribute
    is required and throws an error.

    @param tag      The name of the tag.
    @param params   The ns_set passed to the tag handler.
    @param name     The name of the attribute.
    @param default  A default value to return if the the attribute is
                    not specified in the template.

    @return The value of the attribute.
} {
  set value [ns_set iget $params $name]

  if { [string equal $value {}] } {
    if { [string equal $default {}] } {
      error "Missing [string toupper $name] property\
             in [string toupper $tag] tag"
    } else {
      set value $default
    }
  }

  return $value
}

# Local Variables:
# tcl-indent-level: 2
# End:
