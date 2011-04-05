<!---
	NOTICE
	Name         : bug.cfc
	Author       : Corey Butler
	Created      : May 2, 2009
	Last Updated :
	History      :
	Purpose		 : Extends the Bugzilla factory object to represent a specific bug.
--->
<cfcomponent hint="Represents a specific bug." extends="com.utility.bugzilla.factory" output="false">

	<cfproperty name="id" type="numeric" />
	<cfproperty name="assignedToID" hint="The ID of who the bug is assigned to." type="string" />
	<cfproperty name="assignedTo" hint="Who the bug is assigned to." type="string" />
	<cfproperty name="location" hint="A URL where the bug was found." type="string" />
	<cfproperty name="severity" hint="The severity rating of the bug." type="string" />
	<cfproperty name="status" hint="The current status of the bug." type="string" />
	<cfproperty name="createDate" hint="The date when the bug is created." type="date" />
	<cfproperty name="changeDate" hint="The last date the bug was modified." type="date" />
	<cfproperty name="summary" hint="The descriptive summary of the bug." type="string" />
	<cfproperty name="OS" hint="Operating System" type="string" />
	<cfproperty name="priority" hint="Priority of the fix." type="string" />
	<cfproperty name="productID" hint="The product which the bug is associated with." type="numeric" />
	<cfproperty name="platform" hint="The platform upon which the issue was found." type="string" />
	<cfproperty name="reporter" hint="Who reported the issue." type="string" />
	<cfproperty name="reporterID" hint="The reporter ID" type="numeric" />
	<cfproperty name="reporterEmail" hint="The reporter email address." type="string" />
	<cfproperty name="version" hint="The version of the product/component." type="string" />
	<cfproperty name="componentID" hint="The component ID with the bug." type="numeric" />
	<cfproperty name="component" hint="The component name with the bug." type="string" />
	<cfproperty name="resolution" hint="The fix/answer." type="string" />
	<cfproperty name="targetMilestone" hint="The target milestone for fix/issue." type="string" />
	<cfproperty name="qa" hint="The Quality Assurance contact." type="string" />
	<cfproperty name="whiteboard" hint="Whiteboard status." type="string" />
	<cfproperty name="votes" hint="The total number of votes for this issue." type="numeric" />
	<cfproperty name="keywords" hint="A list of keywords associated with the bug." type="string" />
	<cfproperty name="lastdiffed" hint="The last time the bug was checked for differences" type="date" />
	<cfproperty name="everconfirmed" hint="Identifies whether the bug was ever confirmed." type="boolean" />
	<cfproperty name="reporterAccessible" hint="Whether the reporter is accessible or not." type="boolean" />
	<cfproperty name="cclistAccessible" hint="Whether the CC list is accessible or not." type="boolean" />
	<cfproperty name="estimatedTime" hint="The estimated time to resolution." type="numeric" />
	<cfproperty name="remainingTime" hint="The time remaining to resolution." type="numeric" />
	<cfproperty name="deadline" hint="The deadline for resolution." type="date" />
	<cfproperty name="alias" hint="An alias used to identify the bug." type="string" />
	<cfproperty name="description" hint="All of the descriptions/comments associated with the bug. Each element of the array is a struct with the following keys: ID, author, authorID, authorEmail, created, comment, private." type="array" />
	<cfproperty name="cc" hint="An array of email addresses notified when the bug changes." type="array" />

	<cffunction name="init" hint="Initialize the bug object." access="public" output="false" returntype="void">
		<cfargument name="ini" hint="The absolute path of the ini file for the Bugzilla installation." required="true" type="string"/>
		<cfargument name="section" hint="The section of the ini file to use for this initialization." required="false" default="default" type="string"/>
		<cfargument name="id" type="numeric" hint="The bug ID. This is a numeric value stored in the DB." required="false" />
		<cfscript>
			var i = 0;
			var a = ArrayNew(1);
			super.init(arguments.ini,arguments.section);
			StructDelete(this,"product");
			this.id = arguments.id;
			reinit();
		</cfscript>
		<cfreturn />
	</cffunction>

	<cffunction name="reinit" hint="Populates the primary attributes of the object." access="public" returntype="void">
		<cfscript>
			var qry = "";
			var span = createTimeSpan(0,0,5,0);
			var tmp = StructNew();

			if (StructKeyExists(url,"restart"))
				span = createTimeSpan(0,0,0,0);
		</cfscript>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The bug object is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#" cachedwithin="#span#">
			SELECT	b.version,b.bug_status,b.bug_id,b. assigned_to,b.bug_file_loc,b.bug_severity,b.creation_ts,b.
					delta_ts,b.short_desc,b.op_sys,b.priority,b.rep_platform,b.reporter,b.version,b.component_id,b.resolution,b.
					target_milestone,b.qa_contact,b.status_whiteboard,b.votes,b.keywords,b.lastdiffed,b.everconfirmed,b.
					reporter_accessible,b.cclist_accessible,b.estimated_time,b.remaining_time,b.deadline,b.alias,b.product_id,c.name,
					r.realname,r.login_name
			FROM	(#this.pfx#bugs b JOIN #this.pfx#components c ON c.id = b.component_id)
					JOIN #this.pfx#profiles r ON b.reporter = r.userid
			WHERE	b.bug_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#this.id#"/>
			GROUP BY b.version,b.bug_status,b.bug_id,b. assigned_to,b.bug_file_loc,b.bug_severity,b.creation_ts,b.
					delta_ts,b.short_desc,b.op_sys,b.priority,b.rep_platform,b.reporter,b.version,b.component_id,b.resolution,b.
					target_milestone,b.qa_contact,b.status_whiteboard,b.votes,b.keywords,b.lastdiffed,b.everconfirmed,b.
					reporter_accessible,b.cclist_accessible,b.estimated_time,b.remaining_time,b.deadline,b.alias,b.product_id,c.name,
					r.realname,r.login_name
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				this.id = this.id;
				this.assignedToID = this.id;
				this.assignedTo = "Unassigned";
				this.location = trim(bug_file_loc);
				this.severity = trim(bug_severity);
				this.status = trim(bug_status);
				this.createDate = DateFormat(creation_ts,"mm/dd/yyyy");
				this.changeDate = DateFormat(delta_ts,"mm/dd/yyyy");
				this.summary = trim(short_desc);
				this.OS = trim(op_sys);
				this.priority = trim(priority);
				this.productID = trim(product_id);
				this.platform = trim(rep_platform);
				this.reporterAccessible = (reporter_accessible eq 1);
				this.version = trim(version);
				this.componentID = component_id;
				this.component = trim(name);
				this.resolution = trim(resolution);
				this.targetMilestone = trim(target_milestone);
				this.qa = trim(qa_contact);
				this.whiteboard = trim(status_whiteboard);
				this.votes = votes;
				this.keywords = trim(keywords);
				this.lastdiffed = DateFormat(lastdiffed,"mm/dd/yyyy");
				this.everconfirmed = (everconfirmed eq 1);
				this.reporterAccessible = (reporter_accessible eq 1);
				this.cclistAccessible = (cclist_accessible eq 1);
				this.cc = ArrayNew(1);
				this.estimatedTime = trim(estimated_time);
				this.remainingTime = trim(remaining_time);
				this.deadline = DateFormat(deadline,"mm/dd/yyyy");
				this.alias = trim(alias);
				this.reporterID = reporter;
				this.reporterEmail = trim(login_name);
				this.reporter = trim(realname);
				this.description = ArrayNew(1);
			</cfscript>
		</cfoutput>
		<cfquery name="qry" datasource="#this.dsn#" maxrows="1">
			SELECT	login_name
			FROM	#this.pfx#profiles
			WHERE	userid = <cfqueryparam cfsqltype="cf_sql_numeric" value="#this.assignedToID#"/>
		</cfquery>
		<cfif qry.recordcount><cfset this.assignedTo = trim(qry.login_name[1])></cfif>
		<cfif this.cclistAccessible>
			<cfset this.cc = ArrayNew(1)/>
			<cfquery name="qry" datasource="#this.dsn#">
				SELECT	p.login_name
				FROM	#this.pfx#cc JOIN #this.pfx#profiles p ON cc.who = p.userid
				WHERE	bug_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#this.id#"/>
				ORDER BY p.login_name
			</cfquery>
			<cfoutput query="qry">
				<cfscript>
					ArrayAppend(this.cc,trim(login_name));
				</cfscript>
			</cfoutput>
		</cfif>
		<cfscript>
			updateComments();
		</cfscript>
	</cffunction>

	<cffunction name="updateComments" access="private" output="false" returntype="void" hint="Updates the description attribute of the object.">
		<cfset this.description = ArrayNew(1)/>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	l.comment_id, l.bug_when, l.who, l.thetext, l.isprivate, p.realname, p.login_name
			FROM	#this.pfx#longdescs l LEFT JOIN #this.pfx#profiles p ON l.who = p.userid
			WHERE	bug_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#this.id#"/>
			ORDER BY l.comment_id
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				tmp = StructNew();
				tmp.ID = comment_id;
				tmp.author = trim(realname);
				tmp.authorID = who;
				tmp.authorEmail = trim(login_name);
				tmp.created = DateFormat(bug_when,"mm/dd/yyyy") & " " & TimeFormat(bug_when,"hh:mm:ss tt") & " CST";
				tmp.comment = trim(thetext);
				tmp.private = (isprivate eq 1);
				ArrayAppend(this.description,tmp);
			</cfscript>
		</cfoutput>
	</cffunction>

	<cffunction name="addComment" access="public" returntype="void" output="false" hint="Add a comment to the bug.">
		<cfargument name="author" type="string" required="true" hint="The email address of the author."/>
		<cfargument name="comment" type="string" required="true" hint="The comment text."/>
		<cfscript>
			var qry = "";
		</cfscript>
		<cfif not StructKeyExists(this,"id")>
			<cfthrow message="Not initialized" detail="The bug is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			INSERT INTO #this.pfx#longdescs (bug_id,who,bug_when,thetext)
			VALUES (<cfqueryparam cfsqltype="cf_sql_numeric" value="#this.id#"/>,
					(SELECT	userid FROM #this.pfx#profiles WHERE login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.author)#"/>),
					<cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.comment)#"/>)
		</cfquery>
		<cfscript>
			updateComments();
		</cfscript>
	</cffunction>

	<cffunction name="addCCUser" access="public" returntype="void" output="false" hint="Add a user to the CC list for this issue.">
		<cfargument name="user" type="string" required="true" hint="The email address of the user."/>
		<cfscript>
			var qry = "";
		</cfscript>
		<cfif not StructKeyExists(this,"id")>
			<cfthrow message="Not initialized" detail="The bug is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT 	*
			FROM	#this.pfx#cc
			WHERE	bug_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#this.id#"/>
					AND who = (	SELECT	userid
								FROM 	#this.pfx#profiles
								WHERE 	login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.user)#"/>)
		</cfquery>
		<cfif qry.recordcount>
			<!--- Exit if user is already on list --->
			<cfreturn/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			INSERT INTO #this.pfx#cc (bug_id,who)
			VALUES (<cfqueryparam cfsqltype="cf_sql_numeric" value="#this.id#"/>,
					(SELECT	userid FROM #this.pfx#profiles WHERE login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.user)#"/>))
		</cfquery>
		<cfscript>
			ArrayAppend(this.cc,trim(arguments.user));
		</cfscript>
	</cffunction>

	<cffunction name="removeCCUser" access="public" returntype="void" output="false" hint="Remove a user from the CC list for this issue.">
		<cfargument name="user" type="string" required="true" hint="The email address of the user."/>
		<cfscript>
			var qry = "";
			var i = 0;
		</cfscript>
		<cfif not StructKeyExists(this,"id")>
			<cfthrow message="Not initialized" detail="The bug is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#">
			DELETE FROM	#this.pfx#cc
			WHERE	bug_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#this.id#"/>
					AND who = (	SELECT	userid
								FROM 	#this.pfx#profiles
								WHERE 	login_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.user)#"/>)
		</cfquery>
		<cfscript>
			for (i=1; i lte arraylen(this.cc); i=i+1) {
				if (this.cc[i] is trim(arguments.user)) {
					ArrayDeleteAt(this.cc,i);
					break;
				}
			}
		</cfscript>
	</cffunction>

</cfcomponent>