<master>
 <property name="title">@page_title;noquote@</property>
 <property name="context">@context;noquote@</property>

<formtemplate id="search">
Search <formwidget id="search_locale"> for <formwidget id="q"> <input type="submit" value="Search">
</formtemplate>

<if @locale_enabled_p@>
  <p>
    <b>&raquo;</b> <a href="@import_all_url@" title="Imports all messages for this locale from the catalog files"  onclick="return confirm('Importing messages for this locale from the filesystem should typically only be done once. If you already have translated messages in this locale those may be overwritten by the import, so be very cautious.');">Import all messages for this locale</a>
  </p>
  <p>
    <b>&raquo;</b> <a href="@export_all_url@" title="Export all messages for this locale to the catalog files">Export all messages for this locale</a>
  </p>
</if>

<table cellpadding="0" cellspacing="0" border="0">
  <tr>
    <td style="background: #CCCCCC">

      <table cellpadding="4" cellspacing="1" border="0">
        <tr valign="middle" style="background: #FFFFE4">
          <th></th>
          <th>Package</th>
          <th>Translated</th>
          <th>Untranslated</th>
          <th>Total</th>
        </tr>
        <multiple name="packages">
          <tr style="background: #EEEEEE">
            <td>
              <a href="@packages.batch_edit_url@" title="Batch edit all messages in this @packages.package_key@"><img src="/shared/images/Edit16.gif" border="0" width="16" height="16"></a>
            </td>
            <td>
              <a href="@packages.view_messages_url@" title="View all messages in package">@packages.package_key@</a>
            </td>
            <td align="right">
              <if @packages.num_translated_pretty@ ne 0>
                <a href="@packages.view_translated_url@" title="View all translated messages in package">@packages.num_translated_pretty@</a>
              </if>
            </td>
            <td align="right">
              <if @packages.num_untranslated_pretty@ ne 0>
                <a href="@packages.view_untranslated_url@" title="View all untranslated messages in package">@packages.num_untranslated_pretty@</a>
              </if>
            </td>
            <td align="right">
              <if @packages.num_messages_pretty@ ne 0>
                <a href="@packages.view_messages_url@" title="View all messages in package">@packages.num_messages_pretty@</a>
                </if>
            </td>
          </tr>
        </multiple>
      </table>

    </td>
  </tr>
</table>
