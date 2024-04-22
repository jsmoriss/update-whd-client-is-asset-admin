<h1>update-whd-client-is-asset-admin.pl</h1>

<h2>Jamf Policy Script to Make WHD Asset Clients Admin on Login</h2>

<p>If you use <a href="https://www.jamf.com/products/jamf-pro/">Jamf Pro</a> and <a href="https://www.solarwinds.com/web-help-desk">SolarWinds Web Help Desk</a> (WHD), you may be interested in using this Jamf policy script to <strong>make WHD asset clients admin of their own assets on login</strong>.</p>

<h2 class="wp-block-heading"><strong>Jamf and WHD Requirements</strong></h2>

<ul>
<li>Assets in WHD must have accurate serial numbers entered. The script uses the computer serial number to locate the asset in WHD, so WHD assets must have serial numbers.</li>
<li>Assets in WHD must have one or more clients assigned to them. Clients assigned to the asset will be added to the 'admin' group for that asset on login.</li>
<li>The Perl script uses the JSON module, which Apple included in MacOS v11. If the computer uses an older MacOS version, the script will exit with an error. The script uses a <code>BEGIN{}</code> section to handle importing the JSON <code>decode_json()</code> function and exit gracefully if the JSON module is missing.</li>
</ul>

<h2 class="wp-block-heading"><strong>Jamf Script Arguments</strong></h2>

<p>When adding the script to Jamf, you'll want to add these parameter labels:</p>

<ul>
<li><strong>Parameter 4:</strong> WHD hostname?</li>
<li><strong>Parameter 5:</strong> WHD API username?</li>
<li><strong>Parameter 6:</strong> WHD API key?</li>
<li><strong>Parameter 7:</strong> Always admin usernames (optional)?</li>
<li><strong>Parameter 8:</strong> Fix extra admin users (default is false)?</li>
</ul>

<h2 class="wp-block-heading"><strong>Jamf Policy</strong></h2>

<ul>
<li><strong>Trigger:</strong> Login</li>
<li><strong>Execution Frequency:</strong> Ongoing</li>
<li><strong>Parameter Values:</strong>
<ul>
<li><strong>Parameter 4:</strong> WHD hostname? <em><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-cyan-bluish-gray-color">example: helpdesk.mycompany.com</mark></em></li>
<li><strong>Parameter 5:</strong> WHD API username? <em><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-cyan-bluish-gray-color">example: jsmith</mark></em></li>
<li><strong>Parameter 6:</strong> WHD API key? <em><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-cyan-bluish-gray-color">example: yfi65OHG5hgu75IOgjhkdhte87JHGjhhjgjhgGJHG</mark></em></li>
<li><strong>Parameter 7:</strong> Always admin usernames (optional)? <em><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-cyan-bluish-gray-color">example: sysadmin support</mark></em></li>
<li><strong>Parameter 8:</strong> Fix extra admin users (default is false)? <em><mark style="background-color:rgba(0, 0, 0, 0)" class="has-inline-color has-cyan-bluish-gray-color">example: true</mark></em></li>
</ul>
</li>
</ul>

<p>WHD requires a valid tech username for their API queries - any active tech username will do. :)</p>

<p>Note that parameter 8 is false by default. If parameter 8 is true, if the user is already part of the admin group and not a client of the asset in WHD, the user is removed from the admin group. Keeping this parameter false avoids two extra validation queries to the WHD database (ie. if the user is already admin, then do nothing).</p>

<h2 class="wp-block-heading">Jamf Policy Log Details</h2>

<p>The log details will show the script argument values (the API key is hidden) along with a message of each action taken.</p>

<p>For example:</p>

<pre><code>
mount_point = /
computer_name = COMPNAME
user_name = jdoe
whd_server = helpdesk.mycompany.com
whd_api_user = jsmith
whd_api_key = ********
admin_users = sysadmin support
fix_extra_admin = true
macos_version = x.x.x

retrieved asset id 123 tag ASSETTAG serial number FVFYJ3ACJK80.
retrieved client id 456 user name jdoe.
user jdoe is already admin of COMPNAME (FVFYJ3ACJK80).
</code></pre>
