<master>
<property name="title">Update Basic Information</property>
<property name="context_bar">in @site_link;noquote@</property>
<property name="context">Update Information</property>

<form method="post" action="basic-info-update-2">
@export_vars;noquote@
<table>
<tr>
 <th>Name:</th><td><input type="text" name="first_names" size="20" value="@first_names@" /> 
                <input type="text" name="last_name" size="25" value="@last_name@" /></td>
</tr>
<tr>
 <th>email address:</th><td><input type="text" name="email" size="30" value="@email@" /></td>
</tr>
<tr>
 <th>Personal URL:</th><td><input type="text" name="url" size="50" value="@url@" /></td>
</tr>
<tr>
 <th>screen name:</th><td><input type="text" name="screen_name" size="30" value="@screen_name@" /></td>
</tr>
<tr>
 <th>Biography:</th><td><textarea name="bio" rows="10" cols="50" wrap="soft">@bio@</textarea></td>
</tr>
</table>

<p><center>
<input type=submit value="Update">
</center></p>


