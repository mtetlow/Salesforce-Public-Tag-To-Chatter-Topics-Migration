global class tagMigrationBatch implements Database.Batchable<sObject> {
	
	public String query = 'SELECT Id FROM TagDefinition';
	List<String> tagObjNames = new List<String>();
	public Integer publicTagCount{get;set;}
	public Integer initialTopicAssignmentCount{get;set;}
	public Integer finalTopicAssignmentCount{get;set;}

	global tagMigrationBatch() {
		for(String objName : Schema.getGlobalDescribe().keySet()){
			if(objName.endsWith('tag')){
				tagObjNames.add(objName);
			}
		}
		setPublicTagCount();
		List<AggregateResult> groupedResults = [SELECT COUNT(Id) FROM TopicAssignment];
		if(groupedResults[0] != null){
			initialTopicAssignmentCount=Integer.valueOf(groupedResults[0].get('expr0'));
		}

	}

	public void setPublicTagCount(){
		List<String> tagObjNames = new List<String>();
		for(String objName : Schema.getGlobalDescribe().keySet()){
			if(objName.endsWith('tag')){
				tagObjNames.add(objName);
			}
		}
		Integer tagRecordCount = 0;
		Integer totalQueryLimit = Limits.getLimitQueries();
		Integer queriesAfter = 1;
		for(String objName : tagObjNames){
			if(Limits.getQueries() <= totalQueryLimit-queriesAfter){
				String objQuery = 'SELECT COUNT(Id) FROM '+objName+' WHERE Type=\'Public\'';
				List<AggregateResult> groupedResults = Database.query(objQuery);
				if(groupedResults[0] != null){
					tagRecordCount = tagRecordCount+Integer.valueOf(groupedResults[0].get('expr0'));
				}
			}
		}
		publicTagCount=tagRecordCount;

	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {

		messaging.singleEmailMessage mail = new messaging.singleEmailMessage();
	    String sfUrl=URL.getSalesforceBaseUrl().getHost();
		String apexJobUrl = 'https://'+sfUrl+'/apexpages/setup/listAsyncApexJobs.apexp';
	    mail.setToAddresses(new string[]{UserInfo.getUserEmail()});
	    mail.setReplyTo('no-reply@salesforce.com');
	    mail.setSubject('Tag Migration Start');
	    String htmlBody = 'Your tag migration has started!<br /><br />';
	    htmlBody += 'You can check on the status of the batch job at: ';
	    htmlBody += '<a href="'+apexJobUrl+'">Apex Jobs</a><br /> <br />';
	    htmlBody += 'You will receive another email with more information after the job completes.';
	    mail.setHTMLBody(htmlBody);

	    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<Id> tagDefIds = new List<Id>();
		for(sObject item : scope){
			tagDefIds.add(Id.valueOf(String.valueOf(item.get('Id'))));
		}
		
		List<sObject> tagObjs = new List<sObject>();
		Integer totalQueryLimit = Limits.getLimitQueries();
		Integer queriesAfter = 2;
		for(String objName : tagObjNames){
			if(Limits.getQueries() <= totalQueryLimit-queriesAfter){
				tagObjs.addAll(Database.query('SELECT Id,Name,ItemId FROM '+objName+' WHERE TagDefinitionId IN :tagDefIds AND Type=\'Public\''));
			}
		}

		Map<String,List<Id>> topicNameToEntityIdsMap = new Map<String,List<Id>>();
		for(sObject tagObj : tagObjs){
			String topicName = String.valueOf(tagObj.get('Name'));
			if(topicNameToEntityIdsMap.get(topicName) == null){ topicNameToEntityIdsMap.put(topicName,new List<Id>()); }
			List<Id> itemIds = topicNameToEntityIdsMap.get(topicName);
			itemIds.add(Id.valueOf(String.valueOf(tagObj.get('ItemId'))));
			topicNameToEntityIdsMap.put(topicName,itemIds);
		}

		List<Topic> topicsToInsert = new List<Topic>();
		for(String topicName : topicNameToEntityIdsMap.keySet()){
			topicsToInsert.add(new Topic(Name=topicName));
		}
		//All or none false because we might have topics matching the names we are trying to insert
		Database.insert(topicsToInsert,false);

		List<Topic> topicsInserted = [SELECT Id,Name FROM Topic WHERE Name IN :topicNameToEntityIdsMap.keySet()];

		Map<String,Id> topicNameToIdMap = new Map<String,Id>();
		for(Topic topic : topicsInserted){
			topicNameToIdMap.put(topic.Name,topic.Id);
		}

		List<TopicAssignment> topicAssignmentsToInsert = new List<TopicAssignment>();
		for(String topicName : topicNameToEntityIdsMap.keySet()){
			List<Id> topicEntityIds = topicNameToEntityIdsMap.get(topicName);
			for(Id topicEntityId : topicEntityIds){
				topicAssignmentsToInsert.add(new TopicAssignment(EntityId=topicEntityId, TopicId=topicNameToIdMap.get(topicName)));
			}
		}
		//All or none false because there might already be an association
		Database.insert(topicAssignmentsToInsert,false);
	}
	
	global void finish(Database.BatchableContext BC) {

		List<AggregateResult> groupedResults = [SELECT COUNT(Id) FROM TopicAssignment];
		if(groupedResults[0] != null){
			finalTopicAssignmentCount=Integer.valueOf(groupedResults[0].get('expr0'));
		} else{
			finalTopicAssignmentCount=0;
		}

		messaging.singleEmailMessage mail = new messaging.singleEmailMessage();
	    AsyncApexJob a = [SELECT CreatedBy.Email,NumberOfErrors,TotalJobItems,Status FROM AsyncApexJob WHERE Id =:BC.getJobId()];
	    mail.setToAddresses(new string[]{a.CreatedBy.Email});
	    mail.setReplyTo('no-reply@salesforce.com');
	    mail.setSubject('Tag Migration Complete');
	    String htmlBody = 'Your tag migration is complete!<br />All public tags which belong to a record whose object is Object Topics Enabled (Setup -> Customizer -> Topics -> Topics For Objects), should be migrated to Chatter Topics.<br /><br />';
	    htmlBody += 'Org Wide Public Tag Count: '+publicTagCount+'<br />';
	    htmlBody += 'Chatter Topic Assignment Count (Before Migration): '+initialTopicAssignmentCount+'<br />';
	    htmlBody += 'Chatter Topic Assignment Count (After Migration): '+finalTopicAssignmentCount+'<br />';
	    htmlBody += 'Number of Errors: '+a.NumberOfErrors+'<br />';
	    htmlBody += 'Number of Items Processed: '+a.TotalJobItems+'<br />';
	    htmlBody += 'Final Job Status: '+a.Status+'<br />';
	    mail.setHTMLBody(htmlBody);

	    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
	
}