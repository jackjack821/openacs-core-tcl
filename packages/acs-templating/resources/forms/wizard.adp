<!-- Dark blue frame -->
<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0>
<tr><td>

<!-- Light blue pad -->
<table bgcolor=#99CCFF cellspacing=0 cellpadding=6 border=0 width="100%">
<tr><td>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">

  <multiple name=elements>
  
    <if @elements.section@ not nil>
      <tr><td colspan=2 bgcolor=#eeeeee><b>@elements.section@</b></td></tr>
    </if>

    <group column="section">

    <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
    </if>

    <else>
      <if @elements.widget@ in "submit" "button">
        <!-- put it at the bottom -->
      </if>
      <else>
        <!-- If the widget is wide, display it in its own section -->
        <if @elements.wide@ not nil>
          <tr><td colspan=2 bgcolor=#eeeeee><b>@elements.label@</b></td></tr>
          <tr><td colspan=2>
        </if>
        <else>
          <tr><td><b>@elements.label@</b>&nbsp;&nbsp;
          <if @elements.help_text@ not nil>
            <br>&nbsp;&nbsp;
            <font size=-1><noparse><formhelp id=@elements.id@></noparse></font><br>
          </if></td>
        </else>

	  <if @elements.widget@ in radio checkbox>
            <if @elements.wide@ not nil>
              <if @elements.help_text@ not nil>
                &nbsp;&nbsp;
                <font size=-1><noparse><formhelp id=@elements.id@></noparse></font><br>
              </if>
            </if><else><td></else>
              <noparse>
		<table cellpadding=4 cellspacing=0 border=0>

		<formgroup id=@elements.id@ cols=4>
		  <if \@formgroup.col@ eq 1><tr></if>

		  <if \@formgroup.rownum@ le \@formgroup:rowcount@>
		    <td align=right>&nbsp;\@formgroup.widget@</td>      
		    <td align=left><label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">\@formgroup.label@</label></td> 
		  </if><else><td>&nbsp;</td><td>&nbsp;</td></else>

		<if \@formgroup.col@ eq 4></tr></if>

		</formgroup>

		</table>
		<formerror id=@elements.id@><br>
		  <font color="red"><b>\@formerror.@elements.id@\@</b></font>
		</formerror>
              </noparse>
	    </td>
	  </if>
	  <else> 
	    <if @elements.widget@ eq inform>
	      <if @elements.wide@ not nil>
                <noparse>
                  <formerror  id=@elements.id@><br>
                    <font color="red"><b>\@formerror.@elements.id@\@</b></font><br>
                  </formerror>
                </noparse>
              </if><else><td bgcolor=#EEEEEE></else>
		<noparse><formwidget id=@elements.id@></noparse>
	      </td>
	    </if>
	    <else>
	      <if @elements.wide@ not nil></if><else><td nowrap></else>
		<noparse><formwidget id=@elements.id@>
		<formerror id=@elements.id@><br><font 
		   color="red"><b>\@formerror.@elements.id@\@<b></font>
                </formerror></noparse>
	      </td>
	    </else>
	  </else>
      </tr>
      </else>
    </else>

    </group>

  </multiple>

  </table>

</td></tr>

<noparse><if \@form_properties.has_submit\@ nil></noparse>
  <tr>
    <td align=right>
      <if @form_properties.mode@ not nil and @form_properties.mode@ ne "edit">
        <input type=submit name="__edit" value="     Edit     ">
      </if>
      <else>
        <multiple name="buttons">
          <if @buttons.name@ eq "ok">
            <input type="submit" name="@buttons.name@" value="      @buttons.label@      ">
          </if>
          <else>
            <input type="submit" name="@buttons.name@" value="@buttons.label@">
          </else>
        </multiple>
      </else>
    </td>
  </tr>
<noparse></if></noparse>
<noparse><else></noparse>
  <tr><td align=right colspan=2>
    <table border=0 cellspacing=5 cellpadding=0>
      <tr>
      <multiple name=elements>
        <if @elements.widget@ in "submit" "button">
          <td><noparse><formwidget id=@elements.id@></noparse></td>
        </if>
      </multiple>
      </tr>
    </table>
  </td></tr>
<noparse></else></noparse>
 
</table>

<!-- Light blue pad -->
</td></tr>
</table>

<!-- Dark blue frame -->
</td></tr>
</table>


