# /packages/mbryzek-subsite/www/admin/index.tcl

ad_page_contract {

    View an OpenACS Object Type

    @author Yonantan Feldman (yon@arsdigita.com)
    @creation-date August 13, 2000
    @cvs-id $Id$

} {
    object_type:notnull
}


if { ![db_0or1row object_type {
    select supertype,
           abstract_p,
           pretty_name,
           pretty_plural,
           table_name,
           id_column,
           name_method,
           type_extension_table,
           package_name,
           dynamic_p
      from acs_object_types
     where object_type = :object_type
}] } {
    ad_return_complaint 1 "<li> The specified object type, $object_type, does not exist"
    ad_script_abort
}



set title "Details for type $pretty_name"

set page "
[ad_admin_header $title]
<h2>$title</h2>
[ad_admin_context_bar [list "./index" "Object Type Administration"] $title]
<hr>
<ul>"

append page "
 <table border=0 cellspacing=0 cellpadding=0 width=90%>
  <tr>
   <td>[acs_object_type_hierarchy -object_type $object_type]</td>
   <td align=right>
    <a href=\"./index\">Hierarchical Index</a>&nbsp;|&nbsp;<a href=\"./alphabetical-index\">Alphabetical Index</a>
   </td>
  </tr>
 </table>

<p>
<b>Information</b>:
 <ul>
  <li>Pretty Name: $pretty_name</li>
  <li>Pretty Plural: $pretty_plural</li>
  <li>Abstract: [ad_decode $abstract_p "f" "False" "True"]</li>
  <li>Dynamic: [ad_decode $dynamic_p "f" "False" "True"]</li>
  [ad_decode $table_name "" "" "<li>Table Name: $table_name</li>"]
  [ad_decode $id_column "" "" "<li>Primary Key: $id_column</li>"]
  [ad_decode $name_method "" "" "<li>Name Method: $name_method</li>"]
  [ad_decode $type_extension_table "" "" "<li>Helper Table: $type_extension_table</li>"]
  [ad_decode $package_name "" "" "<li>Package Name: $package_name</li>"]
 </ul>"

set i 0
set body "
    <table border=0 cellpadding=5 cellspacing=5>
     <tr>
      <th align=left>Attribute Name</th>
      <th align=left>Pretty Name</th>
      <th align=left>Pretty Plural</th>
      <th align=left>Datatype</th>
      <th align=left>Default Value</th>
      <th align=left>Minimum Number of Values</th>
      <th align=left>Maximum Number of Values</th>
      <th align=left>Storage</th>
      <th align=left>Table Name</th>
      <th align=left>Column Name</th>
     </tr>"

db_foreach attribute {
    select attribute_name,
           pretty_name,
           pretty_plural,
           datatype,
           default_value,
           min_n_values,
           max_n_values,
           storage,
           table_name as attr_table_name,
           column_name
      from acs_attributes
     where object_type = :object_type
} {
    incr i
    append body "
     <tr>
      <td>$attribute_name</td>
      <td>$pretty_name</td>
      <td>$pretty_plural</td>
      <td>$datatype</td>
      <td>$default_value</td>
      <td>$min_n_values</td>
      <td>$max_n_values</td>
      <td>$storage</td>
      <td>[string tolower $attr_table_name]</td>
      <td>[string tolower $column_name]</td>
     </tr>"
}

append body "
    </table>"

    if { $i > 0 } {
	append page "
<p>
<b>Attributes</b>:
 <ul>
$body
 </ul>"
    }

if { [exists_and_not_null table_name] } {

    set body [db_string table_comment "select comments from user_tab_comments where table_name = '[string toupper $table_name]'" -default ""]

    append body "
    <table border=0 cellpadding=5 cellspacing=5>
     <tr>
      <th align=left>Type</th>
      <th align=left>Name</th>
      <th align=left>Comment</th>
     </tr>"

    set i 0
    db_foreach attribute "
	select utc.column_name,
	       utc.data_type,
               ucc.comments
	  from user_tab_columns utc,
               user_col_comments ucc
	 where utc.table_name = '[string toupper $table_name]'
           and utc.table_name = ucc.table_name(+)
           and utc.column_name = ucc.column_name(+)
    " {
	incr i
	append body "
     <tr>
      <td>[string tolower $column_name]</td>
      <td>[string tolower $data_type]</td>
      <td>$comments</td>
     </tr>"
    }

    append body "
    </table>"

    if { $i > 0 } {
	append page "
<p>
<b>Table Attributes</b>:
 <ul>
$body
 </ul>"
    }
}

set i 0
set body ""
db_foreach package_index {
    select replace (replace (text, ' ', '&nbsp;'), chr(9), '&nbsp;&nbsp;&nbsp;&nbsp;') as text
      from user_source
     where lower(name) = :package_name
       and type = 'PACKAGE BODY'
     order by line
} {
    incr i
    append body "$text"
}

if { $i > 0 } {
    append page "
<p>
<b>Methods</b>:
 <ul>
  <pre>
   <code>
$body
   </code>
  </pre>
 </ul>"
}

append page "
</ul>
[ad_admin_footer]"

ns_return 200 text/html $page
