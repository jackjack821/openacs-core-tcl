#!/bin/sh
#
# This script attempts to check that catalog files of a certain package
# (or all packages if no package key is provided) are consistent with
# eachother and that they are consistent with lookups in the code. More
# specifically the script does the following:
#
# 1) Checks that the info in the catalog filename matches info in
#    its xml content (package_key, locale and charset).
# 
# 2) Checks that the set of keys in the message catalog is identical to the
#    set of keys in the adp, info, sql, and tcl files in the package.
#
# 3) Checks that the set of keys in non-en_US catalog files is present
#    in the en_US catalog file of the package.
#
# 4) Checks that all keys in non-en_US catalog files are present in the en_US one.
#
# 5) Checks that the package version in every catalog file is consistent with what
#    is in the corresponding info file.
#
# The scripts assumes that message lookups in adp and info files are 
# on the format #package_key.message_key#, and that message lookups 
# in tcl files are always done with the underscore procedure. 
#
# usage: check-catalog.sh [package_key package_key ...]
#
# @author Peter Marklund (peter@collaboraid.biz)

### Functions start
get_catalog_keys() {
    file_name=$1
    echo $(${script_path}/mygrep '<msg key="([^"]+)"' $file_name)
}

check_package_version_of_catalog_files() {
    
    info_file_package_version=$(cat ${package_key}.info | ${script_path}/mygrep '<version name="([^"]+)"')

    for catalog_file in $(ls catalog/${package_key}*.xml)
    do
        catalog_package_version=$(cat $catalog_file | ${script_path}/mygrep '<message_catalog .*package_version="([^"]+)"')

        if [ ! "$info_file_package_version" == "$catalog_package_version" ]; then
            echo "$0: $package_key - Warning: package version $catalog_package_version in file $catalog_file does not equal version $info_file_package_version in info file."
        fi
    done
}

check_consistency_non_en_US_files() {
    en_US_file=catalog/${package_key}.en_US.ISO-8859-1.xml

    for file_name in $(ls catalog/${package_key}*.xml | grep -v 'en_US.ISO-8859-1.xml')
    do
        echo "$0: $package_key - checking that keys in $file_name are also in en_US catalog file"

        for catalog_key in `get_catalog_keys $file_name`
        do
            egrep -q "<msg key=\"${catalog_key}\">" $en_US_file || echo "$0: $package_key - Warning: key $catalog_key in $file_name missing in $en_US_file"
        done
    done
}

check_catalog_keys_have_lookups() {

    # Check that all keys in the catalog file are either in tcl or adp or info files
    for catalog_key in `get_catalog_keys catalog/${package_key}.en_US.ISO-8859-1.xml` 
    do 
        lookup_lines=$(find ../ -regex '.*\.\(info\|adp\|sql\|tcl\)' | xargs egrep "${package_key}\.$catalog_key")
        
        if [ -z "$lookup_lines" ]; then
            echo "$0: $package_key - Warning key $catalog_key in catalog file not found in any adp, info, sql, or tcl file"
        fi
    done
}

check_tcl_file_lookups_are_in_catalog() {

    # Check that all message lookups in tcl files have entries in the message catalog
    for tcl_message_key in $(find ../ -iname '*.tcl'|xargs ${script_path}/mygrep \
                             "(?ms)\[_\s+(?:\[ad_conn locale\]\s+)?\"?${package_key}\.([a-zA-Z0-9_\-\.]+)\"?")
    do 
        egrep -q "<msg[[:space:]]+key=\"$tcl_message_key\"" catalog/${package_key}.en_US.ISO-8859-1.xml \
          || \
        echo "$0: $package_key - Warning: key $tcl_message_key not in catalog file" 
    done
}

check_adp_file_lookups_are_in_catalog() {

    catalog_file=catalog/${package_key}.en_US.ISO-8859-1.xml

    # Check that all message lookups in adp and info files are in the catalog file
    for adp_message_key in $(find ../ -regex '.*\.\(info\|adp\)'|xargs ${script_path}/mygrep \
                            "#${package_key}\.([a-zA-Z0-9_\-\.]+)#")
    do 
        egrep -q "<msg[[:space:]]+key=\"$adp_message_key\"" $catalog_file \
          || \
        echo "$0: $package_key - Warning: key $adp_message_key not in catalog file"
    done
}
### Functions end

script_path=$(dirname $(which $0))
packages_dir="${script_path}/../../"

# Process arguments
if [ "$#" == "0" ]; then
    # No package provided - check all packages
    for catalog_dir in $(find $package_dir -iname catalog -type d)
    do
        # Recurse with each package key that has a catalog dir
        $0 $(basename $(dirname $catalog_dir))
    done

    exit 0
fi

for package_key in "$@"
do
    export package_key

    # Check that the catalog file exists
    catalog_file_path="${packages_dir}${package_key}/catalog/${package_key}.en_US.ISO-8859-1.xml"
    if [ ! -e $catalog_file_path ]; then
        echo "$0: Error - the file $catalog_file_path in package $package_key doesn't exist, exiting"
        exit 1
    fi

    package_path="${script_path}/../../${package_key}"
    cd $package_path

    for file_name in $(ls catalog/*.xml)
    do
        echo "$0: $package_key - checking filename consistency of catalog file $file_name"
        ${script_path}/check-catalog-file-path.pl "${package_path}/${file_name}"
    done

    echo "$0: $package_key - checking en_US catalog keys are in lookups"
    check_catalog_keys_have_lookups

    echo "$0: $package_key - checking tcl lookups are in en_US catalog file"
    check_tcl_file_lookups_are_in_catalog

    echo "$0: $package_key - checking adp lookups are in en_US catalog file"
    check_adp_file_lookups_are_in_catalog

    check_consistency_non_en_US_files

    echo "$0: $package_key - checking that package version in each catalog file is consistent with package version in corresponding info file"
    check_package_version_of_catalog_files
done
