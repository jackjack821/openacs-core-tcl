  <master>
    <property name="title">Permissions for @name@</property>
    <property name="context">@context@</property>

    <h3>Inherited Permissions</h3>
    <if @inherited:rowcount@ gt 0>
      <ul>
        <multiple name="inherited">
          <li>@inherited.grantee_name@, @inherited.privilege@</li>
        </multiple>
      </ul>
    </if>
    <else>
      <p><em>No inherited permissions</em></p>
    </else>
    <h3>Direct Permissions</h3>
    <if @acl:rowcount@ gt 0>
      <form method="get" action="revoke">
        <input type=hidden name="object_id" value="@object_id@">
          <ul>
            <multiple name="acl">
              <li> @acl.grantee_name@, @acl.privilege@ <input type="checkbox" name="revoke_list" value="@acl.grantee_id@ @acl.privilege@"></li>
            </multiple>
          </ul>
    </if>
    <else>
      <p><em>None</em></p>
    </else>
    <if @acl:rowcount@ gt 0>
    <input type=submit value="Revoke Checked">
    </form>
    </if>
    @controls@

    <h3>Children</h3>
    <if @children_p@>
      <if @children:rowcount@ gt 0>
        <ul>
          <multiple name="children">
            <li><a href="one?object_id=@children.c_object_id@">@children.c_name@</a> @children.c_type@</li>
          </multiple>
        </ul>
      </if>
      <else>
        <p><em>No children</em></p>
      </else>
    </if>
    <if @children_p@ eq "f">
      <if @num_children@ gt 0> @num_children@ Children Hidden [<a href="one?object_id=@object_id@&amp;children_p=t">Show</a>]</if>
      <else>
        <em>No children</em>
      </else>
    </if>
    <if @context_id@ not nil><p>[<a href="one?object_id=@context_id@">up to @context_name@</a>]</p></if>      