<master src="/www/blank-master">
  <if @title@ not nil>
    <property name="title">@title;noquote@</property>
  </if>
  <if @signatory@ not nil>
    <property name="signatory">@signatory;noquote@</property>
  </if>
  <if @focus@ not nil>
    <property name="focus">@focus;noquote@</property>
  </if>
  <if @context_bar@ not nil>
    <property name="context_bar">@context_bar;noquote@</property>
  </if>
  <if @context@ not nil>
    <property name="context">@context;noquote@</property>
  </if>
  <property name="header_stuff">
    @header_stuff;noquote@
    <link rel="stylesheet" type="text/css" href="@css_url@" media="all">
  </property>


<!-- Header -->

<table cellspacing="0" cellpadding="0" width="100%" class="subsite-header" border="0">
  <tr class="subsite-header">
    <td class="system-name" width="25%">
      <a href="@system_url@" class="system-name">@system_name@</a>
    </td>

    <td align="center" class="subsite-header" width="25%">
      <if @user_id@ ne 0>
        Welcome, @user_name@
      </if>
      <else>
        Not logged in
      </else>
    </td>

    <td align="right" class="subsite-header" style="padding-right: 8px;" width="50%">
      <if @admin_url@ not nil>
        &nbsp;
        <span class="button-header"><a href="@admin_url@" title="Site-wide administration" class="button">Admin</a></span>
      </if>
      <if @admin_url@ not nil>
        &nbsp;
        <span class="button-header"><a href="@devhome_url@" title="Developer's Administration" class="button">DevAdmin</a></span>
      </if>
      <if @pvt_home_url@ not nil>
        &nbsp;
        <span class="button-header"><a href="@pvt_home_url@" title="Change password, email, portrait" class="button">@pvt_home_name@</a></span>
      </if>
      <if @logout_url@ not nil>
        &nbsp;
        <span class="button-header"><a href="@logout_url@?return_url=@subsite_url@" title="Logout from @system_name@" class="button">Logout</a></span>
      </if>
      <if @login_url@ not nil>
        &nbsp;
        <span class="button-header"><a href="@login_url@" title="Log in to @system_name@" class="button">Log in</a></span>
      </if>
    </td>
  </tr>
</table>

<slave>

<if @curriculum_bar_p@ true>
<include src="/packages/curriculum/lib/bar" />
</if>
