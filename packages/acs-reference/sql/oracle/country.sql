-- packages/acs-reference/sql/country.sql
--
-- @author jon@arsdigita.com
-- @creation-date 2000-11-21
-- @cvs-id $Id$

-- country is taken from ISO 3166

-- probably ought to add a note about analyze for efficiency on non-integer primary keys

create table countries (
    iso char(2)
        constraint countries_iso_pk
        primary key,
    -- this is the three letter abbreviation - hardly used
    a3  char(3),
    -- this is the numeric code - hardly used
    -- it is a char because of leading zeros so it isn't really a number
    numeric char(3),
    -- this violates 3nf but is used for 2 reasons
    -- 1. to help efficiency
    -- 2. to make querys not fail if no translation exists yet
    default_name varchar(100)
        constraint countries_default_name_nn
        not null
        constraint countries_default_name_uq
        unique
);

comment on table countries is '
    This is the country code/english name table from ISO 3166.
';

comment on column countries.default_name is '
    This is admittedly a violation of 3NF but it is more efficient and helps with non-translated values.
See country.sql for more comments.
';
 
comment on column countries.a3 is '
   This is the three letter abbreviation - hardly used.
';

comment on column countries.numeric is ' 
    This is the numeric code - hardly used.
';

-- add this table into the reference repository
declare
    v_id integer;
begin
    v_id := acs_reference.new(
        table_name     => 'COUNTRIES',
        source         => 'ISO 3166',
        source_url     => 'http://www.din.de/gremien/nas/nabd/iso3166ma/codlstp1/db_en.html',
        last_update    => to_date('2000-08-21','YYYY-MM-DD'),
        effective_date => sysdate
    );
commit;
end;
/

-- This is the translated mapping of country names

create table country_names (
    -- lookup into the countries table
    iso char(2)
        constraint country_names_iso_fk
        references countries (iso),
    -- lookup into the language_codes table
    language_code 
        constraint country_names_language_code_fk
        references language_codes (language_id),
    -- the translated name
    name varchar(100)
);

comment on table country_names is ' 
    This is the translated mapping of country names and language codes.
';

comment on column country_names.language_code is '
    This is a lookup into the iso languages table.
';

-- I need to know the easy way to add extended chars in sqlplus then I can add french and spanish

-- ISO country codes

set feedback off;

insert into countries (default_name,iso) values ('AFGHANISTAN','AF');
insert into countries (default_name,iso) values ('ALBANIA','AL');
insert into countries (default_name,iso) values ('ALGERIA','DZ'); 
insert into countries (default_name,iso) values ('AMERICAN SAMOA','AS'); 
insert into countries (default_name,iso) values ('ANDORRA','AD');
insert into countries (default_name,iso) values ('ANGOLA','AO');
insert into countries (default_name,iso) values ('ANGUILLA','AI');
insert into countries (default_name,iso) values ('ANTARCTICA','AQ');
insert into countries (default_name,iso) values ('ANTIGUA AND BARBUDA','AG');
insert into countries (default_name,iso) values ('ARGENTINA','AR');
insert into countries (default_name,iso) values ('ARMENIA','AM');
insert into countries (default_name,iso) values ('ARUBA','AW');
insert into countries (default_name,iso) values ('AUSTRALIA','AU'); 
insert into countries (default_name,iso) values ('AUSTRIA','AT');
insert into countries (default_name,iso) values ('AZERBAIJAN','AZ'); 
insert into countries (default_name,iso) values ('BAHAMAS','BS');
insert into countries (default_name,iso) values ('BAHRAIN','BH');
insert into countries (default_name,iso) values ('BANGLADESH','BD'); 
insert into countries (default_name,iso) values ('BARBADOS','BB');
insert into countries (default_name,iso) values ('BELARUS','BY');
insert into countries (default_name,iso) values ('BELGIUM','BE');
insert into countries (default_name,iso) values ('BELIZE','BZ');
insert into countries (default_name,iso) values ('BENIN','BJ');
insert into countries (default_name,iso) values ('BERMUDA','BM');
insert into countries (default_name,iso) values ('BHUTAN','BT');
insert into countries (default_name,iso) values ('BOLIVIA','BO');
insert into countries (default_name,iso) values ('BOSNIA AND HERZEGOVINA','BA');
insert into countries (default_name,iso) values ('BOTSWANA','BW');
insert into countries (default_name,iso) values ('BOUVET ISLAND','BV'); 
insert into countries (default_name,iso) values ('BRAZIL','BR');
insert into countries (default_name,iso) values ('BRITISH INDIAN OCEAN TERRITORY','IO');
insert into countries (default_name,iso) values ('BRUNEI DARUSSALAM','BN');
insert into countries (default_name,iso) values ('BULGARIA','BG');
insert into countries (default_name,iso) values ('BURKINA FASO','BF'); 
insert into countries (default_name,iso) values ('BURUNDI','BI');
insert into countries (default_name,iso) values ('CAMBODIA','KH');
insert into countries (default_name,iso) values ('CAMEROON','CM');
insert into countries (default_name,iso) values ('CANADA','CA');
insert into countries (default_name,iso) values ('CAPE VERDE','CV'); 
insert into countries (default_name,iso) values ('CAYMAN ISLANDS','KY'); 
insert into countries (default_name,iso) values ('CENTRAL AFRICAN REPUBLIC','CF');
insert into countries (default_name,iso) values ('CHAD','TD');
insert into countries (default_name,iso) values ('CHILE','CL');
insert into countries (default_name,iso) values ('CHINA','CN');
insert into countries (default_name,iso) values ('CHRISTMAS ISLAND','CX');
insert into countries (default_name,iso) values ('COCOS (KEELING) ISLANDS','CC');
insert into countries (default_name,iso) values ('COLOMBIA','CO');
insert into countries (default_name,iso) values ('COMOROS','KM');
insert into countries (default_name,iso) values ('CONGO','CG');
insert into countries (default_name,iso) values ('CONGO, THE DEMOCRATIC REPUBLIC OF THE','CD');
insert into countries (default_name,iso) values ('COOK ISLANDS','CK');
insert into countries (default_name,iso) values ('COSTA RICA','CR');
insert into countries (default_name,iso) values ('COTE D''IVOIRE','CI');
insert into countries (default_name,iso) values ('CROATIA','HR');
insert into countries (default_name,iso) values ('CUBA','CU');
insert into countries (default_name,iso) values ('CYPRUS','CY');
insert into countries (default_name,iso) values ('CZECH REPUBLIC','CZ');
insert into countries (default_name,iso) values ('DENMARK','DK');
insert into countries (default_name,iso) values ('DJIBOUTI','DJ');
insert into countries (default_name,iso) values ('DOMINICA','DM');
insert into countries (default_name,iso) values ('DOMINICAN REPUBLIC','DO');
insert into countries (default_name,iso) values ('EAST TIMOR','TP');
insert into countries (default_name,iso) values ('ECUADOR','EC');
insert into countries (default_name,iso) values ('EGYPT','EG');
insert into countries (default_name,iso) values ('EL SALVADOR','SV'); 
insert into countries (default_name,iso) values ('EQUATORIAL GUINEA','GQ'); 
insert into countries (default_name,iso) values ('ERITREA','ER');
insert into countries (default_name,iso) values ('ESTONIA','EE');
insert into countries (default_name,iso) values ('ETHIOPIA','ET');
insert into countries (default_name,iso) values ('FALKLAND ISLANDS (MALVINAS)','FK');
insert into countries (default_name,iso) values ('FAROE ISLANDS','FO');
insert into countries (default_name,iso) values ('FIJI','FJ');
insert into countries (default_name,iso) values ('FINLAND','FI'); 
insert into countries (default_name,iso) values ('FRANCE','FR');
insert into countries (default_name,iso) values ('FRENCH GUIANA','GF');
insert into countries (default_name,iso) values ('FRENCH POLYNESIA','PF'); 
insert into countries (default_name,iso) values ('FRENCH SOUTHERN TERRITORIES','TF'); 
insert into countries (default_name,iso) values ('GABON','GA'); 
insert into countries (default_name,iso) values ('GAMBIA','GM');
insert into countries (default_name,iso) values ('GEORGIA','GE');
insert into countries (default_name,iso) values ('GERMANY','DE');
insert into countries (default_name,iso) values ('GHANA','GH');
insert into countries (default_name,iso) values ('GIBRALTAR','GI'); 
insert into countries (default_name,iso) values ('GREECE','GR');
insert into countries (default_name,iso) values ('GREENLAND','GL'); 
insert into countries (default_name,iso) values ('GRENADA','GD');
insert into countries (default_name,iso) values ('GUADELOUPE','GP'); 
insert into countries (default_name,iso) values ('GUAM','GU');
insert into countries (default_name,iso) values ('GUATEMALA','GT'); 
insert into countries (default_name,iso) values ('GUINEA','GN');
insert into countries (default_name,iso) values ('GUINEA-BISSAU','GW'); 
insert into countries (default_name,iso) values ('GUYANA','GY');
insert into countries (default_name,iso) values ('HAITI','HT');
insert into countries (default_name,iso) values ('HEARD ISLAND AND MCDONALD ISLANDS','HM');
insert into countries (default_name,iso) values ('HOLY SEE (VATICAN CITY STATE)','VA');
insert into countries (default_name,iso) values ('HONDURAS','HN');
insert into countries (default_name,iso) values ('HONG KONG','HK');
insert into countries (default_name,iso) values ('HUNGARY','HU');
insert into countries (default_name,iso) values ('ICELAND','IS');
insert into countries (default_name,iso) values ('INDIA','IN');
insert into countries (default_name,iso) values ('INDONESIA','ID'); 
insert into countries (default_name,iso) values ('IRAN, ISLAMIC REPUBLIC OF','IR');
insert into countries (default_name,iso) values ('IRAQ','IQ');
insert into countries (default_name,iso) values ('IRELAND','IE'); 
insert into countries (default_name,iso) values ('ISRAEL','IL');
insert into countries (default_name,iso) values ('ITALY','IT');
insert into countries (default_name,iso) values ('JAMAICA','JM');
insert into countries (default_name,iso) values ('JAPAN','JP');
insert into countries (default_name,iso) values ('JORDAN','JO');
insert into countries (default_name,iso) values ('KAZAKSTAN','KZ'); 
insert into countries (default_name,iso) values ('KENYA','KE');
insert into countries (default_name,iso) values ('KIRIBATI','KI'); 
insert into countries (default_name,iso) values ('KOREA, DEMOCRATIC PEOPLE''S REPUBLIC OF','KP');
insert into countries (default_name,iso) values ('KOREA, REPUBLIC OF','KR');
insert into countries (default_name,iso) values ('KUWAIT','KW');
insert into countries (default_name,iso) values ('KYRGYZSTAN','KG'); 
insert into countries (default_name,iso) values ('LAO PEOPLE''S DEMOCRATIC REPUBLIC','LA');
insert into countries (default_name,iso) values ('LATVIA','LV');
insert into countries (default_name,iso) values ('LEBANON','LB');
insert into countries (default_name,iso) values ('LESOTHO','LS');
insert into countries (default_name,iso) values ('LIBERIA','LR');
insert into countries (default_name,iso) values ('LIBYAN ARAB JAMAHIRIYA','LY');
insert into countries (default_name,iso) values ('LIECHTENSTEIN','LI');
insert into countries (default_name,iso) values ('LITHUANIA','LT');
insert into countries (default_name,iso) values ('LUXEMBOURG','LU');
insert into countries (default_name,iso) values ('MACAU','MO');
insert into countries (default_name,iso) values ('MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF','MK');
insert into countries (default_name,iso) values ('MADAGASCAR','MG');
insert into countries (default_name,iso) values ('MALAWI','MW'); 
insert into countries (default_name,iso) values ('MALAYSIA','MY');
insert into countries (default_name,iso) values ('MALDIVES','MV');
insert into countries (default_name,iso) values ('MALI','ML');
insert into countries (default_name,iso) values ('MALTA','MT');
insert into countries (default_name,iso) values ('MARSHALL ISLANDS','MH');
insert into countries (default_name,iso) values ('MARTINIQUE','MQ');
insert into countries (default_name,iso) values ('MAURITANIA','MR');
insert into countries (default_name,iso) values ('MAURITIUS','MU');
insert into countries (default_name,iso) values ('MAYOTTE','YT');
insert into countries (default_name,iso) values ('MEXICO','MX');
insert into countries (default_name,iso) values ('MICRONESIA, FEDERATED STATES OF','FM');
insert into countries (default_name,iso) values ('MOLDOVA, REPUBLIC OF','MD');
insert into countries (default_name,iso) values ('MONACO','MC');
insert into countries (default_name,iso) values ('MONGOLIA','MN');
insert into countries (default_name,iso) values ('MONTSERRAT','MS');
insert into countries (default_name,iso) values ('MOROCCO','MA');
insert into countries (default_name,iso) values ('MOZAMBIQUE','MZ'); 
insert into countries (default_name,iso) values ('MYANMAR','MM');
insert into countries (default_name,iso) values ('NAMIBIA','NA');
insert into countries (default_name,iso) values ('NAURU','NR');
insert into countries (default_name,iso) values ('NEPAL','NP');
insert into countries (default_name,iso) values ('NETHERLANDS','NL'); 
insert into countries (default_name,iso) values ('NETHERLANDS ANTILLES','AN');
insert into countries (default_name,iso) values ('NEW CALEDONIA','NC');
insert into countries (default_name,iso) values ('NEW ZEALAND','NZ');
insert into countries (default_name,iso) values ('NICARAGUA','NI');
insert into countries (default_name,iso) values ('NIGER','NE');
insert into countries (default_name,iso) values ('NIGERIA','NG');
insert into countries (default_name,iso) values ('NIUE','NU');
insert into countries (default_name,iso) values ('NORFOLK ISLAND','NF');
insert into countries (default_name,iso) values ('NORTHERN MARIANA ISLANDS','MP');
insert into countries (default_name,iso) values ('NORWAY','NO');
insert into countries (default_name,iso) values ('OMAN','OM');
insert into countries (default_name,iso) values ('PAKISTAN','PK'); 
insert into countries (default_name,iso) values ('PALAU','PW');
insert into countries (default_name,iso) values ('PALESTINIAN TERRITORY, OCCUPIED','PS');
insert into countries (default_name,iso) values ('PANAMA','PA');
insert into countries (default_name,iso) values ('PAPUA NEW GUINEA','PG');
insert into countries (default_name,iso) values ('PARAGUAY','PY');
insert into countries (default_name,iso) values ('PERU','PE');
insert into countries (default_name,iso) values ('PHILIPPINES','PH');
insert into countries (default_name,iso) values ('PITCAIRN','PN');
insert into countries (default_name,iso) values ('POLAND','PL');
insert into countries (default_name,iso) values ('PORTUGAL','PT');
insert into countries (default_name,iso) values ('PUERTO RICO','PR'); 
insert into countries (default_name,iso) values ('QATAR','QA');
insert into countries (default_name,iso) values ('REUNION','RE');
insert into countries (default_name,iso) values ('ROMANIA','RO');
insert into countries (default_name,iso) values ('RUSSIAN FEDERATION','RU');
insert into countries (default_name,iso) values ('RWANDA','RW');
insert into countries (default_name,iso) values ('SAINT HELENA','SH');
insert into countries (default_name,iso) values ('SAINT KITTS AND NEVIS','KN');
insert into countries (default_name,iso) values ('SAINT LUCIA','LC');
insert into countries (default_name,iso) values ('SAINT PIERRE AND MIQUELON','PM');
insert into countries (default_name,iso) values ('SAINT VINCENT AND THE GRENADINES','VC');
insert into countries (default_name,iso) values ('SAMOA','WS');
insert into countries (default_name,iso) values ('SAN MARINO','SM'); 
insert into countries (default_name,iso) values ('SAO TOME AND PRINCIPE','ST');
insert into countries (default_name,iso) values ('SAUDI ARABIA','SA');
insert into countries (default_name,iso) values ('SENEGAL','SN');
insert into countries (default_name,iso) values ('SEYCHELLES','SC'); 
insert into countries (default_name,iso) values ('SIERRA LEONE','SL');
insert into countries (default_name,iso) values ('SINGAPORE','SG');
insert into countries (default_name,iso) values ('SLOVAKIA','SK');
insert into countries (default_name,iso) values ('SLOVENIA','SI');
insert into countries (default_name,iso) values ('SOLOMON ISLANDS','SB');
insert into countries (default_name,iso) values ('SOMALIA','SO');
insert into countries (default_name,iso) values ('SOUTH AFRICA','ZA'); 
insert into countries (default_name,iso) values ('SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS','GS');
insert into countries (default_name,iso) values ('SPAIN','ES');
insert into countries (default_name,iso) values ('SRI LANKA','LK'); 
insert into countries (default_name,iso) values ('SUDAN','SD');
insert into countries (default_name,iso) values ('SURINAME','SR'); 
insert into countries (default_name,iso) values ('SVALBARD AND JAN MAYEN','SJ');
insert into countries (default_name,iso) values ('SWAZILAND','SZ');
insert into countries (default_name,iso) values ('SWEDEN','SE');
insert into countries (default_name,iso) values ('SWITZERLAND','CH');
insert into countries (default_name,iso) values ('SYRIAN ARAB REPUBLIC','SY');
insert into countries (default_name,iso) values ('TAIWAN, PROVINCE OF CHINA','TW');
insert into countries (default_name,iso) values ('TAJIKISTAN','TJ');
insert into countries (default_name,iso) values ('TANZANIA, UNITED REPUBLIC OF','TZ');
insert into countries (default_name,iso) values ('THAILAND','TH');
insert into countries (default_name,iso) values ('TOGO','TG');
insert into countries (default_name,iso) values ('TOKELAU','TK'); 
insert into countries (default_name,iso) values ('TONGA','TO');
insert into countries (default_name,iso) values ('TRINIDAD AND TOBAGO','TT');
insert into countries (default_name,iso) values ('TUNISIA','TN');
insert into countries (default_name,iso) values ('TURKEY','TR');
insert into countries (default_name,iso) values ('TURKMENISTAN','TM');
insert into countries (default_name,iso) values ('TURKS AND CAICOS ISLANDS','TC');
insert into countries (default_name,iso) values ('TUVALU','TV');
insert into countries (default_name,iso) values ('UGANDA','UG');
insert into countries (default_name,iso) values ('UKRAINE','UA');
insert into countries (default_name,iso) values ('UNITED ARAB EMIRATES','AE');
insert into countries (default_name,iso) values ('UNITED KINGDOM','GB');
insert into countries (default_name,iso) values ('UNITED STATES','US');
insert into countries (default_name,iso) values ('UNITED STATES MINOR OUTLYING ISLANDS','UM');
insert into countries (default_name,iso) values ('URUGUAY','UY');
insert into countries (default_name,iso) values ('UZBEKISTAN','UZ'); 
insert into countries (default_name,iso) values ('VANUATU','VU');
insert into countries (default_name,iso) values ('VENEZUELA','VE');
insert into countries (default_name,iso) values ('VIET NAM','VN');
insert into countries (default_name,iso) values ('VIRGIN ISLANDS, BRITISH','VG');
insert into countries (default_name,iso) values ('VIRGIN ISLANDS, U.S.','VI');
insert into countries (default_name,iso) values ('WALLIS AND FUTUNA','WF');
insert into countries (default_name,iso) values ('WESTERN SAHARA','EH');
insert into countries (default_name,iso) values ('YEMEN','YE');
insert into countries (default_name,iso) values ('YUGOSLAVIA','YU'); 
insert into countries (default_name,iso) values ('ZAMBIA','ZM');
insert into countries (default_name,iso) values ('ZIMBABWE','ZW');
			
set feedback on;
commit;



