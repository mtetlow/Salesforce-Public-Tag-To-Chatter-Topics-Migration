Salesforce Public Tags to Chatter Topics Migration Tool
=========

This tool provides a Batch Apex class which converts Public Tags associated to records in Salesforce to Chatter Topics for Objects.

Components
--

  - Visualforce page: /apex/tagMigration
  - Apex Class: tagMigration (Visualforce page controller)
  - Apex Class: tagMigrationBatch



Installation
--------------

#####Option 1:
Install the unmanaged package at: https://login.salesforce.com/packaging/installPackage.apexp?p0=04ti0000000H1ed
#####Option 2:
git clone this repo and deploy with your favorite Salesforce apex deployment tool
##### Configure Plugins. Instructions in following README.md files

Usage
--------------
  - Install the components via the unmanaged package or a deploy to your org
  - Navigate to https://<instance>.salesforce.com/apex/tagMigration
  - Examine the objects you currently have tagging enabled for, enable Topics for Objects on the objects you would like to migrate.
  - Click the "Start Public Tags to Topics Migration" button
  - Wait for emails saying the proccess is complete
  - Check out your new topics!

Installation Problems
--------------
  - If you receive "Missing Organization Feature: Tagging" on install, make sure you have both public and private tagging enabled.
 
Issues
--------------
 - Test class is weak. There are a few reasons why
   - Can't find a way to see if Chatter Topics for Objects is enabled on a specific object through Apex. This means we can't be sure what tags should actually be converting. A possible work around for this could be to make a custom setting to determine what objects are available to Chatter topics via catching exceptions
   - For some reason the TagDefinition object is consistently empty in @isTest methods. Even after inserting tags directly above querying the TagDefinition object.
 - It would be nice to provide the user with a mapping of Tag Objects -> Objects and display if they are Chatter Topic enabled or not. Resolution would be the same as first test class subissue.

License
----

MIT

    
