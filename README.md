<h1>About BugConnect</h1>
BugConnect is a small package of CF components that connect to and interact with Bugzilla. It was originally created to provide CF developers with a simple way to create custom skins using CF/HTML that mask Bugzilla from end-users.

<b>Features</b>
- Dynamically create/disable Bugzilla users
- Submit bugs
- Update/comment on bugs
- Create CC Lists
- Retrieve bugs for display

This is not meant to be a replacement for the Bugzilla administrator. It is meant to support people interested in making a custom interface or connecting to remote Bugzilla instances. This could be especially useful in situations where QA users need a central place to submit bugs against multiple Bugzilla instances. It can also be used in situations where developers need to customize what gets submitted before it reaches Bugzilla. 

The package follows a loose object oriented approach, so it is not reliant on any framework.

See the screenshots for examples of this in use. The download package has a comprehensive guide with setup instructions, examples, screenshots, and documentation (PDF/HTML).

<b>Requirements:</b>
ColdFusion 8 (probably works with 7 too)
Bugzilla 3.2.3+ (also tested against 3.3.4) 