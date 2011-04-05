<!---
	NOTICE
	Name         : factory.cfc
	Author       : Corey Butler
	Created      : May 2, 2009
	Last Updated :
	History      :
	Purpose		 : Provides CF the basic methods and properties of a Bugzilla instance.
--->
<cfcomponent hint="Provides base methods and properties of the Bugzilla installation." output="false">

	<cfproperty name="server" hint="The core URL of the Bugzilla installation." type="string" />
	<cfproperty name="port" hint="The port on which Bugzilla is running." default="80" type="string" />
	<cfproperty name="adminuser" hint="The administrative account with permission to add users and query all products." type="string" />
	<cfproperty name="dsn" hint="The DSN used to connect to the Bugzilla DB." type="string" />
	<cfproperty name="pfx" hint="The prefix of the Bugzilla DB schema and/or table name." type="string" />
	<cfproperty name="key" hint="A key used for obfuscating the password." type="string" />
	<cfproperty name="adminpassword" hint="The obfuscated password of the account used to login." type="string" />
	<cfproperty name="default" hint="A struct containing 6 default values (keys): priority, platform, OS, status, assignedTo, and estimatedTime." type="string" />
	<cfproperty name="url" hint="A struct containing the URL values of each Bugzilla form handler." type="string" />
	<cfproperty name="product" hint="A struct containing the product ID's associated with this Bugzilla instance. Each ID is a key containing a sub-struct. The sub-struct keys include name and closed. Closed is a true/false value representing whether or not the product is open for new bug submission." type="string" />
	<cfproperty name="options" hint="A struct containing arrays with system options." type="string" />

	<cffunction name="init" hint="Initialize the factory as though it's being used by a specific user." access="public" output="false" returntype="void">
		<cfargument name="ini" hint="The absolute path of the ini file." required="true" type="string"/>
		<cfargument name="section" hint="The section of the ini file to use for this initialization." required="false" default="default" type="string"/>
		<cfscript>
			var qry = "";
			tmp = StructNew();
		</cfscript>
		<cfif not FileExists(arguments.ini)>
			<cfthrow message="Cannot read ini file." detail="Cannot find or read #arguments.ini#."/>
		</cfif>
		<cfif not StructKeyExists(getProfileSections(arguments.ini),arguments.section)>
			<cfthrow message="Invalid ini section." detail="#arguments.section# could not be found in #arguments.ini#."/>
		</cfif>
		<cfscript>
			this.dsn = getProfileString(arguments.ini,arguments.section,"dsn");
			this.pfx = getProfileString(arguments.ini,arguments.section,"pfx");
			this.adminuser = trim(getProfileString(arguments.ini,arguments.section,"user"));
		</cfscript>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	*
			FROM	#this.pfx#profiles
			WHERE	login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#this.adminuser#"/>
		</cfquery>
		<cfif not qry.recordcount>
			<cfthrow message="Cannot initialize factory." detail="The user with email '#this.adminuser#' could not be found."/>
		</cfif>
		<cfscript>
			this.dsn = trim(getProfileString(arguments.ini,arguments.section,"dsn"));
			this.key = createuuid();
			this.adminpassword = encrypt(trim(getProfileString(arguments.ini,arguments.section,"password")),this.key);
			this.default.priority = trim(getProfileString(arguments.ini,arguments.section,"priority"));
			this.default.platform = trim(getProfileString(arguments.ini,arguments.section,"platform"));
			this.default.OS = trim(getProfileString(arguments.ini,arguments.section,"OS"));
			this.default.status = trim(getProfileString(arguments.ini,arguments.section,"status"));
			this.default.assignedTo = trim(getProfileString(arguments.ini,arguments.section,"assignment"));
			this.default.estimatedTime = "0.0";
			this.default.severity = trim(getProfileString(arguments.ini,arguments.section,"severity"));
			this.server = trim(getProfileString(arguments.ini,arguments.section,"server"));
			this.port = trim(getProfileString(arguments.ini,arguments.section,"port"));
			this.url.post = this.server & "/post_bug.cgi";
			this.url.vote = this.server & "/votes.cgi";
			this.url.user = this.server & "/editusers.cgi";
			this.product = getProducts();
			this.options.severity = ArrayNew(1);
			this.options.platform = ArrayNew(1);
			this.options.priority = ArrayNew(1);
			this.options.OS = ArrayNew(1);
			this.options.initialstate = ArrayNew(1);
		</cfscript>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	*
			FROM	#this.pfx#bug_severity
			WHERE	isactive = 1
			ORDER BY sortkey ASC
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				tmp = StructNew();
				tmp.name = trim(value);
				tmp.sortkey = sortkey;
				tmp.id = id;
				ArrayAppend(this.options.severity,tmp);
			</cfscript>
		</cfoutput>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	*
			FROM	#this.pfx#rep_platform
			WHERE	isactive = 1
			ORDER BY sortkey ASC
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				tmp = StructNew();
				tmp.id = id;
				tmp.name = trim(value);
				tmp.sortkey = sortkey;
				ArrayAppend(this.options.platform,tmp);
			</cfscript>
		</cfoutput>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	*
			FROM	#this.pfx#priority
			WHERE	isactive = 1
			ORDER BY sortkey ASC
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				tmp = StructNew();
				tmp.id = id;
				tmp.name = trim(value);
				tmp.sortkey = sortkey;
				ArrayAppend(this.options.priority,tmp);
			</cfscript>
		</cfoutput>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	*
			FROM	#this.pfx#op_sys
			WHERE	isactive = 1
			ORDER BY sortkey ASC
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				tmp = StructNew();
				tmp.id = id;
				tmp.name = trim(value);
				tmp.sortkey = sortkey;
				ArrayAppend(this.options.OS,tmp);
			</cfscript>
		</cfoutput>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	*
			FROM	#this.pfx#resolution
			WHERE	isactive = 1
			ORDER BY sortkey ASC
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				tmp = StructNew();
				tmp.id = id;
				tmp.name = trim(value);
				tmp.sortkey = sortkey;
				ArrayAppend(this.options.initialstate,tmp);
			</cfscript>
		</cfoutput>
		<cfreturn />
	</cffunction>

	<cffunction name="getProducts" access="private" returntype="struct" hint="Populates the product attribute." output="false">
		<cfset var tmp = StructNew()/>
		<cfset var tmp2 = StructNew()/>
		<cfset var qry = ""/>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	id, name, disallownew
			FROM	#this.pfx#products
			ORDER BY	name ASC
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				tmp = StructNew();
				tmp.name = trim(name);
				tmp.closed = (disallownew eq 1);
				StructInsert(tmp2,id,tmp);
			</cfscript>
		</cfoutput>
		<cfreturn tmp2/>
	</cffunction>

	<cffunction name="getBugzillaToken" access="package" returntype="string" hint="Returns a Bugzilla security token for the specified event/user. If no token exists, one is generated unless the noforce attribute is true.">
		<cfargument name="event" type="string" required="true" hint="The Bugzilla event for which a token is necessary."/>
		<cfargument name="user" type="string" required="false" hint="The user requiring a token. If none is specified, the admin user will be used."/>
		<cfargument name="type" type="string" required="false" default="session" hint="The type of session to be created."/>
		<cfargument name="noforce" type="boolean" required="false" default="false" hint="Setting this to true will NOT create a new token, even if one cannot be found. If no token is found and none are generated, the resulting value will be 'NONE'."/>
		<cfscript>
			var qry = "";
			var tok = "";
		</cfscript>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfscript>
			if (not StructKeyExists(arguments,"user"))
				arguments.user = this.adminuser;
			else if (not len(trim(arguments.user)))
				arguments.user = this.adminuser;
		</cfscript>
		<!--- Generate the appropriate token --->
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	token
			FROM 	#this.pfx#tokens
			WHERE	issuedate = (
						SELECT max(issuedate)
						FROM bugzilla.tokens
						WHERE userid = (SELECT userid FROM #this.pfx#profiles WHERE login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user#"/>)
							AND tokentype = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.type#"/>
							AND eventdata = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.event#"/>
							AND issuedate >= <cfqueryparam cfsqltype="cf_sql_date" value="#Dateformat(now(),'mm/dd/yyyy')#"/>
					)
		</cfquery>
		<cfif not qry.recordcount and not arguments.noforce>
			<cfset tok = left(replace(createuuid(),'-','','ALL'),10)/>
			<cfquery name="qry" datasource="#this.dsn#">
				INSERT INTO #this.pfx#tokens (userid,issuedate,token,tokentype,eventdata)
				VALUES (
					(SELECT userid FROM #this.pfx#profiles WHERE login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user#"/>),
					current_date,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#tok#"/>,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.type#"/>,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.event#"/>
				)
			</cfquery>
			<cfreturn tok/>
		<cfelseif qry.recordcount>
			<cfreturn qry.token/>
		<cfelse>
			<cfreturn 'NONE'/>
		</cfif>
	</cffunction>

	<cffunction name="removeBugzillaToken" access="public" output="false" returntype="void" hint="Removes a security token.">
		<cfargument name="token" type="string" required="true" hint="The token to be removed."/>
		<cfset var qry = ""/>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			DELETE FROM #this.pfx#tokens
			WHERE	token = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.token#"/>
		</cfquery>
	</cffunction>

	<cffunction name="removeAllUserBugzillaTokens" access="public" output="false" returntype="void" hint="Removes all security tokens for a particular user.">
		<cfargument name="user" type="string" required="true" hint="The user to clear."/>
		<cfset var qry = ""/>
		<cfset var qry1 = ""/>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfquery name="qry1" datasource="#this.dsn#">
			SELECT	userid
			FROM	#this.pfx#profiles
			WHERE	login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.user#"/>
		</cfquery>
		<cfif not qry1.recordcount>
			<cfthrow message="Could not find user." detail="The user '#arguments.user#' could not be found or does not exist."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			DELETE FROM #this.pfx#tokens
			WHERE	userid = '#qry1.userid[1]#'
		</cfquery>
	</cffunction>

	<cffunction name="userExists" access="public" output="false" returntype="boolean" hint="Indicates whether the specified user exists or not.">
		<cfargument name="email" required="true" type="string" hint="The email address of the user."/>
		<cfset var qry = ""/>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	userid
			FROM	#this.pfx#profiles
			WHERE	login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.email#"/>
		</cfquery>
		<cfreturn (qry.recordcount eq 1)/>
	</cffunction>

	<cffunction name="createUser" access="public" output="true" returntype="void" hint="Creates a new database user in Bugzilla. This does not support LDAP/Active Directory user creation.">
		<cfargument name="email" required="true" type="string" hint="The email address of the user. If using LDAP or Active Directory, make sure this is the same email account associated with the user's LDAP/AD account."/>
		<cfargument name="pwd" required="true" type="string" hint="A plain text password (will be auto-encrypted)."/>
		<cfargument name="nm" required="true" type="string" hint="The user's real name."/>
		<cfscript>
			var tok = getBugzillaToken('add_user',this.adminuser);
		</cfscript>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfhttp url="#this.url.user#" result="posted" method="post">
			<cfhttpparam type="formfield" name="Bugzilla_login" value="#this.adminuser#"/>
			<cfhttpparam type="formfield" name="Bugzilla_password" value="#decrypt(this.adminpassword,this.key)#"/>
			<cfhttpparam type="formfield" name="login" value="#trim(arguments.email)#"/>
			<cfhttpparam type="formfield" name="name" value="#trim(arguments.nm)#"/>
			<cfhttpparam type="formfield" name="password" value="#trim(arguments.pwd)#"/>
			<cfhttpparam type="formfield" name="disable_mail" value="0"/>
			<cfhttpparam type="formfield" name="disabledtext" value=""/>
			<cfhttpparam type="formfield" name="add" value="Add"/>
			<cfhttpparam type="formfield" name="action" value="new"/>
			<cfhttpparam type="formfield" name="token" value="#tok#"/>
			<cfhttpparam type="formfield" name="blocked" value="">
			<cfhttpparam type="formfield" name="bit-14" value="1"/>
			<cfhttpparam type="formfield" name="form_name" value="f"/>
		</cfhttp>
		<cfif not findnocase("user "&trim(arguments.email)&" created",posted.Filecontent)>
			<cfthrow message="Could not create new user." detail="#posted.Filecontent#"/>
		</cfif>
	</cffunction>

	<cffunction name="disableUser" access="public" hint="Disables a user." output="false">
		<cfargument name="user" required="true" type="string" hint="The email address of the user."/>
		<cfset var qry = ""/>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			DELETE	FROM 	#this.pfx#profiles
			WHERE 	login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.user)#"/>
		</cfquery>
	</cffunction>

	<cffunction name="addUserToGroup" access="public" output="false" returntype="void" hint="Adds the user to the specified group.">
		<cfargument name="user" required="true" type="string" hint="The email address of the user."/>
		<cfargument name="group" required="true" type="numeric" hint="The ID of the group to add the user to."/>
		<cfset var qry = ""/>
		<cfset var uid = ""/>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	userid
			FROM 	#this.pfx#profiles
			WHERE 	login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.user)#"/>
		</cfquery>
		<cfif not qry.recordcount>
			<cfreturn/>
		</cfif>
		<cfset uid = qry.userid[1]/>
		<cfquery name="qry" datasource="#this.dsn#">
			INSERT INTO #this.pfx#user_group_map (user_id,group_id,isbless,grant_type)
			VALUES (<cfqueryparam cfsqltype="cf_sql_numeric" value="#uid#"/>,
					<cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.group#"/>,
					0,
					0)
		</cfquery>
	</cffunction>

	<cffunction name="createBug" access="public" output="false" returntype="void" hint="Creates a new bug. If a bug with the same name, location, and version is submitted, the existing bug's vote count will be increased by one.">
		<cfargument name="user" required="true" type="string" hint="The email address of the user. If using LDAP or Active Directory, make sure this is the same email account associated with the user's LDAP/AD account."/>
		<cfargument name="pwd" required="true" type="string" hint="A plain text password (will be auto-encrypted)."/>
		<cfargument name="exception" required="true" type="any" hint="The issue to log. This can be any type of data, which will be dumped to the database. For robust error checking, provide a WDDX value."/>
		<cfargument name="name" required="true" type="string" hint="The descriptive name of the issue (summary)."/>
		<cfargument name="product" required="true" type="string" hint="The product is which the issue arose."/>
		<cfargument name="component" required="true" type="string" hint="The component of the product in which the issue arose."/>
		<cfargument name="version" required="false" default="1.0" type="string" hint="The version of the product in which the issue arose."/>
		<cfargument name="platform" required="false" type="string" hint="The platform on which the issue occurred."/>
		<cfargument name="os" required="false" type="string" hint="The Operating System on which the issue occurred."/>
		<cfargument name="priority" required="false" type="string" hint="The priority level of the issue."/>
		<cfargument name="severity" required="false" type="string" hint="The severity level of the issue."/>
		<cfargument name="status" required="false" type="string" hint="The status of the issue."/>
		<cfargument name="assignedTo" required="false" type="string" hint="Who the bug should be assigned to. To use the default assignee, leave this blank."/>
		<cfargument name="cc" default="" required="false" type="string" hint="Who should be cc'd on the issue."/>
		<cfargument name="estimatedTime" required="false" type="string" hint="The estimated time required to fix or review the issue."/>
		<cfargument name="location" required="false" default="" type="string" hint="The URL where the issue occurred."/>
		<cfargument name="deadline" required="false" default="" type="string" hint="The deadline for completing the fix/review."/>
		<cfargument name="keywords" required="false" default="" type="string" hint="A comma delimited list of keywords."/>
		<cfargument name="dependson" required="false" default="" type="string" hint="The ID of another issue on which this new issue is dependent."/>
		<cfargument name="forceNew" required="false" default="false" type="boolean" hint="Forces the creation of a new bug, even if the name, location, and version match an existing bug."/>
		<cfscript>
			var qs = "";
			var start = 0;
			var end = 0;
			var bug = 0;
			var qryCheck = "";
			var qry = "";
			var body = "";
			var tok = getBugzillaToken('add_user',arguments.user);

			if (not StructKeyExists(arguments,"os"))
				arguments.os = this.default.OS;
			if (not StructKeyExists(arguments,"priority"))
				arguments.priority = this.default.priority;
			if (not StructKeyExists(arguments,"status"))
				arguments.status = this.default.status;
			if (not StructKeyExists(arguments,"assignedTo"))
				arguments.assignedTo = this.default.assignedTo;
			if (not StructKeyExists(arguments,"estimatedTime"))
				arguments.estimatedTime = this.default.estimatedTime;
			if (not StructKeyExists(arguments,"platform"))
				arguments.platform = this.default.platform;
			if (not StructKeyExists(arguments,"severity"))
				arguments.severity = this.default.severity;
		</cfscript>
		<cfif not StructKeyExists(this,"dsn")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfif not isSimpleValue(arguments.exception)>
			<cfsavecontent variable="body"><cfdump var="#arguments.exception#"></cfsavecontent>
		<cfelse>
			<cfsavecontent variable="body"><cfoutput>#arguments.exception#</cfoutput></cfsavecontent>
		</cfif>
		<cfquery name="qryCheck" datasource="#this.dsn#" maxrows="1">
			SELECT 	bug_id, votes
			FROM	#this.pfx#bugs
			WHERE	short_desc = '#trim(body)#'
					AND bug_file_loc = '#trim(arguments.location)#'
					AND version = '#arguments.version#'
		</cfquery>
		<cfif not qryCheck.recordcount or arguments.forceNew>
			<cfif len(trim(arguments.dependson))>
				<!--- Check for dependencies --->
				<cfquery name="qry" datasource="#this.dsn#" maxrows="1">
					SELECT	count(bug_id) as ct
					FROM	#this.pfx#bugs
					WHERE	bug_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.dependson#"/>
				</cfquery>
				<cfif qry.ct lt 1>
					<cfthrow message="Invalid dependent bug." detail="The value specified for the dependson attribute (#arguments.dependson#) is not a valid issue or could not be found.">
				</cfif>
			</cfif>
			<cfhttp url="#this.url.post#" result="posted" method="post">
				<cfhttpparam type="formfield" name="Bugzilla_login" value="#arguments.user#">
				<cfhttpparam type="formfield" name="Bugzilla_password" value="#arguments.pwd#">
				<cfhttpparam type="formfield" name="product" value="#arguments.product#">
				<cfhttpparam type="formfield" name="component" value="#arguments.component#">
				<cfhttpparam type="formfield" name="version" value="#arguments.version#">
				<cfhttpparam type="formfield" name="bug_severity" value="#arguments.severity#">
				<cfhttpparam type="formfield" name="rep_platform" value="#arguments.platform#">
				<cfhttpparam type="formfield" name="op_sys" value="#arguments.os#">
				<cfhttpparam type="formfield" name="priority" value="#arguments.priority#">
				<cfhttpparam type="formfield" name="bug_status" value="#ucase(arguments.status)#">
				<cfhttpparam type="formfield" name="assigned_to" value="#arguments.assignedTo#">
				<cfhttpparam type="formfield" name="cc" value="#arguments.cc#">
				<!--- <cfhttpparam type="formfield" name="token" value="#tok#"/> --->
				<cfhttpparam type="formfield" name="estimated_time" value="#arguments.estimatedTime#">
				<cfhttpparam type="formfield" name="deadline" value="#arguments.deadline#">
				<cfhttpparam type="formfield" name="bug_file_loc" value="#arguments.location#">
				<cfhttpparam type="formfield" name="short_desc" value="#trim(arguments.name)#">
				<cfhttpparam type="formfield" name="comment" value="#body#">
				<cfhttpparam type="formfield" name="keywords" value="#arguments.keywords#">
				<cfhttpparam type="formfield" name="dependson" value="#arguments.dependson#">
				<cfhttpparam type="formfield" name="blocked" value="">
				<cfhttpparam type="formfield" name="bit-14" value="1">
				<cfhttpparam type="formfield" name="form_name" value="enter_bug">
			</cfhttp>
			<cfif not findnocase("added to the database",posted.Filecontent)>
				<cfwddx action="cfml2wddx" input="#posted#" output="x"/>
				<cfthrow message="Error logging issue." detail="#x#"/>
			</cfif>
		<cfelseif qryCheck.votes lt application.error.maxvotes>
			<cfhttp url="#this.url.vote#" result="posted" method="post">
				<cfhttpparam type="formfield" name="Bugzilla_login" value="#decrypt(arguments.user,this.key)#">
				<cfhttpparam type="formfield" name="Bugzilla_password" value="#decrypt(arguments.password,this.key)#">
				<cfhttpparam type="formfield" name="#qryCheck.bug_id#" value="#abs(qryCheck.votes+1)#">
				<cfhttpparam type="formfield" name="action" value="vote">
				<cfhttpparam type="formfield" name="form_name" value="voting_form">
			</cfhttp>
			<cfset bug = qryCheck.bug_id>
		</cfif>
	</cffunction>

	<cffunction name="bugExists" access="public" hint="Given a Bug ID, determines whether it exists or not." output="false" returntype="boolean">
		<cfargument name="id" type="numeric" required="true" hint="The ID of the bug."/>
		<cfset var qry = ""/>
		<cfif not StructKeyExists(this,"dsn")>
			<cfthrow message="Not initialized" detail="The Bugzilla factory is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#" maxrows="1">
			SELECT	bug_id
			FROM	#this.pfx#bugs
			WHERE	bug_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#"/>
		</cfquery>
		<cfreturn (qry.recordcount gt 0)/>
	</cffunction>

</cfcomponent>