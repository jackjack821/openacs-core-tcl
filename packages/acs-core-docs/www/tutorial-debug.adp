
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Debugging and Automated Testing}</property>
<property name="doc(title)">Debugging and Automated Testing</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-pages" leftLabel="Prev"
		    title="
Chapter 9. Development Tutorial"
		    rightLink="tutorial-advanced" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-debug" id="tutorial-debug"></a>Debugging and Automated Testing</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140205652257432" id="idp140205652257432"></a>Debugging</h3></div></div></div><p>
<strong>Developer Support. </strong>The Developer
Support package adds several goodies: debug information for every
page; the ability to log comments to the page instead of the error
log, and fast user switching so that you can test pages as
anonymous and as dummy users without logging in and out.</p><p>
<strong>PostgreSQL. </strong>You can work directly
with the database to do debugging steps like looking directly at
tables and testing stored procedures. Start emacs. Type
<strong class="userinput"><code>M-x sql-postgres</code></strong>.
Press enter for server name and use <strong class="userinput"><code><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></code></strong>
for database name. You can use C-(up arrow) and C-(down arrow) for
command history.</p><p>Hint: "Parse error near *" usually means that an xql
file wasn&#39;t recognized, because the Tcl file is choking on the
*SQL* placeholder that it falls back on.</p><p><strong>Watching the server log. </strong></p><p>To set up real-time monitoring of the AOLserver error log,
<span class="bold"><strong>type</strong></span>
</p><pre class="screen">
less /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/log/openacs-dev-error.log
</pre><div class="literallayout"><p>
F to show new log entries in real time (like tail -f)<br>

C-c to stop and F to start it up again. <br>

G goes to the end.<br>

? searches backward <br>
/ searches forward. <br>
          </p></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140205645002936" id="idp140205645002936"></a>Manual testing</h3></div></div></div><p>Make a list of basic tests to make sure it works</p><div class="segmentedlist"><table border="0">
<thead><tr class="segtitle">
<th>Test Num</th><th>Action</th><th>Expected Result</th>
</tr></thead><tbody>
<tr class="seglistitem">
<td class="seg">001</td><td class="seg">Browse to the index page while not logged in and
while one or more notes exist.</td><td class="seg">No edit or delete or add links should appear.</td>
</tr><tr class="seglistitem">
<td class="seg">002</td><td class="seg">Browse to the index page while logged in. An Edit
link should appear. Click on it. Fill out the form and click
Submit.</td><td class="seg">The text added in the form should be visible on the
index page.</td>
</tr><tr class="seglistitem">
<td class="seg">API-001</td><td class="seg">Invoke mfp::note::create with a specific word as
the title.</td><td class="seg">Proc should return an object id.</td>
</tr><tr class="seglistitem">
<td class="seg">API-002</td><td class="seg">Given an object id from API-001, invoke
mfp::note::get.</td><td class="seg">Proc should return the specific word in the
title.</td>
</tr><tr class="seglistitem">
<td class="seg">API-003</td><td class="seg">Given the object id from API-001, invoke
mfp::note::delete.</td><td class="seg">Proc should return 0 for success.</td>
</tr>
</tbody>
</table></div><p>Other things to test: try to delete someone else&#39;s note. Try
to delete your own note. Edit your own note. Search for a note.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="idp140205661882680" id="idp140205661882680"></a>Write automated tests</h3></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:simon\@collaboraid.net" target="_top">Simon Carstensen</a> and Joel Aufrecht</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>
<a class="indexterm" name="idp140205661884728" id="idp140205661884728"></a> It seems to me that a lot of people have
been asking for some guidelines on how to write automated tests.
I&#39;ve done several tests by now and have found the process to be
extremely easy and useful. It&#39;s a joy to work with automated
testing once you get the hang of it.</p><p>Create the directory that will contain the test script and edit
the script file. The directory location and file name are standards
which are recognized by the automated testing package:</p><pre class="screen">
[$OPENACS_SERVICE_NAME www]$<strong class="userinput"><code> mkdir /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/tcl/test</code></strong>
[$OPENACS_SERVICE_NAME www]$<strong class="userinput"><code> cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/myfirstpackage/tcl/test</code></strong>
[$OPENACS_SERVICE_NAME test]$ <strong class="userinput"><code>emacs myfirstpackages-procs.tcl</code></strong>
</pre><p>Write the tests. This is obviously the big step :) The script
should first call ad_library like any normal -procs.tcl file:</p><pre class="screen">
ad_library {
    ...
}
</pre><p>To create a test case you call <code class="computeroutput">
<a class="ulink" href="/api-doc/proc-view?proc=aa%5fregister%5fcase" target="_top">aa_register_case</a> test_case_name.</code>. Once you&#39;ve
created the test case you start writing the needed logic. We&#39;ll
use the tutorial package, "myfirstpackage," as an
example. Let&#39;s say you just wrote an <a class="ulink" href="/api-doc" target="_top">API</a> for adding and deleting notes in
the notes packages and wanted to test that. You&#39;d probably want
to write a test that first creates a note, then verifies that it
was inserted, then perhaps deletes it again, and finally verifies
that it is gone.</p><p>Naturally this means you&#39;ll be adding a lot of bogus data to
the database, which you&#39;re not really interested in having
there. To avoid this I usually do two things. I always put all my
test code inside a call to aa_run_with_teardown which basically
means that all the inserts, deletes, and updates will be rolled
back once the test has been executed. A very useful feature.
Instead of inserting bogus data like: <code class="computeroutput">set name "Simon"</code>, I tend to
generate a random script in order avoid inserting a value
that&#39;s already in the database:</p><pre class="screen">
set name [ad_generate_random_string]
</pre><p>Here&#39;s how the test case looks so far:</p><pre class="screen">
aa_register_case mfp_basic_test {
    My test
} {
    aa_run_with_teardown \
       -rollback \
       -test_code  {

       }
}
</pre><p>Now let&#39;s look at the actual test code. That&#39;s the code
that goes inside <code class="computeroutput">-test_code {}</code>.
We want to implement test case API-001, "Given an object id
from API-001, invoke mfp::note::get. Proc should return the
specific word in the title."</p><pre class="programlisting">
      set name [ad_generate_random_string]
      set new_id [mfp::note::add -title $name]
      aa_true "Note add succeeded" ([info exists new_id] &amp;&amp; $new_id ne "")
</pre><p>To test our simple case, we must load the test file into the
system (just as with the /tcl file in the basic tutorial, since the
file didn&#39;t exist when the system started, the system
doesn&#39;t know about it.) To make this file take effect, go to
the <a class="ulink" href="/acs-admin/apm" target="_top">APM</a>
and choose "Reload changed" for
"MyFirstPackage". Since we&#39;ll be changing it
frequently, select "watch this file" on the next page.
This will cause the system to check this file every time any page
is requested, which is bad for production systems but convenient
for developing. We can also add some aa_register_case flags to make
it easier to run the test. The <code class="computeroutput">-procs</code> flag, which indicates which procs
are tested by this test case, makes it easier to find procs in your
package that aren&#39;t tested at all. The <code class="computeroutput">-cats</code> flag, setting categories, makes it
easier to control which tests to run. The <code class="computeroutput">smoke</code> test setting means that this is a
basic test case that can and should be run any time you are doing
any test. (<a class="ulink" href="http://www.nedbatchelder.com/blog/20030408T062805.html" target="_top">a definition of "smoke test"</a>)</p><p>Once the file is loaded, go to <a class="ulink" href="/test" target="_top">ACS Automated Testing</a> and click on
myfirstpackage. You should see your test case. Run it and examine
the results.</p><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140205661901656" id="idp140205661901656"></a>TCLWebtest tests</h4></div></div></div><p>API testing can only test part of our package - it doesn&#39;t
test the code in our adp/tcl pairs. For this, we can use
TCLwebtest. TCLwebtest must be <a class="link" href="install-tclwebtest" title="Install tclwebtest.">installed</a>
for this test to work. This provides a <a class="ulink" href="http://tclwebtest.sourceforge.net/doc/api_public.html" target="_top">library of functions</a> that make it easy to call a page
through HTTP, examine the results, and drive forms.
TCLwebtest&#39;s functions overlap slightly with
acs-automated-testing; see the example provided for one approach on
integrating them.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140205661904216" id="idp140205661904216"></a>Example</h4></div></div></div><p>Now we can add the rest of the API tests, including a test with
deliberately bad data. The complete test looks like:</p><pre class="programlisting">
ad_library {
    Test cases for my first package.
}

aa_register_case \
    -cats {smoke api} \
    -procs {mfp::note::add mfp::note::get mfp::note::delete} \
    mfp_basic_test \
    {
        A simple test that adds, retrieves, and deletes a record.
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code  {
                set name [ad_generate_random_string]
                set new_id [mfp::note::add -title $name]
                aa_true "Note add succeeded" ([info exists new_id] &amp;&amp; $new_id ne "")
                
                mfp::note::get -item_id $new_id -array note_array
                aa_true "Note contains correct title" [string equal $note_array(title) $name]
                
                mfp::note::delete -item_id $new_id
                
                set get_again [catch {mfp::note::get -item_id $new_id -array note_array}]
                aa_false "After deleting a note, retrieving it fails" [expr {$get_again == 0}]
            }
    }

aa_register_case \
    -cats {api} \
    -procs {mfp::note::add mfp::note::get mfp::note::delete} \
    mfp_bad_data_test \
    {
        A simple test that adds, retrieves, and deletes a record, using some tricky data.
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code  {
                set name {-Bad [BAD] \077 { $Bad}} 
                append name [ad_generate_random_string]
                set new_id [mfp::note::add -title $name]
                aa_true "Note add succeeded" ([info exists new_id] &amp;&amp; $new_id ne "")
                
                mfp::note::get -item_id $new_id -array note_array
                aa_true "Note contains correct title" [string equal $note_array(title) $name]
                aa_log "Title is $name"
                mfp::note::delete -item_id $new_id
                
                set get_again [catch {mfp::note::get -item_id $new_id -array note_array}]
                aa_false "After deleting a note, retrieving it fails" [expr {$get_again == 0}]
            }
    }


aa_register_case \
    -cats {web smoke} \
    -libraries tclwebtest \
    mfp_web_basic_test \
    {
        A simple tclwebtest test case for the tutorial demo package.
        
        \@author Peter Marklund
    } {
        # we need to get a user_id here so that it&#39;s available throughout
        # this proc
        set user_id [db_nextval acs_object_id_seq]

        set note_title [ad_generate_random_string]

        # NOTE: Never use the aa_run_with_teardown with the rollback switch
        # when running Tclwebtest tests since this will put the test code in
        # a transaction and changes won&#39;t be visible across HTTP requests.
        
        aa_run_with_teardown -test_code {
            
            #-------------------------------------------------------------
            # Login
            #-------------------------------------------------------------
            
            # Make a site-wide admin user for this test
            # We use an admin to avoid permission issues
            array set user_info [twt::user::create -admin -user_id $user_id]
            
            # Login the user
            twt::user::login $user_info(email) $user_info(password)
            
            #-------------------------------------------------------------
            # New Note
            #-------------------------------------------------------------
            
            # Request note-edit page
            set package_uri [apm_package_url_from_key myfirstpackage]
            set edit_uri "${package_uri}note-edit"
            aa_log "[twt::server_url]$edit_uri"
            twt::do_request "[twt::server_url]$edit_uri"
            
            # Submit a new note

            tclwebtest::form find ~n note
            tclwebtest::field find ~n title
            tclwebtest::field fill $note_title
            tclwebtest::form submit
            
            #-------------------------------------------------------------
            # Retrieve note
            #-------------------------------------------------------------
            
            # Request index page and verify that note is in listing
            tclwebtest::do_request $package_uri                 
            aa_true "New note with title \"$note_title\" is found in index page" \
                [string match "*${note_title}*" [tclwebtest::response body]]
            
            #-------------------------------------------------------------
            # Delete Note
            #-------------------------------------------------------------
            # Delete all notes

            # Three options to delete the note
            # 1) go directly to the database to get the id
            # 2) require an API function that takes name and returns ID
            # 3) screen-scrape for the ID
            # all options are problematic.  We&#39;ll do #1 in this example:

            set note_id [db_string get_note_id_from_name " 
                select item_id 
                  from cr_items 
                 where name = :note_title  
                   and content_type = 'mfp_note'
            " -default 0]

            aa_log "Deleting note with id $note_id"

            set delete_uri "${package_uri}note-delete?item_id=${note_id}"
            twt::do_request $delete_uri
            
            # Request index page and verify that note is in listing
            tclwebtest::do_request $package_uri                 
            aa_true "Note with title \"$note_title\" is not found in index page after deletion." \
                ![string match "*${note_title}*" [tclwebtest::response body]]
            
        } -teardown_code {
            
            twt::user::delete -user_id $user_id
        }
    }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
</pre><p>See also <a class="xref" href="automated-testing-best-practices" title="Automated Testing">the section called
&ldquo;Automated Testing&rdquo;</a>.</p>
</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-pages" leftLabel="Prev" leftTitle="Creating Web Pages"
		    rightLink="tutorial-advanced" rightLabel="Next" rightTitle="
Chapter 10. Advanced Topics"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial" upLabel="Up"> 
		