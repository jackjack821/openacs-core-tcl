<?xml version="1.0"?>
<queryset>

   <fullquery name="lang::util::charset_for_locale.charset_for_locale">      
      <querytext>
      
        select mime_charset
        from   ad_locales 
        where  locale = :locale
    
      </querytext>
   </fullquery>

   <fullquery name="lang::util::default_locale_from_lang_not_cached.default_locale_from_lang">
      <querytext>
        select locale
        from   ad_locales
        where  language = '[db_quote $language]'
        and    enabled_p = 't'
        and    (default_p = 't' or
                (select count(*)
                from ad_locales
                where language = '[db_quote $language]') = 1
                    )
      </querytext>
   </fullquery>

</queryset>
