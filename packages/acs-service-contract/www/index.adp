<master>

<h2>ACS Service Contract</h2>

@context_bar@

<hr>

<h3>Installed Bindings</h3>
<ul>
<if @valid_installed_binding:rowcount@ eq 0>
  <li><i>None</i></li>
</if>
<else>
<multiple name=valid_installed_binding>
<li>@valid_installed_binding.contract_id@
@valid_installed_binding.contract_name@,
@valid_installed_binding.impl_id@
@valid_installed_binding.impl_name@
[<a href=binding-uninstall?contract_id=@valid_installed_binding.contract_id@&impl_id=@valid_installed_binding.impl_id@>Uninstall</a>]
</multiple>
</else>
</ul>



<h3>Valid Uninstalled Bindings</h3>
<ul>
<if @valid_uninstalled_binding:rowcount@ eq 0>
  <li><i>None</i></li>
</if>
<else>
<multiple name=valid_uninstalled_binding>
<li>@valid_uninstalled_binding.contract_id@
@valid_uninstalled_binding.contract_name@,
@valid_uninstalled_binding.impl_id@
@valid_uninstalled_binding.impl_name@
[<a href=binding-install?contract_id=@valid_uninstalled_binding.contract_id@&impl_id=@valid_uninstalled_binding.impl_id@>Install</a>]
</multiple>
</else>
</ul>



<h3>Invalid Uninstalled Bindings</h3>
<ul>
<if @invalid_uninstalled_binding:rowcount@ eq 0>
  <li><i>None</i></li>
</if>
<else>
<multiple name=invalid_uninstalled_binding>
<li>@invalid_uninstalled_binding.contract_id@
@invalid_uninstalled_binding.contract_name@,
@invalid_uninstalled_binding.impl_id@
@invalid_uninstalled_binding.impl_name@
[<a href=>What's wrong?</a>]
</multiple>
</else>
</ul>

<h3>Orphan Implementations</h3>
<ul>
<if @orphan_implementation:rowcount@ eq 0>
  <li><i>None</i></li>
</if>
<else>
<multiple name=orphan_implementation>
<li>@orphan_implementation.impl_id@
@orphan_implementation.impl_name@
@orphan_implementation.impl_contract_name@
</multiple>
</else>
</ul>