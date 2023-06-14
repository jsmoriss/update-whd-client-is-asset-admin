<h1>update-users-whd-asset-admin</h1>

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
</ul>
</li>
</ul>

<p>WHD requires a valid tech username for their API queries - any active tech username will do. :)</p>

<h2 class="wp-block-heading">Jamf Policy Log Details</h2>

<p>The log details will show the script argument values (the API key is hidden) along with a message of each action taken.</p>

<p>For example:</p>

<blockquote class="wp-block-quote wide">
<p>
mount_point = /<br/>
computer_name = ASSET123<br/>
user_name = jdoe<br/>whd_server =<br>
whd_api_user =<br>
whd_api_key = ********<br/>
macos_version = x.x.x<br/><br/>
user jdoe is already admin of ASSET123 (FVFYJ3ACJK80).
</p>
</blockquote>
