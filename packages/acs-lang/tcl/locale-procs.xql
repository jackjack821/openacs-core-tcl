<?xml version="1.0"?>
<queryset>

   <fullquery name="lang::system::package_level_locale_not_cached.get_system_locale">      
      <querytext>
        select default_locale
        from   apm_packages
        where  package_id = :package_id
      </querytext>
   </fullquery>

   <fullquery name="lang::system::set_locale.update_system_locale">
      <querytext>
        update apm_packages
        set    default_locale = :locale 
        where  package_id = :package_id
      </querytext>
   </fullquery>

   <fullquery name="lang::user::package_level_locale_not_cached.get_user_locale">      
      <querytext>
        select locale
        from   ad_locale_user_prefs
        where  user_id = :user_id
        and    package_id = :package_id
      </querytext>
   </fullquery>

   <fullquery name="lang::user::site_wide_locale_not_cached.get_user_site_wide_locale">
      <querytext>
        select locale
        from   user_preferences
        where  user_id = :user_id
      </querytext>
   </fullquery>

    <fullquery name="lang::user::set_locale.set_user_site_wide_locale">
      <querytext>
        update user_preferences
        set    locale = :locale
        where  user_id = :user_id
      </querytext>
   </fullquery>

   <fullquery name="lang::user::set_locale.user_locale_exists_p">
      <querytext>
        select count(*) 
        from   ad_locale_user_prefs 
        where  user_id = :user_id
        and    package_id = :package_id
      </querytext>
   </fullquery>

   <fullquery name="lang::user::set_locale.update_user_locale">
      <querytext>
        update ad_locale_user_prefs 
        set    locale = :locale 
        where  user_id = :user_id 
        and    package_id = :package_id
      </querytext>
   </fullquery>

   <fullquery name="lang::user::set_locale.insert_user_locale">
      <querytext>
         insert into ad_locale_user_prefs (user_id, package_id, locale) 
        values (:user_id, :package_id, :locale)
      </querytext>
   </fullquery>


   <fullquery name="lang::user::set_locale.delete_user_locale">
      <querytext>
        delete 
        from   ad_locale_user_prefs 
        where  user_id = :user_id 
        and    package_id = :package_id
      </querytext>
   </fullquery>

</queryset>
