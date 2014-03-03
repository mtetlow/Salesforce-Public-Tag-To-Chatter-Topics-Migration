public with sharing class tagMigration {
	public Integer publicTagCount{get;set;}
	public Integer initialTopicAssignmentCount{get;set;}
	public String tagEnabledObjects{get;set;}
	public String apexJobUrl{get;set;}
	public Id batchId{get;set;}
	
	public tagMigration() {
		setPublicTagInfo();
		setTopicCounts();
		String sfUrl=URL.getSalesforceBaseUrl().getHost();
		apexJobUrl = 'https://'+sfUrl+'/apexpages/setup/listAsyncApexJobs.apexp';

	}

	public void setTopicCounts(){
		List<AggregateResult> groupedResults = [SELECT COUNT(Id) FROM TopicAssignment];
		if(groupedResults[0] != null){
			initialTopicAssignmentCount=Integer.valueOf(groupedResults[0].get('expr0'));
		}
	}

	public void setPublicTagInfo(){
		List<String> tagObjNames = new List<String>();
		List<String> tagEnabledObjLabels = new List<String>();
		Map<String,Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();
		for(String objName : globalDesc.keySet()){
			if(objName.endsWith('tag')){
				tagObjNames.add(objName);
			}
		}
		Integer tagRecordCount = 0;
		Integer totalQueryLimit = Limits.getLimitQueries();
		Integer queriesAfter = 2;
		for(String objName : tagObjNames){
			if(Limits.getQueries() <= totalQueryLimit-queriesAfter){
				String objQuery = 'SELECT COUNT(Id) FROM '+objName+' WHERE Type=\'Public\'';
				List<AggregateResult> groupedResults = Database.query(objQuery);
				if(groupedResults[0] != null){
					tagRecordCount = tagRecordCount+Integer.valueOf(groupedResults[0].get('expr0'));
				}
			}
			Schema.SObjectType tagObjType = globalDesc.get(objName);
			Schema.DescribeSObjectResult objDesc = tagObjType.getDescribe();
			tagEnabledObjLabels.add(objDesc.getLabel());
		}
		publicTagCount=tagRecordCount;
		tagEnabledObjects=String.join(tagEnabledObjLabels,', ');
	}

	public void executeBatch(){
		batchId=Database.executeBatch(new tagMigrationBatch());
	}

}