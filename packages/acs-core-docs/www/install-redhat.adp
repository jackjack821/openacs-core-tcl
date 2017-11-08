
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Appendix A. Install Red Hat
8/9}</property>
<property name="doc(title)">Appendix A. Install Red Hat
8/9</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="backups-with-cvs" leftLabel="Prev"
		    title="
Part II. Administrator&#39;s Guide"
		    rightLink="install-more-software" rightLabel="Next">
		<div class="appendix">
<div class="titlepage"><div><div><h2 class="title">
<a name="install-redhat" id="install-redhat"></a>Appendix A. Install
Red Hat 8/9</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">by <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel
Aufrecht</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>This section takes a blank PC and sets up some supporting
software. You should do this section as-is if you have a machine
you can reformat and you want to be sure that your installation
works and is secure; it should take about an hour. (In my
experience, it&#39;s almost always a net time savings of several
hours to install a new machine from scratch compared to installing
each of these packages installed independently.)</p><p>The installation guide assumes you have:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>A PC with hard drive you can reinstall</p></li><li class="listitem"><p>Red Hat 8.0 or 9.0 install discs</p></li><li class="listitem"><p>A CD with the current <a class="ulink" href="http://www.redhat.com/apps/support/errata/" target="_top">Security
Patches</a> for your version of Red Hat.</p></li>
</ul></div><p>The installation guide assumes that you can do the following on
your platform:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Adding users, groups, setting passwords</p></li><li class="listitem"><p>(For Oracle) Starting an X server and running an X program
remotely</p></li><li class="listitem"><p>Basic file management using <code class="computeroutput">cp, rm,
mv,</code> and <code class="computeroutput">cd</code>
</p></li><li class="listitem"><p>Compiling a program using ./config and make.</p></li>
</ul></div><p>You can complete this install without the above knowledge, but
if anything goes wrong it may take extra time to understand and
correct the problem. <a class="link" href="install-resources" title="Resources">Some useful UNIX resources</a>.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<a name="install-first-step" id="install-first-step"></a>Unplug
the network cable from your computer. We don&#39;t want to connect
to the network until we&#39;re sure the computer is secure.
<a class="indexterm" name="idp140623091303016" id="idp140623091303016"></a> (Wherever you see the word secure, you
should always read it as, "secure enough for our purposes,
given the amount of work we&#39;re willing to exert and the
estimated risk and consequences.")</p></li><li class="listitem"><p>Insert Red Hat 8.0 or 9.0 Disk 1 into the CD-ROM and reboot the
computer</p></li><li class="listitem"><p>At the <code class="computeroutput"><span class="guilabel">boot:</span></code> prompt, press Enter for a graphical
install. The text install is fairly different, so if you need to do
that instead proceed with caution, because the guide won&#39;t
match the steps.</p></li><li class="listitem"><p>Checking the media is probably a waste of time, so when it asks
press Tab and then Enter to skip it.</p></li><li class="listitem"><p>After the graphical introduction page loads, click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>
</p></li><li class="listitem"><p>Choose the language you want to use and then click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>
</p></li><li class="listitem"><p>Select the keyboard layout you will use and Click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>
</p></li><li class="listitem"><p>Choose your mouse type and Click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>
</p></li><li class="listitem"><p>Red Hat has several templates for new computers. We&#39;ll start
with the "Server" template and then fine-tune it during
the rest of the install. Choose <code class="computeroutput"><span class="guilabel">Server</span></code> and
click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>.</p></li><li class="listitem">
<p>Reformat the hard drive. If you know what you&#39;re doing, do
this step on your own. Otherwise: we&#39;re going to let the
installer wipe out the everything on the main hard drive and then
arrange things to its liking.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Choose <code class="computeroutput"><span class="guilabel">Automatically Partition</span></code> and click
<code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>
</p></li><li class="listitem"><p>Uncheck <code class="computeroutput"><span class="guilabel">Re<span class="accel">v</span>iew (and modify if needed)
the partitions created</span></code> and click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>
</p></li><li class="listitem"><p>On the pop-up window asking "Are you sure you want to do
this?" click <code class="computeroutput"><span class="guibutton">
<span class="accel">Y</span>es</span></code> IF YOU ARE
WIPING YOUR HARD DRIVE.</p></li><li class="listitem"><p>Click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code> on the
boot loader screen</p></li>
</ol></div>
</li><li class="listitem">
<p>Configure Networking. <a class="indexterm" name="idp140623091331368" id="idp140623091331368"></a> Again, if you
know what you&#39;re doing, do this step yourself, being sure to
note the firewall holes. Otherwise, follow the instructions in this
step to set up a computer directly connected to the internet with a
dedicated IP address.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>DHCP is a system by which a computer that joins a network (such
as on boot) can request a temporary IP address and other network
information. Assuming the machine has a dedicated IP address (if it
doesn&#39;t, it will be tricky to access the OpenACS service from
the outside world), we&#39;re going to set up that address. If you
don&#39;t know your netmask, 255.255.255.0 is usually a pretty safe
guess. Click <code class="computeroutput"><span class="guibutton">Edit</span></code>, uncheck <code class="computeroutput"><span class="guilabel">Configure using
<span class="accel">D</span>HCP</span></code> and type in your IP
and netmask. Click <code class="computeroutput"><span class="guibutton">
<span class="accel">O</span>k</span></code>.</p></li><li class="listitem"><p>Type in your host name, gateway, and DNS server(s). Then click
<code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>.</p></li><li class="listitem"><p>We&#39;re going to use the firewall template for high security,
meaning that we&#39;ll block almost all incoming traffic. Then
we&#39;ll add a few holes to the firewall for services which we
need and know are secure. Choose <code class="computeroutput"><span class="guilabel">Hi<span class="accel">g</span>h</span></code> security level. Check <code class="computeroutput"><span class="guilabel">WWW</span></code>,
<code class="computeroutput"><span class="guilabel">SSH</span></code>, and <code class="computeroutput"><span class="guilabel">Mail (SMTP)</span></code>.
In the <code class="computeroutput"><span class="guilabel">Other
<span class="accel">p</span>orts</span></code> box, enter
<strong class="userinput"><code>443, 8000, 8443</code></strong>.
Click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>. Port 443
is for https (http over ssl), and 8000 and 8443 are http and https
access to the development server we&#39;ll be setting up.</p></li>
</ol></div>
</li><li class="listitem"><p>
<a class="indexterm" name="idp140623091350264" id="idp140623091350264"></a>Select any additional languages you want
the computer to support and then click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>
</p></li><li class="listitem"><p>Choose your time zone and click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>.</p></li><li class="listitem"><p>Type in a root password, twice.</p></li><li class="listitem">
<p>On the Package selection page, we&#39;re going to uncheck a lot
of packages that install software we don&#39;t need, and add
packages that have stuff we do need. You should install everything
we&#39;re installing here or the guide may not work for you; you
can install extra stuff, or ignore the instructions here to not
install stuff, with relative impunity - at worst, you&#39;ll
introduce a security risk that&#39;s still screened by the
firewall, or a resource hog. Just don&#39;t install a database or
web server, because that would conflict with the database and web
server we&#39;ll install later.</p><table border="0" summary="Simple list" class="simplelist">
<tr><td>check <code class="computeroutput"><span class="guilabel">Editors</span></code> (this installs emacs<a class="indexterm" name="idp140623091358664" id="idp140623091358664"></a>),</td></tr><tr><td>click <code class="computeroutput"><span class="guilabel">Details</span></code> next to <code class="computeroutput"><span class="guilabel">Text-based
Internet</span></code>, check <code class="computeroutput"><span class="guilabel">lynx</span></code>, and
click <code class="computeroutput"><span class="guibutton">
<span class="accel">O</span>K</span></code>;</td></tr><tr><td>check <code class="computeroutput"><span class="guilabel">Authoring and Publishing</span></code> (<a class="indexterm" name="idp140623091366120" id="idp140623091366120"></a>this installs docbook),</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">Server Configuration Tools</span></code>,</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">Web
Server</span></code>,</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">Windows File Server</span></code>,</td></tr><tr><td>check <code class="computeroutput"><span class="guilabel">SQL
Database Server</span></code> (this installs PostgreSQL),</td></tr><tr><td>check <code class="computeroutput"><span class="guilabel">Development Tools</span></code> (this installs gmake and
other build tools),</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">Administration Tools</span></code>, and</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">Printing Support</span></code>.</td></tr>
</table><p>At the bottom, check <code class="computeroutput"><span class="guilabel">
<span class="accel">S</span>elect Individual
Packages</span></code> and click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>
</p>
</li><li class="listitem">
<p>We need to fine-tune the exact list of packages. The same rules
apply as in the last step - you can add more stuff, but you
shouldn&#39;t remove anything the guide adds. We&#39;re going to go
through all the packages in one big list, so select <code class="computeroutput"><span class="guilabel">
<span class="accel">F</span>lat View</span></code> and wait. In a minute, a
list of packages will appear.</p><table border="0" summary="Simple list" class="simplelist">
<tr><td>uncheck <code class="computeroutput"><span class="guilabel">apmd</span></code> (monitors power, not very useful for
servers),</td></tr><tr><td>check <code class="computeroutput"><span class="guilabel">ImageMagick</span></code> (required for the <a class="indexterm" name="idp140623091218680" id="idp140623091218680"></a>photo-album packages,</td></tr><tr><td>uncheck<code class="computeroutput"><span class="guilabel">isdn4k-utils</span></code> (unless you are using isdn,
this installs a useless daemon),</td></tr><tr><td>check <code class="computeroutput"><span class="guilabel">mutt</span></code> (a mail program that reads
Maildir),</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">nfs-utils</span></code> (nfs is a major security
risk),</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">pam-devel</span></code> (I don&#39;t remember why, but
we don&#39;t want this),</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">portmap</span></code>,</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">postfix</span></code> (this is an MTA, but we&#39;re
going to install qmail later),</td></tr><tr><td>check <code class="computeroutput"><span class="guilabel">postgresql-devel</span></code>,</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">rsh</span></code> (rsh is a security hole),</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">sendmail</span></code> (sendmail is an insecure MTA;
we&#39;re going to install qmail instead later),</td></tr><tr><td>check <code class="computeroutput"><span class="guilabel">tcl</span></code> (we need tcl), and</td></tr><tr><td>uncheck <code class="computeroutput"><span class="guilabel">xinetd</span></code> (xinetd handles incoming tcp
connections. We&#39;ll install a different, more secure program,
ucspi-tcp).</td></tr><tr><td>Click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>
</td></tr>
</table>
</li><li class="listitem"><p>Red Hat isn&#39;t completely happy with the combination of
packages we&#39;ve selected, and wants to satisfy some
dependencies. Don&#39;t let it. On the next screen, choose
<code class="computeroutput"><span class="guilabel">I<span class="accel">g</span>nore Package Dependencies</span></code> and click
<code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>.</p></li><li class="listitem"><p>Click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code> to start
the copying of files.</p></li><li class="listitem"><p>Wait. Insert Disk 2 when asked.</p></li><li class="listitem"><p>Wait. Insert Disk 3 when asked.</p></li><li class="listitem"><p>If you know how to use it, create a boot disk. Since you can
also boot into recovery mode with the Install CDs, this is less
useful than it used to be, and we won&#39;t bother. Select
<code class="computeroutput"><span class="guilabel">No,I
<span class="accel">d</span>o not want to create a boot
disk</span></code> and click <code class="computeroutput"><span class="guibutton">
<span class="accel">N</span>ext</span></code>.</p></li><li class="listitem"><p>Click <code class="computeroutput"><span class="guilabel">
<span class="accel">E</span>xit</span></code>, remove
the CD, and watch the computer reboot.</p></li><li class="listitem">
<p>After it finishes rebooting and shows the login prompt, log
in:</p><pre class="screen">
yourserver login: <strong class="userinput"><code>root</code></strong>
Password:
[root root]#
</pre>
</li><li class="listitem"><p>Install any security patches. For example, insert your CD with
patches, mount it with <code class="computeroutput">mount
/dev/cdrom</code>, then <code class="computeroutput">cd
/mnt/cdrom</code>, then <code class="computeroutput">rpm -UVH
*rpm</code>. Both Red Hat 8.0 and 9.0 have had both kernel and
openssl/openssh root exploits, so you should be upgrading all of
that. Since you are upgrading the kernel, reboot after this
step.</p></li><li class="listitem">
<p>Lock down SSH</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>
<a class="indexterm" name="idp140623091405192" id="idp140623091405192"></a> SSH is the protocol we use to connect
securely to the computer (replacing telnet, which is insecure).
sshd is the daemon that listens for incoming ssh connections. As a
security precaution, we are now going to tell ssh not to allow
anyone to connect directly to this computer as root. Type this into
the shell:</p><pre class="screen"><strong class="userinput"><code>emacs /etc/ssh/sshd_config</code></strong></pre>
</li><li class="listitem"><p>Search for the word "root" by typing <strong class="userinput"><code>C-s</code></strong> (that&#39;s emacs-speak for
control-s) and then <strong class="userinput"><code>root</code></strong>.</p></li><li class="listitem">
<p>Make the following changes:</p><table border="0" summary="Simple list" class="simplelist">
<tr><td>
<code class="computeroutput">#Protocol 2,1</code> to
<code class="computeroutput">Protocol 2</code> (this prevents any
connections via SSH 1, which is insecure)</td></tr><tr><td>
<code class="computeroutput">#PermitRootLogin yes</code> to
<code class="computeroutput">PermitRootLogin no</code> (this
prevents the root user from logging in remotely via ssh. If you do
this, be sure to create a remote access account, such as
"remadmin", which you can use to get ssh before using
"su" to become root)</td></tr><tr><td>
<code class="computeroutput">#PermitEmptyPasswords no</code> to
<code class="computeroutput">PermitEmptyPasswords no</code> (this
blocks passwordless accounts) and save and exit by typing
<strong class="userinput"><code>C-x C-s C-x
C-c</code></strong>
</td></tr>
</table>
</li><li class="listitem">
<p>Restart sshd so that the change takes effect.</p><pre class="screen"><strong class="userinput"><code>service sshd restart</code></strong></pre>
</li>
</ol></div>
</li><li class="listitem">
<p>Red Hat still installed a few services we don&#39;t need, and
which can be security holes. Use the service command to turn them
off, and then use chkconfig to automatically edit the System V init
directories to permanently (The System V init directories are the
ones in /etc/rc.d. They consist of a bunch of scripts for starting
and stopping programs, and directories of symlinks for each system
level indicating which services should be up and down at any given
service level. We&#39;ll use this system for PostgreSQL, but
we&#39;ll use daemontools to perform a similar function for
AOLserver. (The reason for this discrepencies is that, while
daemontools is better, it&#39;s a pain in the ass to deal with and
nobody&#39;s had any trouble leaving PostgreSQL the way it is.)</p><pre class="screen">
[root root]# <strong class="userinput"><code>service pcmcia stop</code></strong>
[root root]# <strong class="userinput"><code>service netfs stop</code></strong>
[root root]# <strong class="userinput"><code>chkconfig --del pcmcia</code></strong>
[root root]# <strong class="userinput"><code>chkconfig --del netfs</code></strong>
[root root]#
<span class="action">service pcmcia stop
service netfs stop
chkconfig --del pcmcia
chkconfig --del netfs</span>
</pre><p>If you installed PostgreSQL, do also <code class="computeroutput">service postgresql start</code> and <code class="computeroutput">chkconfig --add postgresql</code>.</p>
</li><li class="listitem"><p>Plug in the network cable.</p></li><li class="listitem">
<p>Verify that you have connectivity by going to another computer
and ssh&#39;ing to <em class="replaceable"><code>yourserver</code></em>, logging in as remadmin,
and promoting yourself to root:</p><pre class="screen">
[joeuser\@someotherserver]$ <strong class="userinput"><code> ssh <em class="replaceable"><code>remadmin\@yourserver.test</code></em>
</code></strong>
The authenticity of host 'yourserver.test (1.2.3.4)' can&#39;t be established.
DSA key fingerprint is 10:b9:b6:10:79:46:14:c8:2d:65:ae:c1:61:4b:a5:a5.
Are you sure you want to continue connecting (yes/no)? <strong class="userinput"><code>yes</code></strong>
Warning: Permanently added 'yourserver.test (1.2.3.4)' (DSA) to the list of known hosts.
Password:
Last login: Mon Mar  3 21:15:27 2003 from host-12-01.dsl-sea.seanet.com
[remadmin remadmin]$ <strong class="userinput"><code>su -</code></strong>
Password: 
[root root]#
</pre>
</li><li class="listitem">
<p>If you didn&#39;t burn a CD of patches and use it, can still
download and install the necessary patches. Here&#39;s how to do it
for the kernel; you should also check for other critical
packages.</p><p>Upgrade the kernel to fix a security hole. The default Red Hat
8.0 system kernel (2.4.18-14, which you can check with
<strong class="userinput"><code>uname -a</code></strong>) has
several <a class="ulink" href="https://rhn.redhat.com/errata/RHSA-2003-098.html" target="_top">security problems</a>. Download the new kernel, install it,
and reboot.</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /var/tmp</code></strong>
[root tmp]# <strong class="userinput"><code>wget http://updates.redhat.com/7.1/en/os/i686/kernel-2.4.18-27.7.x.i686.rpm</code></strong>
--20:39:00--  http://updates.redhat.com/7.1/en/os/i686/kernel-2.4.18-27.7.x.i686.rpm
           =&gt; `kernel-2.4.18-27.7.x.i686.rpm'
Resolving updates.redhat.com... done.
Connecting to updates.redhat.com[66.187.232.52]:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 12,736,430 [application/x-rpm]

100%[======================================&gt;] 12,736,430    78.38K/s    ETA 00:00

20:41:39 (78.38 KB/s) - `kernel-2.4.18-27.7.x.i686.rpm' saved [12736430/12736430]

root\@yourserver tmp]# <strong class="userinput"><code>rpm -Uvh kernel-2.4.18-27.7.x.i686.rpm</code></strong>
warning: kernel-2.4.18-27.7.x.i686.rpm: V3 DSA signature: NOKEY, key ID db42a60e
Preparing...                ########################################### [100%]
   1:kernel                 ########################################### [100%]
[root tmp]# <strong class="userinput"><code>reboot</code></strong>

Broadcast message from root (pts/0) (Sat May  3 20:46:39 2003):

The system is going down for reboot NOW!
[root tmp]#
<span class="action">cd /var/tmp
wget http://updates.redhat.com/7.1/en/os/i686/kernel-2.4.18-27.7.x.i686.rpm
rpm -Uvh kernel-2.4.18-27.7.x.i686.rpm
reboot</span>
</pre>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="backups-with-cvs" leftLabel="Prev" leftTitle="Using CVS for backup-recovery"
		    rightLink="install-more-software" rightLabel="Next" rightTitle="
Appendix B. Install additional supporting
software"
		    homeLink="index" homeLabel="Home" 
		    upLink="acs-admin" upLabel="Up"> 
		