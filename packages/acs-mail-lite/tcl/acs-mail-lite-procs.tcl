ad_library {

    Provides a simple API for reliably sending email.
    
    @author Eric Lorenzo (eric@openforce.net)
    @creation-date 22 March 2002
    @cvs-id $Id$

}

namespace eval acs_mail_lite {

    ad_proc -public with_finally {
	-code:required
	-finally:required
    } {
	Execute CODE, then execute cleanup code FINALLY.
	If CODE completes normally, its value is returned after
	executing FINALLY.
	If CODE exits non-locally (as with error or return), FINALLY
	is executed anyway.

	@option code Code to be executed that could throw and error
	@option finally Cleanup code to be executed even if an error occurs
    } {
	global errorInfo errorCode

	# Execute CODE.
	set return_code [catch {uplevel $code} string]
	set s_errorInfo $errorInfo
	set s_errorCode $errorCode

	# As promised, always execute FINALLY.  If FINALLY throws an
	# error, Tcl will propagate it the usual way.  If FINALLY contains
	# stuff like break or continue, the result is undefined.
	uplevel $finally

	switch $return_code {
	    0 {
		# CODE executed without a non-local exit -- return what it
		# evaluated to.
		return $string
	    }
	    1 {
		# Error
		return -code error -errorinfo $s_errorInfo -errorcode $s_errorCode $string
	    }
	    2 {
		# Return from the caller.
		return -code return $string
	    }
	    3 {
		# break
		return -code break
	    }
	    4 {
		# continue
		return -code continue
	    }
	    default {
		return -code $return_code $string
	    }
	}
    }

    ad_proc -public get_package_id {} {
	@returns package_id of this package
    } {
        return [apm_package_id_from_key acs-mail-lite]
    }
    
    ad_proc -public get_parameter {
        -name:required
        {-default ""}
    } {
	Returns an apm-parameter value of this package
	@option name parameter name
	@option default default parameter value
	@returns apm-parameter value of this package
    } {
        return [parameter::get -package_id [get_package_id] -parameter $name -default $default]
    }
    
    ad_proc -public address_domain {} {
	@returns domain address to which bounces are directed to
    } {
        set domain [get_parameter -name "BounceDomain"]
        if { [empty_string_p $domain] } {
	    set domain [ns_info hostname]
	}
	return $domain
    }
    
    ad_proc -private bounce_sendmail {} {
	@returns path to the sendmail executable
    } {
	return [get_parameter -name "SendmailBin"]
    }
    
    ad_proc -private bounce_prefix {} {
	@returns bounce prefix for x-envelope-from
    } {
        return [get_parameter -name "EnvelopePrefix"]
    }
    
    ad_proc -private mail_dir {} {
	@returns incoming mail directory to be scanned for bounces
    } {
        return [get_parameter -name "BounceMailDir"]
    }
    
    ad_proc -public parse_email_address {
	-email:required
    } {
	Extracts the email address out of a mail address (like Joe User <joe@user.com>)
	@option email mail address to be parsed
	@returns only the email address part of the mail address
    } {
        if {![regexp {<([^>]*)>} $email all clean_email]} {
            return $email
        } else {
            return $clean_email
        }
    }

    ad_proc -public bouncing_email_p {
	-email:required
    } {
	Checks if email address is bouncing mail
	@option email email address to be checked for bouncing
	@returns boolean 1 if bouncing 0 if ok.
    } {
	return [db_string bouncing_p {} -default 0]
    }

    ad_proc -public bouncing_user_p {
	-user_id:required
    } {
	Checks if email address of user is bouncing mail
	@option user_id user to be checked for bouncing
	@returns boolean 1 if bouncing 0 if ok.
    } {
	return [db_string bouncing_p {} -default 0]
    }

    ad_proc -private log_mail_sending {
	-user_id:required
    } {
	Logs mail sending time for user
	@option user_id user for whom email sending should be logged
    } {
	db_dml record_mail_sent {}
	if {![db_resultrows]} {
	    db_dml insert_log_entry {}
	}
    }

    ad_proc -public bounce_address {
        -user_id:required
	-package_id:required
	-message_id:required
    } {
	Composes a bounce address
	@option user_id user_id of the mail recipient
	@option package_id package_id of the mail sending package
	        (needed to call package-specific code to deal with bounces)
	@option message_id message-id of the mail
	@returns bounce address
    } {
	return "[bounce_prefix]-$user_id-[ns_sha1 $message_id]-$package_id@[address_domain]"
    }
    
    ad_proc -public parse_bounce_address {
        -bounce_address:required
    } {
        This takes a reply address, checks it for consistency,
	and returns a list of user_id, package_id and bounce_signature found
	@option bounce_address bounce address to be checked
	@returns tcl-list of user_id package_id bounce_signature
    } {
        set regexp_str "^[bounce_prefix]-(\[0-9\]+)-(\[^-\]+)-(\[0-9\]+)\@"
        if {![regexp $regexp_str $bounce_address all user_id signature package_id]} {
	    ns_log Notice "acs-mail-lite: bounce_address not found"
            return ""
        }
    	return [list $user_id $package_id $signature]
    }
    
    ad_proc -public generate_message_id {
    } {
        Generate an id suitable as a Message-Id: header for an email.
	@returns valid message-id for mail header
    } {
        # The combination of high resolution time and random
        # value should be pretty unique.

        return "<[clock clicks].[ns_time].oacs@[address_domain]>"
    }

    ad_proc -public valid_signature {
	-signature:required
	-msg:required
    } {
        Validates if provided signature matches message_id
	@option signature signature to be checked
	@option msg message-id that the signature should be checked against
	@returns boolean 0 or 1
    } {
	if {![regexp "Message-Id: (<\[\-0-9\]+\\.\[0-9\]+\\.oacs@[address_domain]>)\n" $msg match message_id] || ![string equal $signature [ns_sha1 $message_id]]} {
	    # either couldn't find message-id or signature doesn't match
	    return 0
	}
	return 1
    }

    ad_proc -private load_mail_dir {
        -queue_dir:required
    } {
        Scans qmail incoming email queue for bounced mail and processes
	these bounced mails.
	
        @author ben@openforce.net
        @author dan.wickstrom@openforce.net
        @creation-date 22 Sept, 2001
	
        @option queue_dir The location of the qmail mail queue in the file-system.
    } {
        if {[catch {
	    # get list of all incoming mail
            set messages [glob "$queue_dir/new/*"]
        } errmsg]} {
            ns_log Notice "queue dir = $queue_dir/new/*, no messages"
            return [list]
        }
	
        set list_of_bounce_ids [list]
        set new_messages_p 0

	# loop over every incoming mail
        foreach msg $messages {
            ns_log Notice "opening file: $msg"
            if [catch {set f [open $msg r]}] {
                continue
            }
            set file [read $f]
            close $f
            set file [split $file "\n"]
	    
            set new_messages 1
            set end_of_headers_p 0
            set i 0
            set line [lindex $file $i]
            set headers [list]
	    
            # walk through the headers and extract each one
            while ![empty_string_p $line] {
                set next_line [lindex $file [expr $i + 1]]
                if {[regexp {^[ ]*$} $next_line match] && $i > 0} {
                    set end_of_headers_p 1
                }
                if {[regexp {^([^:]+):[ ]+(.+)$} $line match name value]} {
                    # join headers that span more than one line (e.g. Received)
                    if { ![regexp {^([^:]+):[ ]+(.+)$} $next_line match] && !$end_of_headers_p} {
			append line $next_line
			incr i
                    }
                    lappend headers [string tolower $name] $value
		    
                    if {$end_of_headers_p} {
			incr i
			break
                    }
                } else {
                    # The headers and the body are delimited by a null line as specified by RFC822
                    if {[regexp {^[ ]*$} $line match]} {
			incr i
			break
                    }
                }
                incr i
                set line [lindex $file $i]
            }
            set body "\n[join [lrange $file $i end] "\n"]"
	    
            # okay now we have a list of headers and the body, let's
            # put it into notifications stuff
            array set email_headers $headers
	    
            if [catch {set from $email_headers(from)}] {
                set from ""
            }
            if [catch {set to $email_headers(to)}] {
                set to ""
            }
	    
            set to [parse_email_address -email $to]
	    ns_log Notice "acs-mail-lite: To: $to"
            util_unlist [parse_bounce_address -bounce_address $to] user_id package_id signature
	    
            # If no user_id found or signature invalid, ignore message
            if {[empty_string_p $user_id] || ![valid_signature -signature $signature -msg $body]} {
		if {[empty_string_p $user_id]} {
		    ns_log Notice "acs-mail-lite: No user id $user_id found"
		} else {
		    ns_log Notice "acs-mail-lite: Invalid mail signature"
		}
                if {[catch {ns_unlink $msg} errmsg]} {
                    ns_log Notice "acs-mail-lite: couldn't remove message"
                }
                continue
            }

	    # Try to invoke package-specific procedure for special treatment
	    # of mail bounces
	    catch {acs_sc::invoke -contract AcsMailLite -operation MailBounce -impl [string map {- _} [apm_package_key_from_id $package_id]] -call_args [list [array get email_headers] $body]}
	    
	    # Okay, we have a bounce for a system user
	    # Check if the user has been marked as bouncing mail
	    # if the user is bouncing mail, we simply disgard the
	    # bounce since it was sent before the user's email was
	    # disabled.

	    ns_log Notice "Bounce checking: $to, $user_id"

	    if { ![bouncing_user_p -user_id $user_id] } {
                ns_log Notice "acs-mail-lite: Bouncing email from user $user_id"
		# record the bounce in the database
		db_dml record_bounce {}

		if {![db_resultrows]} {
		    db_dml insert_bounce {}
		}
	    }
            catch {ns_unlink $msg}
        }
    }
    
    ad_proc -public scan_replies {} {
        Scheduled procedure that will scan for bounced mails
    } {
	# Make sure that only one thread is processing the queue at a time.
	if {[nsv_incr acs_mail_lite check_bounce_p] > 1} {
	    nsv_incr acs_mail_lite check_bounce_p -1
	    return
	}

	with_finally -code {
	    ns_log Notice "acs-mail-lite: about to load qmail queue"
	    load_mail_dir -queue_dir [mail_dir]
	} -finally {
	    nsv_incr acs_mail_lite check_bounce_p -1
	}
    }

    ad_proc -private check_bounces { } {
	Daily proc that sends out warning mail that emails
	are bouncing and disables emails if necessary
    } {
	set max_bounce_count [get_parameter -name MaxBounceCount -default 10]
	set max_days_to_bounce [get_parameter -name MaxDaysToBounce -default 3]
	set notification_interval [get_parameter -name NotificationInterval -default 7]
	set max_notification_count [get_parameter -name MaxNotificationCount -default 4]
	set notification_sender [get_parameter -name NotificationSender -default "reminder@[address_domain]"]

	# delete all bounce-log-entries for users who received last email
	# X days ago without any bouncing (parameter)
	db_dml delete_log_if_no_recent_bounce {}

	# disable mail sending for users with more than X recently
	# bounced mails
	db_dml disable_bouncing_email {}

	# notify users of this disabled mail sending
	db_dml send_notification_to_bouncing_email {}

	# now delete bounce log for users with disabled mail sending
	db_dml delete_bouncing_users_from_log {}

	set subject "[ad_system_name] Email Reminder"

	# now periodically send notifications to users with
	# disabled email to tell them how to reenable the email
	set notifications [db_list_of_ns_sets get_recent_bouncing_users {}]

	# send notification to users with disabled email
	foreach notification $notifications {
	    set notification_list [util_ns_set_to_list -set $notification]
	    array set user $notification_list
	    set user_id $user(user_id)

	    set body "Dear $user(name),\n\nDue to returning mails from your email account, we currently do not send you any email from our system. To reenable your email account, please visit\n[ad_url]/register/restore-bounce?[export_url_vars user_id]"

	    send -to_addr $notification_list -from_addr $notification_sender -subject $subject -body $body -valid_email
	    ns_log Notice "Bounce notification send to user $user_id"

	    # schedule next notification
	    db_dml log_notication_sending {}
	}
    }
    
    ad_proc -public deliver_mail {
	-to_addr:required
	-from_addr:required
	-subject:required
	-body:required
	{-extraheaders ""}
	{-bcc ""}
	{-valid_email_p 0}
	-package_id:required
    } {
	Bounce Manager send 
	@option to_addr list of mail recipients
	@option from_addr mail sender
	@option subject mail subject
	@option body mail body
	@option extraheaders extra mail header
	@option bcc list of recipients of a mail copy
	@option valid_email_p flag if email needs to be checked if it's bouncing or
	        if calling code already made sure that the receiving email addresses
	        are not bouncing (this increases performance if mails are send in a batch process)
	@option package_id package_id of the sending package
	        (needed to call package-specific code to deal with bounces)
    } {
	set msg "Subject: $subject\nDate: [ns_httptime [ns_time]]"
	
	array set headers $extraheaders
	set message_id $headers(Message-Id)

	foreach {key value} $extraheaders {
	    append msg "\n$key\: $value"
	}

	## Blank line between headers and body
	append msg "\n\n$body\n"

        # ----------------------------------------------------
        # Rollout support
        # ----------------------------------------------------
        # if set in /etc/config.tcl, then
        # /packages/acs-tcl/tcl/rollout-email-procs.tcl will rename a
        # proc to ns_sendmail. So we simply call ns_sendmail instead
        # of the sendmail bin if the EmailDeliveryMode parameter is
        # set - JFR
        #-----------------------------------------------------
        set delivery_mode [ns_config ns/server/[ns_info server]/acs/acs-rollout-support EmailDeliveryMode] 

        if {![empty_string_p $delivery_mode]} {
            # The to_addr has been put in an array, and returned. Now
            # it is of the form: email email_address name namefromdb
            # user_id user_id_if_present_or_empty_string
            set to_address "[lindex $to_addr 1] ([lindex $to_addr 3])"
            ns_sendmail "$to_address" "$from_addr" "$subject" "$body" "$extraheaders" "$bcc"
        } else {

            if { [string equal [bounce_sendmail] "SMTP"] } {
                ## Terminate body with a solitary period
                foreach line [split $msg "\n"] { 
                    if [string match . $line] {
                        append data .
                    }
                    append data "$line\r\n"
                }
                append data .
                
                smtp -from_addr $from_addr -sendlist $to_addr -msg $data -valid_email_p $valid_email_p -message_id $message_id -package_id $package_id
                if {![empty_string_p $bcc]} {
                    smtp -from_addr $from_addr -sendlist $bcc -msg $data -valid_email_p $valid_email_p -message_id $message_id -package_id $package_id
                }
                
            } else {
                sendmail -from_addr $from_addr -sendlist $to_addr -msg $msg -valid_email_p $valid_email_p -message_id $message_id -package_id $package_id
                if {![empty_string_p $bcc]} {
                    sendmail -from_addr $from_addr -sendlist $bcc -msg $msg -valid_email_p $valid_email_p -message_id $message_id -package_id $package_id
                }
            }
            
            
        }
    }
    
    ad_proc -private sendmail {
	-from_addr:required
        -sendlist:required
	-msg:required
	{-valid_email_p 0}
	-message_id:required
	-package_id:required
    } {
	Sending mail through sendmail.
	@option from_addr mail sender
	@option sendlist list of mail recipients
	@option msg mail to be sent (subject, header, body)
	@option valid_email_p flag if email needs to be checked if it's bouncing or
	        if calling code already made sure that the receiving email addresses
	        are not bouncing (this increases performance if mails are send in a batch process)
	@option message_id message-id of the mail
	@option package_id package_id of the sending package
	        (needed to call package-specific code to deal with bounces)
    } {
	array set rcpts $sendlist
        foreach rcpt $rcpts(email) rcpt_id $rcpts(user_id) rcpt_name $rcpts(name) {
	    if { $valid_email_p || ![bouncing_email_p -email $rcpt] } {
		with_finally -code {
		    set sendmail [list [bounce_sendmail] "-f[bounce_address -user_id $rcpt_id -package_id $package_id -message_id $message_id]" "-t" "-i"]

		    # add username if it exists
		    if {![empty_string_p $rcpt_name]} {
			set pretty_to "$rcpt_name <$rcpt>"
		    } else {
			set pretty_to $rcpt
		    }

                    # substitute all "\r\n" with "\n", because piped text should only contain "\n"
                    regsub -all "\r\n" $msg "\n" msg

		    set f [open "|$sendmail" "w"]
		    puts $f "From: $from_addr\nTo: $pretty_to\n$msg"
		    close $f
		} -finally {
		}
	    } else {
		ns_log Notice "acs-mail-lite: Email bouncing from $rcpt, mail not sent and deleted from queue"
	    }
	    # log mail sending time
	    if {![empty_string_p $rcpt_id]} { log_mail_sending -user_id $rcpt_id }
	}
    }
    
    ad_proc -private smtp {
	-from_addr:required
	-sendlist:required
	-msg:required
	{-valid_email_p 0}
	-message_id:required
	-package_id:required
    } {
	Sending mail through smtp.
	@option from_addr mail sender
	@option sendlist list of mail recipients
	@option msg mail to be sent (subject, header, body)
	@option valid_email_p flag if email needs to be checked if it's bouncing or
	        if calling code already made sure that the receiving email addresses
	        are not bouncing (this increases performance if mails are send in a batch process)
	@option message_id message-id of the mail
	@option package_id package_id of the sending package
	        (needed to call package-specific code to deal with bounces)
    } { 
	set smtp [ns_config ns/parameters smtphost]
	if {[empty_string_p $smtp]} {
	    set smtp [ns_config ns/parameters mailhost]
	}
	if {[empty_string_p $smtp]} {
	    set smtp localhost
	}
	set timeout [ns_config ns/parameters smtptimeout]
	if {[empty_string_p $timeout]} {
	    set timeout 60
	}
	set smtpport [ns_config ns/parameters smtpport]
	if {[empty_string_p $smtpport]} {
	    set smtpport 25
	}
	array set rcpts $sendlist
        foreach rcpt $rcpts(email) rcpt_id $rcpts(user_id) rcpt_name $rcpts(name) {
	    if { $valid_email_p || ![bouncing_email_p -email $rcpt] } {
		# add username if it exists
		if {![empty_string_p $rcpt_name]} {
		    set pretty_to "$rcpt_name <$rcpt>"
		} else {
		    set pretty_to $rcpt
		}

		set msg "From: $from_addr\r\nTo: $pretty_to\r\n$msg"
		set mail_from [bounce_address -user_id $rcpt_id -package_id $package_id -message_id $message_id]

		## Open the connection
		set sock [ns_sockopen $smtp $smtpport]
		set rfp [lindex $sock 0]
		set wfp [lindex $sock 1]
		
		## Perform the SMTP conversation
		with_finally -code {
		    _ns_smtp_recv $rfp 220 $timeout
		    _ns_smtp_send $wfp "HELO [ns_info hostname]" $timeout
		    _ns_smtp_recv $rfp 250 $timeout
		    _ns_smtp_send $wfp "MAIL FROM:<$mail_from>" $timeout
		    _ns_smtp_recv $rfp 250 $timeout
		    _ns_smtp_send $wfp "RCPT TO:<$rcpt>" $timeout
		    _ns_smtp_recv $rfp 250 $timeout
		    _ns_smtp_send $wfp DATA $timeout
		    _ns_smtp_recv $rfp 354 $timeout
		    _ns_smtp_send $wfp $msg $timeout
		    _ns_smtp_recv $rfp 250 $timeout
		    _ns_smtp_send $wfp QUIT $timeout
		    _ns_smtp_recv $rfp 221 $timeout
		} -finally {
		    ## Close the connection
		    close $rfp
		    close $wfp
		}
	    } else {
		ns_log Notice "acs-mail-lite: Email bouncing from $rcpt, mail not sent and deleted from queue"
	    }
	    # log mail sending time
	    if {![empty_string_p $rcpt_id]} { log_mail_sending -user_id $rcpt_id }
	}
    }

    ad_proc -private get_address_array {
	-addresses:required
    } {	Checks if passed variable is already an array of emails,
	user_names and user_ids. If not, get the additional data
	from the db and return the full array.
	@option addresses variable to checked for array
	@returns array of emails, user_names and user_ids to be used
	         for the mail procedures
    } {
	if {[catch {array set address_array $addresses}]
	    || ![string equal [lsort [array names address_array]] [list email name user_id]]} {

	    # either user just passed a normal address-list or
	    # user passed an array, but forgot to provide user_ids
	    # or user_names, so we have to get this data from the db

	    if {![info exists address_array(email)]} {
		# so user passed on a normal address-list
		set address_array(email) $addresses
	    }

	    set address_list [list]
	    foreach email $address_array(email) {
		# strip out only the emails from address-list
		lappend address_list [string tolower [parse_email_address -email $email]]
	    }

	    array unset address_array
	    # now get the user_names and user_ids
	    foreach email $address_list {
		set email [string tolower $email]
		if {[db_0or1row get_user_name_and_id ""]} {
		    lappend address_array(email) $email
		    lappend address_array(name) $user_name
		    lappend address_array(user_id) $user_id
		} else {
		    lappend address_array(email) $email
		    lappend address_array(name) ""
		    lappend address_array(user_id) ""
		}
	    }
	}
	return [array get address_array]
    }
    
    ad_proc -public send {
	-send_immediately:boolean
	-valid_email:boolean
        -to_addr:required
        -from_addr:required
        {-subject ""}
        -body:required
        {-extraheaders ""}
        {-bcc ""}
	{-package_id ""}
    } {
        Reliably send an email message.

	@option send_immediately Switch that lets the mail send directly without adding it to the mail queue first.
	@option valid_email Switch that avoids checking if the email to be mailed is not bouncing
	@option to_addr List of mail-addresses or array of email,name,user_id containing lists of users to be mailed
	@option from_addr mail sender
	@option subject mail subject
	@option body mail body
	@option extraheaders extra mail headers
	@option bcc see to_addr
	@option package_id To be used for calling a package-specific proc when mail has bounced
        @returns the Message-Id of the mail
    } {
	## Extract "from" email address
	set from_addr [parse_email_address -email $from_addr]

	## Get address-array with email, name and user_id
	set to_addr [get_address_array -addresses [string map {\n "" \r ""} $to_addr]]
	if {![empty_string_p $bcc]} {
	    set bcc [get_address_array -addresses [string map {\n "" \r ""} $bcc]]
	}

        if {![empty_string_p $extraheaders]} {
            set eh_list [util_ns_set_to_list -set $extraheaders]
        } else {
            set eh_list ""
        }

        # Subject cannot contain newlines -- replace with spaces
        regsub -all {\n} $subject { } subject

	set message_id [generate_message_id]
        lappend eh_list "Message-Id" $message_id

	if {[empty_string_p $package_id]} {
	    if [ad_conn -connected_p] {
		set package_id [ad_conn package_id]
	    } else {
		set package_id ""
	    }
	}

        # Subject can not be longer than 200 characters
        if { [string length $subject] > 200 } {
            set subject "[string range $subject 0 196]..."
        }

	# check, if send_immediately is set
	# if not, take global parameter
	if {$send_immediately_p} {
	    set send_p $send_immediately_p
	} else {
	    # if parameter is not set, get the global setting
	    set send_p [parameter::get -package_id [get_package_id] -parameter "send_immediately" -default 0]
	}

	# if send_p true, then start acs_mail_lite::send_immediately, so mail is not stored in the db before delivery
	if { $send_p } {
	    acs_mail_lite::send_immediately -to_addr $to_addr -from_addr $from_addr -subject $subject -body $body -extraheaders $eh_list -bcc $bcc -valid_email_p $valid_email_p -package_id $package_id
	} else {
	    # else, store it in the db and let the sweeper deliver the mail
	    db_dml create_queue_entry {}
	}
        return $message_id
    }
 
    ad_proc -private sweeper {} {
        Send messages in the acs_mail_lite_queue table.
    } {
	# Make sure that only one thread is processing the queue at a time.
	if {[nsv_incr acs_mail_lite send_mails_p] > 1} {
	    nsv_incr acs_mail_lite send_mails_p -1
	    return
	}

	with_finally -code {
	    db_foreach get_queued_messages {} {
		with_finally -code {
		    deliver_mail -to_addr $to_addr -from_addr $from_addr \
			-subject $subject -body $body -extraheaders $extra_headers \
			-bcc $bcc -valid_email_p $valid_email_p \
			-package_id $package_id

		    db_dml delete_queue_entry {}
		} -finally {
		}
	    }
	} -finally {
	    nsv_incr acs_mail_lite send_mails_p -1
	}
    }

    ad_proc -private send_immediately {
        -to_addr:required
        -from_addr:required
        {-subject ""}
        -body:required
        {-extraheaders ""}
        {-bcc ""}
	{-valid_email_p 0}
	-package_id:required
    } {
	Procedure to send mails immediately without queuing the mail in the database for performance reasons.
	If ns_sendmail fails, the mail will be written in the db so the sweeper can send them out later.
	@option to_addr List of mail-addresses or array of email,name,user_id containing lists of users to be mailed
	@option from_addr mail sender
	@option subject mail subject
	@option body mail body
	@option extraheaders extra mail headers
	@option bcc see to_addr
	@option valid_email_p Switch that avoids checking if the email to be mailed is not bouncing
	@option package_id To be used for calling a package-specific proc when mail has bounced
    } {
	if {[catch {
	    deliver_mail -to_addr $to_addr -from_addr $from_addr -subject $subject -body $body -extraheaders $extraheaders -bcc $bcc -valid_email_p $valid_email_p -package_id $package_id
	} errmsg]} {
	    ns_log Error "acs_mail_lite::deliver_mail failed: $errmsg"
	    ns_log "Notice" "Mail info will be written in the db"
	    db_dml create_queue_entry {}
	} else {
	    ns_log "Notice" "acs_mail_lite::deliver_mail successful"
	}
    }

    ad_proc -private after_install {} {
	Callback to be called after package installation.
	Adds the service contract package-specific bounce management.

	@author Timo Hentschel (thentschel@sussdorff-roy.com)
    } {
	acs_sc::contract::new -name AcsMailLite -description "Callbacks for Bounce Management"
	acs_sc::contract::operation::new -contract_name AcsMailLite -operation MailBounce -input "header:string body:string" -output "" -description "Callback to handle bouncing mails"
    }

    ad_proc -private before_uninstall {} {
	Callback to be called before package uninstallation.
	Removes the service contract for package-specific bounce management.

	@author Timo Hentschel (thentschel@sussdorff-roy.com)
    } {
	# shouldn't we first delete the bindings?
	acs_sc::contract::delete -name AcsMailLite
    }
}
