<!---
	NOTICE
	Name         : product.cfc
	Author       : Corey Butler
	Created      : May 2, 2009
	Last Updated :
	History      :
	Purpose		 : Extends the Bugzilla factory object to represent a specific product.
--->
<cfcomponent hint="Represents a Bugzilla product." extends="com.utility.bugzilla.factory" output="false">

	<cfproperty name="name" hint="The name of the product" type="string" />
	<cfproperty name="id" hint="The DB ID of the product" type="numeric" />
	<cfproperty name="classification" hint="The bug classification." type="string" />
	<cfproperty name="classificationID" hint="The numeric ID of the bug classification." type="numeric" />
	<cfproperty name="description" hint="A description of the product." type="string" />
	<cfproperty name="milestoneurl" hint="A URL pointing to a specific product milestone." type="string" />
	<cfproperty name="closed" hint="Idnicates that the product is closed for issue tracking." type="boolean" default="false" />
	<cfproperty name="votesperbug" hint="The maximum number of votes per user per bug." type="numeric" />
	<cfproperty name="maxvotesperuser" hint="The maximum number of votes a single user can cast for this product." type="numeric" />
	<cfproperty name="votestoconfirm" hint="The minimum number of votes required to auto-confirm a bug in the product." type="numeric" />
	<cfproperty name="defaultmilestone" hint="The default mileston when none is specified" type="string" default="---" />
	<cfproperty name="component" hint="An struct representing a component of the product." type="struct" />
	<cfproperty name="version" hint="The current version of the product." type="string" />
	<cfproperty name="versions" hint="A structure object containing all of the product versions. Each key of the struct is the ID of a version. Each key contains a version." type="struct" />

	<cffunction name="init" hint="Initialize the Bugzilla product object." access="public" output="false" returntype="void">
		<cfargument name="ini" hint="The absolute path of the ini file for the Bugzilla installation." required="true" type="string"/>
		<cfargument name="section" hint="The section of the ini file to use for this initialization." required="false" default="default" type="string"/>
		<cfargument name="id" type="numeric" hint="The product ID. This is a numeric value stored in the DB." required="false" />
		<cfscript>
			var i = 0;
			var a = ArrayNew(1);
			super.init(arguments.ini,arguments.section);
			StructDelete(this,"product");
			reinit(arguments.id);
		</cfscript>
		<cfreturn />
	</cffunction>

	<cffunction name="reinit" hint="Populates the object properties." access="public" output="false" returntype="void">
		<cfargument name="id" type="numeric" hint="The product ID. This is a numeric value stored in the DB." required="false" />
		<cfset var qry = ""/>
		<cfset var tmp = StructNew()/>
		<cfquery name="qry" datasource="#this.dsn#" maxrows="1">
			SELECT	p.*, c.name as classification
			FROM	#this.pfx#products p LEFT JOIN #this.pfx#classifications c ON p.classification_id = c.id
			WHERE	p.id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#"/>
		</cfquery>
		<cfif not qry.recordcount>
			<cfthrow message="Cannot find product or it does not exist." detail="Product #arguments.id# could not be found."/>
		</cfif>
		<cfscript>
			this.id = arguments.id;
			this.name = qry.name[1];
			this.classificationID = qry.classification_id[1];
			this.classification = qry.classification[1];
			this.description = trim(qry.description[1]);
			this.milestoneurl = qry.milestoneurl[1];
			this.closed = (qry.disallownew[1] eq 1);
			this.votesperuser = qry.votesperuser[1];
			this.maxvotesperbug = qry.maxvotesperbug[1];
			this.votestoconfirm = qry.votestoconfirm[1];
			this.defaultmilestone = qry.defaultmilestone[1];
			this.component = StructNew();
			this.version = StructNew();
			this.group = ArrayNew(1);
		</cfscript>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	*
			FROM	#this.pfx#versions
			WHERE	product_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#"/>
			ORDER BY product_id DESC
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				StructInsert(this.version,id,trim(value));
			</cfscript>
		</cfoutput>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	*
			FROM	#this.pfx#components
			WHERE	product_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#"/>
			ORDER BY name ASC
		</cfquery>
		<cfoutput query="qry">
			<cfscript>
				tmp = StructNew();
				tmp.name = trim(name);
				tmp.initialowner = initialowner;
				tmp.initialqacontact = trim(initialqacontact);
				tmp.description = trim(description);
				StructInsert(this.component,qry.id,tmp);
			</cfscript>
		</cfoutput>
		<cfquery name="qry" datasource="#this.dsn#">
			SELECT	group_id
			FROM	#this.pfx#group_control_map
			WHERE	product_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#"/>
		</cfquery>
		<cfoutput query="qry">
			<cfscript>ArrayAppend(this.group,group_id);</cfscript>
		</cfoutput>
	</cffunction>

	<cffunction name="save" hint="Save the core properties of the product." access="public" output="false" returntype="void">
		<!--- TODO: Implement Method --->
		<cfreturn />
	</cffunction>

	<cffunction name="getBugs" hint="Returns the bugs associated with this product as a query." access="public" output="false" returntype="query">
		<cfargument name="status" required="false" type="string" hint="Restrict the results to a specific type of status. Accepts a comma delimited list. Examples include NEW,ASSIGNED,etc."/>
		<cfscript>
			var qry = "";
			var span = createTimeSpan(0,0,5,0);

			if (StructKeyExists(url,"restart"))
				span = createTimeSpan(0,0,0,0);
		</cfscript>
		<cfif not StructKeyExists(this,"adminuser")>
			<cfthrow message="Not initialized" detail="The Bugzilla product is not initialized."/>
		</cfif>
		<cfquery name="qry" datasource="#this.dsn#" cachedwithin="#span#">
			SELECT	version,bug_status,bug_id, assigned_to,bug_file_loc,bug_severity,creation_ts,
					delta_ts,short_desc,op_sys,priority,rep_platform,reporter,version,component_id,resolution,
					target_milestone,qa_contact,status_whiteboard,votes,keywords,lastdiffed,everconfirmed,
					reporter_accessible,cclist_accessible,estimated_time,remaining_time,deadline,alias
			FROM	#this.pfx#bugs
			WHERE	product_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#this.id#"/>
					<cfif StructKeyExists(arguments,"status")>
					AND bug_status IN (<cfqueryparam list="true" cfsqltype="cf_sql_varchar" value="#ListQualify(arguments.status,',')#"/>)
					</cfif>
			GROUP BY version, bug_status, bug_id, version,assigned_to,bug_file_loc,bug_severity,creation_ts,
					delta_ts,short_desc,op_sys,priority,rep_platform,reporter,component_id,resolution,
					target_milestone,qa_contact,status_whiteboard,votes,keywords,lastdiffed,everconfirmed,
					reporter_accessible,cclist_accessible,estimated_time,remaining_time,deadline,alias
		</cfquery>
		<cfreturn qry/>
	</cffunction>

	<cffunction name="addBug" hint="Adds a new bug to this product." access="public" output="false" returntype="void">
		<cfargument name="user" required="true" type="string" hint="The email address of the user. If using LDAP or Active Directory, make sure this is the same email account associated with the user's LDAP/AD account."/>
		<cfargument name="pwd" required="true" type="string" hint="A plain text password (will be auto-encrypted)."/>
		<cfargument name="summary" type="String" hint="The descriptive summary/title of the bug." required="true" />
		<cfargument name="description" type="String" hint="The message text explaining the issue." required="true" />
		<cfargument name="component" required="true" type="string" hint="The component of the product in which the issue arose."/>
		<cfargument name="version" required="false" default="1.0" type="string" hint="The version of the product in which the issue arose."/>
		<cfargument name="platform" required="false" type="string" hint="The platform on which the issue occurred."/>
		<cfargument name="os" required="false" type="string" hint="The Operating System on which the issue occurred."/>
		<cfargument name="priority" required="false" type="string" hint="The priority level of the issue."/>
		<cfargument name="severity" required="false" default="" type="string" hint="The severity of the issue."/>
		<cfargument name="location" required="false" default="" type="string" hint="The URL where the issue occurred."/>
		<cfargument name="dependson" required="false" default="" type="string" hint="The ID of another issue on which this new issue is dependent."/>
		<cfscript>
			super.createBug(trim(arguments.user),trim(arguments.pwd),trim(arguments.description),trim(arguments.summary),this.name,arguments.component,arguments.version,arguments.platform,arguments.os,arguments.priority,arguments.severity,this.default.status,JavaCast("null",""),JavaCast("null",""),this.default.estimatedTime,arguments.location,JavaCast("null",""),JavaCast("null",""),arguments.dependson);
		</cfscript>
		<cfreturn />
	</cffunction>
</cfcomponent>