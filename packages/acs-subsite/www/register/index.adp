<master>
  <property name="title">#acs-subsite.Log_In#</property>
  <property name="focus">@focus@</property>
  <property name="context">{#acs-subsite.Log_In#}</property>

<include src="/packages/acs-subsite/lib/login" return_url="@return_url;noquote@" no_frame_p="1" authority_id="@authority_id@" username="@username;noquote@" email="@email;noquote@">
