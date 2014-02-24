Salesforce Public Tags to Chatter Topics Migration Tool
=========

This tool provides a Batch Apex class which converts Public Tags associated to records in Salesforce to Chatter Topics for Objects (Spring '14 / Version 30.0 feature).

Components
--

  - Visualforce page: /apex/tagMigration
  - Apex Class: tagMigration (Visualforce page controller)
  - Apex Class: tagMigrationBatch



Installation
--------------

#####Option 1:
Install the unmanaged package at: https://login.salesforce.com/packaging/installPackage.apexp?p0=04ti0000000H1ei
#####Option 2:
git clone this repo and deploy with your favorite Salesforce apex deployment tool

Usage
--------------
  - Install the components via the unmanaged package or a deploy to your org
  - Navigate to https://instance.salesforce.com/apex/tagMigration
  - Examine the objects you currently have tagging enabled for, enable Topics for Objects on the objects you would like to migrate.
  - Click the "Start Public Tags to Topics Migration" button
  - Wait for emails saying the proccess is complete
  - Check out your new topics!
  - Uninstall the package at Setup -> Installed Packages

Installation Problems
--------------
  - If you receive "Missing Organization Feature: Tagging" on install, make sure you have both public and private tagging enabled.
 
Issues
--------------
 - For some reason the TagDefinition object is consistently empty in @isTest methods if SeeAllData != true, even with tags created inside the test method.
 - It would be nice to provide the user with a mapping of Tag Objects -> Objects and display if they are Chatter Topic enabled or not. Resolution would be to figure out how to describe if Chatter For Objects is enabled on a specific sObject.

License
----

MIT

    
