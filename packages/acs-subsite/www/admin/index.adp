<master>
<property name="context">@context@</property>
<property name="title">@subsite_name@ Administration</property>

<ul>
  <li><a href=site-map/>Site Map</a>
  <li><a href=groups/>Groups</a>
  <li><a href=group-types/>Group Types</a>
  <li><a href=rel-segments/>Relational Segments</a>
  <li><a href=rel-types/>Relationship Types</a>
  <li><a href=host-node-map/>Host-Node Map</a>
  <li><a href=object-types/>Object Types</a>
</ul>

<if @acs_admin_available_p@ true>
  To administer the site-wide services of OpenACS, use
  <a href="@acs_admin_url@">@instance_name@</a>.
</if>
<else>
  The Site-Wide Administration service is not available.  If you are a
  site-wide administrator, use the <a href="site-map">Site Map</a> to
  mount the Site-Wide Administration service.  This provides an
  interface for administering the site-wide services of OpenACS.
</else>
