# packages/acs-automated-testing/www/admin/record-test.tcl

ad_page_contract {
    
    Creates test cases and add them to a library
    
    @author Enrique Catalan (enrique.catalan@quest.ie)
    @creation-date 2007-08-21
    @cvs-id $Id$
} {
    package_key
    {return_url:localurl ""}
} -properties {
} -validate {
} -errors {
}

# Todo
# This is a first attempt of integrating the TwtR
# with oacs.  I think it is a good point to start
# but in the ToDo list would be really useful to 
# have:
# - Parsing the Test code to replace fixed values with
#   Random ones (i.e. names, descriptions, intervals,
#   etc.). We might need to change TwtR src. 
# - Modify the js code of TwtR to be able to print
#   the code in this form to avoid users copy&paste it
# - Find a way to get fixed date values and replace 
#   them with dynamic date values 
# - Might be useful to keep record in the db to this
#   kind if testing procs, for statistics just 
#   or more control

set title "Record a new test"
set focus "new_test.test_name"
acs_user::get -array user_info
set creation_user $user_info(email)

ad_form -name new_test -method post -export {package_key return_url} \
    -form {
	test_id:key
	{ test_name:text
	    {label "Test Name"}
	    {html {size 50}}
	}
	{ test_description:text 
	    {label "Short Description"}
	    {html {size 70}}
	}
	{ search_str:text,optional
	    {label "Search String"}
	    {html {size 50}}
	    {help_text "Sometimes, you might need this string to check if the test is successful or no (i.e. testing Warning messages) <br> If you want to check more than one string, use a comma to separate the different strings"}
	}
	{ login_type:integer(select)
	    {label "Login Type"}
	    {options {{admin -1} {newuser -2} {searched_user 0}}}
	}
	{ login_id:party_search(party_search),optional
	    {label "Type a keyword to find a user"}
	}
	{ test_code:text(textarea),nospell
	    {html {cols 90 rows 50}}
	    {label "Test Code"}
	    {help_text "The test code itself, usually generated by the TwtR pluging for firefox (http://www.km.co.at/km/twtr)"}
	}
    } \
    -validate {
	{ test_name
	    { $test_name ne "" }
	    {The name can not contain special characteres, whitespaces or be null} 
	}
	{ login_type
	    { 1 } 
	    {You forgot to search the user}
	}
    } \
    -new_request {
	set test_name ""
	set test_description ""
	set test_code ""
	set search_str ""

    } \
    -new_data {
	
	# Open the automated tests tcl file 
	# of this package key and add the
	# test code to the script, then
	# do an eval to load the test proc.

	# Get the test directory
	set pkg_test_path "[acs_package_root_dir $package_key]/tcl/test/"

	# Create or Open the test cases file and add the
	# code
	set file_name "$package_key-recorded-test-procs.tcl"
	set full_path "${pkg_test_path}${file_name}"

	# Get the namespace
	set package_namespace "${package_key}::twt"

    if {$login_id eq ""} {
        if {$login_type == -2} {
#	    set login_code "twt::user:::create"
	    set login_code "
     array set user_info \[twt::user:::create\]
     twt::user::login \$user_info(email) \$user_info(password)
 "
        } elseif {$login_type == -1} {
#	    set login_code "twt::user:::create -admin"
	    set login_code "
     array set user_info \[twt::user::create -admin\]
     twt::user::login \$user_info(email) \$user_info(password)
 "
        }
    } else {
        set login_code "ad_user_login -forever $login_id"
    }
    
	if { ![file exists $full_path] } {
	    # file does not exist yet
	    set file [open $full_path w+]

	    puts $file "
ad_library {
    This library was generated automatically for Automated tests 
    for ${package_key}
    @author Automatically generated (Ref ${creation_user} ) 
    @creation-date [clock format [clock seconds] -format {%Y-%m-%d %H:%M}]
 }

namespace eval ${package_namespace} {}
"

	} else {
	    # file exists, let us do the job =)
	    set file [open $full_path a]
	}

        # To be able to use this cases in other server
        # we need to replace the URL generated by TwtR 
        # with the URL provided by ad_url, we could do 
        # a string map or use the regexp or regsub like
        #regsub {::tclwebtest::do_request
        # \{http://([^:/]+)(:([0-9]*))?} $line [ad_url] new_line2

	puts $file "
#------------------------------------------
#        Code for case ${test_name}
#------------------------------------------

aa_register_case \
   -cats {web smoke} \
   -libraries {tclwebtest} \
   ${test_name}_case {} {} {
       aa_log \"Running test case ${test_name} \"
       aa_log \"${test_description} \"
       set response 0
       aa_log \" Loging in the user\"
       $login_code
       #------------------ TwtR code -----------------
       ${test_code}
       #-------------- End ofTwtR code ---------------
       aa_log \"Test code executed\"
       set response_url \[tclwebtest::response url\]
       aa_log \"Response URL is \$response_url\"
       # Look for the text \$search_str if not empty
       if { \[string ne $search_str \"\"\] } {
           set string_list \[split \$search_str \",\"\]
           foreach item \$string_list {
    	   if { \[catch {tclwebtest::assert text \$item} errmsg\] } {
    	       aa_error \"Text \$item was not found!: \$errmsg\"
    	       incr errors
    	   } else {
    	       aa_log \"Good news! :), Text \$item was found!\"
    	   }
           }
       }
       # if no errors, test has passed
       if { !\$errors } {
           set response 1
       }
       aa_log \"Finishing ${package_namespace}::${test_name}\"
       twt::user::logout
       aa_display_result \
	   -response \$response \
	   -explanation \"for test: ${test_name} \"
   }
#------------------------------------------
#     End of code for case ${test_name}
#------------------------------------------
"

       close $file
    } -after_submit {
        set version_id [apm_version_id_from_package_key $package_key]
        apm_mark_version_for_reload $version_id files
        ad_returnredirect $return_url
    }


ad_return_template
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
