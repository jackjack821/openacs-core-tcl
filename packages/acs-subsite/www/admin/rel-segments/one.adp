<master>
<property name="context">@context@</property>
<property name="title">Segment "@props.segment_name@"</property>
				   
<h4>Properties of this segment</h4>

<ul>
  <li> Group: <a href=../groups/one?group_id=@props.group_id@>@props.group_name@</a> </li>
  <li> Relationship type: <a href=../rel-types/one?rel_type=@props.rel_type@>@props.rel_type_pretty_name@</a> </li>
  <li> Number of @props.role_pretty_plural@: <a href=elements?segment_id=@segment_id@>@number_elements@</a> </li>
</ul>

<h4>Constraints on this segment</h4>

<ul>
  <if @constraints:rowcount@ eq 0>
    <li>(none)</li>
  </if><else>
   <multiple name="constraints">
    <li> <a href="constraints/one?constraint_id=@constraints.constraint_id@">@constraints.constraint_name@</a> </li>
    </li>
   </multiple>
  </else>
  <p><li> <a href="constraints/new?rel_segment=@segment_id@">Add a constraint</a> </li>
</ul>


<if @admin_p@ eq "1">
  <h4>Administration</h4>
  <ul>
    <li> <a href=delete?segment_id=@props.segment_id@>Delete this segment</a> </li>
  </ul>
</if>

