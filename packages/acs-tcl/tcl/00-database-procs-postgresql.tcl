ad_library {

    Postgres-specific database API and utility procs.

    @creation-date 15 Apr 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id $Id$
}

proc_doc db_nextval { sequence } { Returns the next value for a sequence. This can utilize a pool of sequence values to save hits to the database. } {
    return [db_string nextval "select ${sequence}.nextval"]
}

proc_doc db_exec_plsql { statement_name sql args } {

    Postgres doesn't have PL/SQL, of course, but it does have PL/pgSQL and
    other procedural languages.  Rather than assign the result to a bind
    variable which is then returned to the caller, the Postgres version of
    OpenACS requires the caller to perform a select query that returns
    the value of the function.

    We are no longer calling db_string, which screws up the bind variable
    stuff otherwise because of calling environments. (ben)

} {
    ad_arg_parser { bind_output } $args

    # I'm not happy about having to get the fullname here, but right now
    # I can't figure out a cleaner way to do it. I will have to
    # revisit this ASAP. (ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    if { [info exists bind_output] } {
	return -code error "the -bind_output switch is not currently supported"
    }

    db_with_handle db {
        # plsql calls that are simple selects bypass the plpgsql 
        # mechanism for creating anonymous functions (OpenACS - Dan).
        set test_sql [db_qd_replace_sql $full_statement_name $sql]
        if {[regexp -nocase -- {^\s*select} $test_sql match]} {
            ns_log Notice "PLPGSQL: bypassed anon function"
            set selection [db_exec 0or1row $db $full_statement_name $sql]
        } else {
            ns_log Notice "PLPGSQL: using anonymous function"
            set selection [db_exec_plpgsql $db $full_statement_name $sql \
                           $statement_name]
        }
	return [ns_set value $selection 0]
    }
}

# emulation of plsql calls from oracle.  This routine takes the plsql 
# statements and wraps them in a function call, calls the function, and then
# drops the function. Future work might involve converting this to cache the 
# function calls

ad_proc -private db_exec_plpgsql { db statement_name pre_sql fname } {

    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).

    Low level replacement for db_exec which replaces inline code with a proc.
    db proc is dropped after execution.  This is a temporary fix until we can 
    port all of the db_exec_plsql calls to simple selects of the inline code
    wrapped in function calls.

} {
    set start_time [clock clicks]

    ns_log Notice "PRE-QD: the SQL is $pre_sql"

    # Query Dispatcher (OpenACS - ben)
    set sql [db_qd_replace_sql $statement_name $pre_sql]

    ns_log Notice "POST-QD: the SQL is $sql"

    set unique_id [db_nextval "anon_func_seq"]

    set function_name "__exec_${unique_id}_${fname}"

    # insert tcl variable values (Openacs - Dan)
    if {![string equal $sql $pre_sql]} {
        set sql [uplevel 2 [list subst -nobackslashes $sql]]
    }
    ns_log Notice "PLPGSQL: converted: $sql to: select $function_name ()"

    # create a function definition statement for the inline code 
    # binding is emulated in tcl. (OpenACS - Dan)

    set errno [catch {
	upvar bind bind
	if { [info exists bind] && [llength $bind] != 0 } {
	    if { [llength $bind] == 1 } {
                set bind_vars [list]
                set len [ns_set size $bind]
                for {set i 0} {$i < $len} {incr i} {
                    lappend bind_vars [ns_set key $bind $i] \
                                      [ns_set value $bind $i]
                }
                set proc_sql [db_bind_var_substitution $sql $bind_vars]
	    } else {
                set proc_sql [db_bind_var_substitution $sql $bind]
	    }
	} else {
            set proc_sql [uplevel 2 [list db_bind_var_substitution $sql]]
	}

        ns_db dml $db "create function $function_name () returns varchar as '
                      [DoubleApos $proc_sql]
                      ' language 'plpgsql'"

        set ret_val [ns_db 0or1row $db "select $function_name ()"]
        # drop the anonymous function (OpenACS - Dan)
        ns_db dml $db "drop function $function_name ()"

        return $ret_val

    } error]

    global errorInfo errorCode
    set errinfo $errorInfo
    set errcode $errorCode

    ad_call_proc_if_exists ds_collect_db_call $db 0or1row $statement_name $sql $start_time $errno $error

    if { $errno == 2 } {
	return $error
    } else {
        catch {ns_db dml $db "drop function $function_name ()"}
    }

    return -code $errno -errorinfo $errinfo -errorcode $errcode $error
}

ad_proc -private db_bind_var_substitution { sql { bind "" } } {

    This proc emulates the bind variable substitution in the postgresql driver.
    Since this is a temporary hack, we do it in tcl instead of hacking up the 
    driver to support plsql calls.  This is only used for the db_exec_plpgsql
    function.

} {
    if {[string equal $bind ""]} {
        upvar __db_sql lsql
        set lsql $sql
        uplevel {            
            set __db_lst [regexp -inline -indices -all -- {:?:\w+} $__db_sql]
            for {set i [expr [llength $__db_lst] - 1]} {$i >= 0} {incr i -1} {
                set __db_ws [lindex [lindex $__db_lst $i] 0]
                set __db_we [lindex [lindex $__db_lst $i] 1]
                set __db_bind_var [string range $__db_sql $__db_ws $__db_we]
                if {![string match "::*" $__db_bind_var]} {
                    set __db_tcl_var [string range $__db_bind_var 1 end]
                    set __db_tcl_var [set $__db_tcl_var]
                    if {[string equal $__db_tcl_var ""]} {
                        set __db_tcl_var null
                    } else {
                        set __db_tcl_var "'$__db_tcl_var'"
                    }
                    set __db_sql [string replace $__db_sql $__db_ws $__db_we $__db_tcl_var]
                }                
            }
        }
    } else {

        array set bind_vars $bind

        set lsql $sql
        set lst [regexp -inline -indices -all -- {:?:\w+} $sql]
        for {set i [expr [llength $lst] - 1]} {$i >= 0} {incr i -1} {
            set ws [lindex [lindex $lst $i] 0]
            set we [lindex [lindex $lst $i] 1]
            set bind_var [string range $sql $ws $we]
            if {![string match "::*" $bind_var]} {
                set tcl_var [string range $bind_var 1 end]
                set val $bind_vars($tcl_var)
                if {[string equal $val ""]} {
                    set val null
                } else {
                    set val "'$val'"
                }
                set lsql [string replace $lsql $ws $we $val]
            }                
        }
    }

    return $lsql
}

ad_proc -private db_exec { type db statement_name pre_sql args } {

    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).

} {
    set start_time [clock clicks]

    ns_log Notice "PRE-QD: the SQL is $pre_sql for $statement_name"

    # Query Dispatcher (OpenACS - ben)
    set sql [db_qd_replace_sql $statement_name $pre_sql]

    # insert tcl variable values (Openacs - Dan)
    if {![string equal $sql $pre_sql]} {
        set sql [uplevel 2 [list subst -nobackslashes $sql]]
    }

    ns_log Notice "POST-QD: the SQL is $sql"

    set errno [catch {
	upvar bind bind
	if { [info exists bind] && [llength $bind] != 0 } {
	    if { [llength $bind] == 1 } {
		return [eval [list ns_pg_bind $type $db -bind $bind $sql] $args]
	    } else {
		set bind_vars [ns_set create]
		foreach { name value } $bind {
		    ns_set put $bind_vars $name $value
		}
		return [eval [list ns_pg_bind $type $db -bind $bind_vars $sql] $args]
	    }
	} else {
	    return [uplevel 2 [list ns_pg_bind $type $db $sql] $args]
	}
    } error]

    ad_call_proc_if_exists ds_collect_db_call $db $type $statement_name $sql $start_time $errno $error
    if { $errno == 2 } {
	return $error
    }

    global errorInfo errorCode
    return -code $errno -errorinfo $errorInfo -errorcode $errorCode $error
}

proc_doc db_dml { statement_name sql args } {
    Do a DML statement.  We don't have CLOBs in PG as PG 7.1 allows
    unbounded compressed text columns.  BLOBs are handled much differently,
    to.
} {
    ad_arg_parser { bind blob_files blobs } $args

    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    if {[info exists blob_files]} {

        db_with_handle db {
            # another ugly hack to avoid munging tcl files.
            # __lob_id needs to be set inside of a query (.xql) file for this
            # to work.  Say for example that you need to create a lob. In 
            # Oracle, you would do something like:

            # db_dml update_photo  "update foo set bar = empty_blob() 
            #                       where bar = :bar 
            #                       returning foo into :1" -blob_files [list $file]
            # for postgresql we can do the equivalent by placing the following
            # in a query file:
            # update foo set bar = [set __lob_id [db_string get_id "select empty_lob()"]]
            # where bar = :bar

            # __lob_id acts as a flag that signals that blob_dml_file is 
            # required, and it is also used to pass along the lob_id.  It
            # is unsert afterwards to avoid name clashes with other invocations
            # of this routine.
            # (DanW - Openacs)
            db_exec dml $db $full_statement_name $sql
            if {[uplevel {info exists __lob_id}]} {
                ns_pg blob_dml_file $db [uplevel {set __lob_id}] $blob_files
                uplevel {unset __lob_id}
            }
        }

    } else {

        db_with_handle db {
            db_exec dml $db $full_statement_name $sql
        }
    }
}

proc_doc db_resultrows {} { Returns the number of rows affected by the last DML command. } {
    global db_state
    return [ns_pg ntuples $db_state(last_used)]
}

#ad_proc db_continue_transaction {} {
#    
#    If a transaction is set to be aborted, this procedure allows it to continue.
#    Intended for use only within a db_transaction on_error code block.  
#
#    DRB: we can't emulate this in Postgres.  The best we can do is a COMMIT
#    followed by BEGIN.  Commented out so caller will get an error.
#
#} {
#    global db_state
#    db_with_handle db {
#	# The error has been handled, set the flag to false.
#	set db_state(db_abort_p,$db) 0
#    }
#}

ad_proc db_write_clob { statement_name sql args } {
    ad_arg_parser { bind } $args

    db_with_handle db {
	db_exec write_clob $db $statement_name $sql
    }
}

ad_proc db_write_blob { statement_name sql args } {
    ad_arg_parser { bind } $args

    set full_statement_name [db_qd_get_fullname $statement_name]

    db_with_handle db { 
	db_exec_lob write_blob $db $full_statement_name $sql
    }
}

ad_proc db_blob_get_file { statement_name sql args } {
    ad_arg_parser { bind file args } $args

    set full_statement_name [db_qd_get_fullname $statement_name]

    db_with_handle db {
	db_exec_lob blob_select_file $db $full_statement_name $sql $file
    }
}

ad_proc -private db_exec_lob { type db statement_name pre_sql { file "" } } {

    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).

    Low level replacement for db_exec which emulates blob handling.

} {
    set start_time [clock clicks]

    ns_log Notice "PRE-QD: the SQL is $pre_sql"

    # Query Dispatcher (OpenACS - ben)
    set sql [db_qd_replace_sql $statement_name $pre_sql]

    # insert tcl variable values (Openacs - Dan)
    if {![string equal $sql $pre_sql]} {
        set sql [uplevel 2 [list subst -nobackslashes $sql]]
    }

    ns_log Notice "POST-QD: the SQL is $sql"

    # create a function definition statement for the inline code 
    # binding is emulated in tcl. (OpenACS - Dan)

    set errno [catch {
	upvar bind bind
	if { [info exists bind] && [llength $bind] != 0 } {
	    if { [llength $bind] == 1 } {
                set bind_vars [list]
                set len [ns_set size $bind]
                for {set i 0} {$i < $len} {incr i} {
                    lappend bind_vars [ns_set key $bind $i] \
                                      [ns_set value $bind $i]
                }
                set lob_sql [db_bind_var_substitution $sql $bind_vars]
	    } else {
                set lob_sql [db_bind_var_substitution $sql $bind]
	    }
	} else {
            set lob_sql [uplevel 2 [list db_bind_var_substitution $sql]]
	}

        # get the content - asssume it is in column 0, or optionally it can
        # be returned as "content" with the storage type indicated by the 
        # "storage_type" column.

        set selection [ns_db 1row $db $lob_sql]
        set content [ns_set value $selection 0]
        for {set i 0} {$i < [ns_set size $selection]} {incr i} {
            set name [ns_set key $selection $i]
            if {[string equal $name storage_type]} {
                set storage_type [ns_set value $selection $i]
            } elseif {[string equal $name content]} {
                set content [ns_set value $selection $i]
            }
        }

        # this is an ugly hack, but it allows content to be written
        # to a file/connection if it is stored as a lob or if it is
        # stored in the content-repository as a file. (DanW - Openacs)

        switch $type {

            blob_select_file {

                if {[info exists storage_type]} {
                    switch $storage_type {
                        file {
                            if {[file exists $content]} {
                                set ifp [open $content r]
                                set ofp [open $file w]
                                ns_cpfp $ifp $ofp
                                close $ifp
                                close $ofp
                            } else {
                                error "file: $content doesn't exist"
                            }
                        }

                        lob {
                            if {[regexp {^[0-9]+$} $content match]} {
                                ns_pg blob_select_file $db $content $file
                            } else {
                                error "invalid lob_id: should be an integer"
                            }
                        }

                        default {
                            error "invalid storage type"
                        }
                    }
                } elseif {[file exists $content]} {
                    set ifp [open $content r]
                    set ofp [open $file w]
                    ns_cpfp $ifp $ofp
                    close $ifp
                    close $ofp
                } elseif {[regexp {^[0-9]+$} $content match]} {
                    ns_pg blob_select_file $db $content $file
                } else {
                    error "invalid query"
                }
            }

            write_blob {

                if {[info exists storage_type]} {
                    switch $storage_type {
                        file {
                            if {[file exists $content]} {
                                set ofp [open $content r]
                                ns_writefp $ofp
                                close $ofp
                            } else {
                                error "file: $content doesn't exist"
                            }
                        }

                        text {
                            ns_write $content
                        }

                        lob {
                            if {[regexp {^[0-9]+$} $content match]} {
                                ns_pg blob_write $db $content
                            } else {
                                error "invalid lob_id: should be an integer"
                            }
                        }

                        default {
                            error "invalid storage type"
                        }
                    }
                } elseif {[file exists $content]} {
                    set ofp [open $content r]
                    ns_writefp $ofp
                    close $ofp
                } elseif {[regexp {^[0-9]+$} $content match]} {
                    ns_pg blob_write $db $content
                } else {
                    ns_write $content
                }
            }
        }

        return

    } error]

    global errorInfo errorCode
    set errinfo $errorInfo
    set errcode $errorCode

    ad_call_proc_if_exists ds_collect_db_call $db 0or1row $statement_name $sql $start_time $errno $error

    if { $errno == 2 } {
	return $error
    }

    return -code $errno -errorinfo $errinfo -errorcode $errcode $error
}

ad_proc db_get_pgbin { } {

    Returns the database name from the first database pool.  It assumes the 
    datasource is properly formatted since we've already verified that we
    can connect to the pool.

} {

    set pool [lindex [nsv_get db_available_pools .] 0]
    set driver [ns_config ns/db/pool/$pool Driver]    
    return [ns_config ns/db/driver/$driver pgbin]
}

ad_proc db_get_database { } {

    Returns the database name from the first database pool.  It assumes the 
    datasource is properly formatted since we've already verified that we
    can connect to the pool.

} {

    set pool [lindex [nsv_get db_available_pools .] 0]
    set datasource [ns_config ns/db/pool/$pool DataSource]    
    set last_colon_pos [string last ":" $datasource]
    if { $last_colon_pos == -1 } {
        ns_log Error "datasource contains no \":\"? datasource = $datasource"
        return ""
    }
    return [string range $datasource [expr $last_colon_pos + 1] end]
}

ad_proc db_source_sql_file { {-callback apm_ns_write_callback} file } {

    Sources a SQL file (in SQL*Plus format).

} {
    
    set file_name [file tail $file]
    cd [file dirname $file]
    set fp [open "|[file join [db_get_pgbin] psql] [db_get_database] -f $file_name" "r"]

    while { [gets $fp line] >= 0 } {
	# Don't bother writing out lines which are purely whitespace.
	if { ![string is space $line] } {
	    apm_callback_and_log $callback "[ad_quotehtml $line]\n"
	}
    }

    # PSQL dumps errors and notice information on stderr, and has no option to turn
    # this off.  So we have to chug through the "error" lines looking for those that
    # really signal an error.

    set errno [ catch {
        close $fp
    } error]

    if { $errno == 2 } {
	return $error
    }

    # Just filter out the "NOTICE" lines, so we get the stack dump along with real
    # ERRORs.  This could be done with a couple of opaque-looking regexps...

    set error_found 0
    foreach line [split $error "\n"] {
        if { [string first NOTICE $line] == -1 } {
            append error_lines "$line\n"
            set error_found [expr { $error_found || [string first ERROR $line] != -1 || \
                                    [string first FATAL $line] != -1 } ]
        }
    }

    if { $error_found } {
        global errorCode
        return -code error -errorinfo $error_lines -errorcode $errorCode
    }
}

ad_proc -public db_tables { -pattern } {
    Returns a Tcl list of all the tables owned by the connected user.
    
    @param pattern Will be used as LIKE 'pattern%' to limit the number of tables returned.

    @author Don Baccus dhogaza@pacifier.com

} {
    set tables [list]
    
    if { [info exists pattern] } {
	db_foreach table_names_with_pattern {
	    select relname
	    from pg_class
	    where relname like lower(:pattern) and
                relname !~ '^pg_' and relkind = 'r'
	} {
	    lappend tables $relname
	}
    } else {
	db_foreach table_names_without_pattern {
	    select relname
	    from pg_class
	    where relname !~ '^pg_' and relkind = 'r'
	} {
	    lappend tables $relname
	}
    }
    return $tables
}

ad_proc -public db_table_exists { table_name } {
    Returns 1 if a table with the specified name exists in the database, otherwise 0.

    @author Don Baccus dhogaza@pacifier.com
    
} {
    set n_rows [db_string table_count {
	select count(*) from pg_class
        where relname = lower(:table_name) and
	    relname !~ '^pg_' and relkind = 'r'
    }]
    return $n_rows
}

ad_proc -public db_columns { table_name } {
    Returns a Tcl list of all the columns in the table with the given name.
    
    @author Lars Pind lars@pinds.com

    @change-log yon@arsdigita.com 20000711 changed to return lower case column names
} {
    set columns [list]
    db_foreach table_column_names {
	select lower(column_name) as column_name
	from user_tab_columns
	where table_name = upper(:table_name)
    } {
	lappend columns $column_name
    }
    return $columns
}


ad_proc -public db_column_exists { table_name column_name } {
    Returns 1 if the row exists in the table, 0 if not.
    
    @author Lars Pind lars@pinds.com
} {
    set columns [list]
    set n_rows [db_string column_exists {
	select count(*) 
	from user_tab_columns
	where table_name = upper(:table_name)
	and column_name = upper(:column_name)
    }]
    return [expr $n_rows > 0]
}


ad_proc -public db_column_type { table_name column_name } {

    Returns the Oracle Data Type for the specified column.
    Returns -1 if the table or column doesn't exist.

    @author Yon Feldman (yon@arsdigita.com)

    @change-log 10 July, 2000: changed to return error
                               if column name doesn't exist  
                               (mdettinger@arsdigita.com)

    @change-log 11 July, 2000: changed to return lower case data types 
                               (yon@arsdigita.com)

    @change-log 11 July, 2000: changed to return error using the db_string default clause
                               (yon@arsdigita.com)

} {

    return [db_string column_type_select "
	select data_type as data_type
	  from user_tab_columns
	 where upper(table_name) = upper(:table_name)
	   and upper(column_name) = upper(:column_name)
    " -default "-1"]

}

ad_proc -public ad_column_type { table_name column_name } {

    Returns 'numeric' for number type columns, 'text' otherwise
    Throws an error if no such column exists.

    @author Yon Feldman (yon@arsdigita.com)

} {

    set column_type [db_column_type $table_name $column_name]

    if { $column_type == -1 } {
	return "Either table $table_name doesn't exist or column $column_name doesn't exist"
    } elseif { [string compare $column_type "NUMBER"] } {
	return "numeric"
    } else {
	return "text"
    }
}
