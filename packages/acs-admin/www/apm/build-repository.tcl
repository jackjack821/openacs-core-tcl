ad_page_contract {
    Build package repository.
}

# TODO: Build repository in temp dir, then rename

#----------------------------------------------------------------------
# Configuration Settings
#----------------------------------------------------------------------

set cvs_command "cvs"
set cvs_root ":pserver:anonymous@openacs.org:/cvsroot"
set dotlrn_cvs_root ":pserver:anonymous@dotlrn.openacs.org:/dotlrn-cvsroot"

set work_dir "[acs_root_dir]/repository-builder/"

set repository_dir "[acs_root_dir]/www/repository/"
set repository_url "http://openacs.org/repository/"

set exclude_package_list { cms cms-news-demo glossary site-wide-search spam library }

set head_channel "5-1"


#----------------------------------------------------------------------
# Prepare output
#----------------------------------------------------------------------

ReturnHeaders
ns_write [ad_header "Building repository"]
ns_write <ul>

#----------------------------------------------------------------------
# Find available channels
#----------------------------------------------------------------------

# Prepare work dir
file mkdir $work_dir

cd $work_dir
catch { exec $cvs_command -d $cvs_root -z3 co openacs-4/readme.txt }

catch { exec $cvs_command -d $cvs_root -z3 log -h openacs-4/readme.txt } output

set lines [split $output \n]
for { set i 0 } { $i < [llength $lines] } { incr i } {
    if { [string equal [string trim [lindex $lines $i]] "symbolic names:"] } {
        incr i
        break
    }
}

array set channel_tag [list]
array set channel_bugfix_version [list]

for { } { $i < [llength $lines] } { incr i } {
    # Tag lines have the form   tag: cvs-version
    #     openacs-5-0-0-final: 1.25.2.5

    if { ![regexp {^\s+([^:]+):\s+([0-9.]+)} [lindex $lines $i] match tag_name version_name] } {
        break
    }
    
    # Look for tags named 'openacs-x-y-compat'
    if { [regexp {^openacs-([1-9][0-9]*-[0-9]+)-compat$} $tag_name match oacs_version] } {
        
        set major_version [lindex [split $oacs_version "-"] 0]
        set minor_version [lindex [split $oacs_version "-"] 1]

        if { $major_version >= 5 } {
            set channel "${major_version}-${minor_version}"

            ns_write "<li>Found channel $channel using tag $tag_name\n"

            set channel_tag($channel) $tag_name
        }
    }
}

set channel_tag($head_channel) HEAD


ns_write "<li>Channels are: [array get channel_tag]\n"


#----------------------------------------------------------------------
# Read all package .info files, building manifest file
#----------------------------------------------------------------------

# Wipe and re-create the working directory
file delete -force $work_dir
file mkdir ${work_dir}
cd $work_dir
    
foreach channel [lsort -decreasing [array names channel_tag]] {
    ns_write "<li>Starting channel $channel with tag $channel_tag($channel)\n"

    # Wipe and re-create the checkout directory
    file delete -force "${work_dir}openacs-4"
    file delete -force "${work_dir}dotlrn"
    file mkdir -force "${work_dir}dotlrn/packages"
    
    # Prepare channel directory
    set channel_dir "${work_dir}repository/${channel}/"
    file mkdir $channel_dir

    # Store the list of packages we've seen for this channel, so we don't include the same package twice
    # Seems odd, but we have to do this given the forked packages sitting in /contrib
    set packages [list]
    
    # Checkout from the tag given by channel_tag($channel)
    if { ![string equal $channel_tag($channel) HEAD] } {
        catch { exec $cvs_command -d $cvs_root -z3 co -r $channel_tag($channel) openacs-4/packages } output
        catch { exec $cvs_command -d $cvs_root -z3 co -r $channel_tag($channel) openacs-4/contrib/packages } output
        cd ${work_dir}dotlrn/packages/
        catch { exec $cvs_command -d $dotlrn_cvs_root -z3 co -r $channel_tag($channel) dotlrn-core } output
        cd $work_dir
    } else {
        catch { exec $cvs_command -d $cvs_root -z3 co openacs-4/packages } output
        catch { exec $cvs_command -d $cvs_root -z3 co openacs-4/contrib/packages } output
        cd ${work_dir}dotlrn/packages/
        catch { exec $cvs_command -d $dotlrn_cvs_root -z3 co dotlrn-core } output
        cd $work_dir
    }

    set manifest {<manifest>}
    append manifest \n
    
    foreach packages_dir \
        [list "${work_dir}openacs-4/packages" \
             "${work_dir}openacs-4/contrib/packages" \
             "${work_dir}dotlrn/packages"] {

        foreach spec_file [lsort [apm_scan_packages $packages_dir]] {
        
            set package_path [eval file join [lrange [file split $spec_file] 0 end-1]]
            set package_key [lindex [file split $spec_file] end-1]

            if { [lsearch -exact $exclude_package_list $package_key] != -1 } {
                ns_write "Package $package_key is on list of packages to exclude - skipping"
                continue
            }

            if { [array exists version] } {
                array unset version
            }
            if { [info exists version] } {
                unset version
            }

            with_catch errmsg {
                array set version [apm_read_package_info_file $spec_file]
                
                if { [lsearch -exact $packages $version(package.key)] != -1 } {
                    ns_write "<li>Skipping package $package_key, because we already have another version of it"
                } else {
                    lappend packages $version(package.key)
                    
                    append manifest {  } {<package>} \n
                
                    append manifest {    } {<package-key>} [ad_quotehtml $version(package.key)] {</package-key>} \n
                    append manifest {    } {<version>} [ad_quotehtml $version(name)] {</version>} \n
                    append manifest {    } {<pretty-name>} [ad_quotehtml $version(package-name)] {</pretty-name>} \n
                    append manifest {    } {<package-type>} [ad_quotehtml $version(package.type)] {</package-type>} \n
                    append manifest {    } {<summary>} [ad_quotehtml $version(summary)] {</summary>} \n
                    append manifest {    } {<description format="} [ad_quotehtml $version(description.format)] {">} 
                    append manifest [ad_quotehtml $version(description)] {</description>} \n
                    append manifest {    } {<release-date>} [ad_quotehtml $version(release-date)] {</release-date>} \n
                    append manifest {    } {<vendor url="} [ad_quotehtml $version(vendor.url)] {">} 
                    append manifest [ad_quotehtml $version(vendor)] {</vendor>} \n
                    
                    set apm_file "${channel_dir}${version(package.key)}-${version(name)}.apm"

                    ns_write "<li> Building package $package_key for channel $channel in file $apm_file\n"
                    
                    set files [apm_get_package_files \
                                   -all_db_types \
                                   -package_key $version(package.key) \
                                   -package_path $package_path]
                    
                    if { [llength $files] == 0 } {
                        ns_write "No files in package"
                    } else {
                        set cmd [list exec [apm_tar_cmd] cf -  2>/dev/null]

                        # The path to the 'packages' directory in the checkout
                        set packages_root_path [eval file join [lrange [file split $spec_file] 0 end-2]]
                        
                        lappend cmd -C $packages_root_path
                        foreach file $files {
                            lappend cmd $package_key/$file
                        }
                        lappend cmd "|" [apm_gzip_cmd] -c ">" $apm_file
                        ns_log Notice "Executing: [ad_quotehtml $cmd]"
                        eval $cmd
                    }


                    set apm_url "${repository_url}${channel}/${version(package.key)}-${version(name)}.apm"

                    append manifest {    } {<download-url>} $apm_url {</download-url>} \n
                    foreach elm $version(provides) {
                        append manifest {    } "<provides url=\"[ad_quotehtml [lindex $elm 0]]\" version=\"[ad_quotehtml [lindex $elm 1]]\" />" \n
                    }
                    
                    foreach elm $version(requires) {
                        append manifest {    } "<requires url=\"[ad_quotehtml [lindex $elm 0]]\" version=\"[ad_quotehtml [lindex $elm 1]]\" />" \n
                    }
                    
                    append manifest {  } {</package>} \n
                } 
            } {
                global errorInfo
                ns_write "<li> Error on spec_file $spec_file: [ad_quotehtml $errmsg]<br>[ad_quotehtml $errorInfo]\n"
            }
        }
    }
    append manifest {</manifest>} \n
    
    ns_write "<li>Writing $channel manifest to ${channel_dir}manifest.xml"
    set fw [open "${channel_dir}manifest.xml" w]
    puts $fw $manifest
    close $fw

    ns_write "<li> Channel $channel complete.\n"
    
}

# Without the trailing slash
set work_repository_dirname "${work_dir}repository"
set repository_dirname [string range $repository_dir 0 end-1]
set repository_bak "[string range $repository_dir 0 end-1].bak"

ns_write "<li>Moving work repository $work_repository_dirname to live repository dir at $repository_dir\n"

if { [file exists $repository_bak] } {
    file delete -force $repository_bak
}
if { [file exists $repository_dirname] } {
    file rename $repository_dirname $repository_bak
}
file rename $work_repository_dirname  $repository_dirname

ns_write "</ul> DONE.\n"

        
