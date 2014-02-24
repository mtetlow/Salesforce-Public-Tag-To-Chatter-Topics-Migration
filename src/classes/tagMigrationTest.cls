@isTest
private class tagMigrationTest {
	
	//Have to use SeeAllData = true to see *anything* in the TagDefinition Object
	@isTest (SeeAllData=true) static void testConvertingTagsObj() {
		//Find objects that are tag objects in the org so we can add some tags
		List<String> tagObjNames = new List<String>();
		Map<String,Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();
		
		for(String objName : globalDesc.keySet()){
			if(objName.endsWith('tag')){
				tagObjNames.add(objName);
			}
		}
		if(tagObjNames.size() > 0){
			//Insert test records
			List<sObject> recordsToInsert = new List<sObject>();
			Map<Integer,String> arrIndexToTypeMap = new Map<Integer,String>();
			Integer j = 0;
			Map<String,List<sObject>> tagObjNameToRecordList = new Map<String,List<sObject>>();
			for(String tagObjName : tagObjNames){
				

				String tagRecordObj = (tagObjName.contains('__tag')) ? tagObjName.replace('__tag','__c') : tagObjName.subString(0,tagObjName.length()-3);
				//remove objects we can't do dml inserts on, or don't have name fields
				if(tagRecordObj=='report' || tagRecordObj == 'note' || tagRecordObj == 'task'){break;}
				Schema.SObjectType recordObjType = globalDesc.get(tagRecordObj);				
				if(tagObjNameToRecordList.get(tagObjName) == null){ tagObjNameToRecordList.put(tagObjName,new List<sObject>()); }
				for(Integer i = 0; i<10; i++){
					sObject record = recordObjType.newSObject();
					record.put('Name','Test Record '+tagRecordObj+' '+i);
					recordsToInsert.add(record);
					//arrIndexToTypeMap.put(j,)
					List<sObject> recordsForType = tagObjNameToRecordList.get(tagObjName);
					recordsForType.add(record);
					tagObjNameToRecordList.put(tagObjName,recordsForType);
					j++;
				}
			}
			//All or none false because of required fields
			Database.insert(recordsToInsert,false);

			//Transform the records into a map of type -> list of records
			

			//Insert test tags
			List<sObject> tagsToInsert = new List<sObject>();
			Set<String> tagNameSet = new Set<String>();
			Map<String,Set<Id>> tagNameToRecordIdSet = new Map<String,Set<Id>>();
			for(String tagObjName : tagObjNames){
				Schema.SObjectType tagObjType = globalDesc.get(tagObjName);
				List<sObject> recordsForTagType = tagObjNameToRecordList.get(tagObjName);
				if(recordsForTagType!= null){
					for(Integer i = 0; i<100; i++){
						sObject tag = tagObjType.newSObject();
						String nameStr = tagObjName+' Test tag str '+i;
						tagNameSet.add(nameStr);
						tag.put('Name', nameStr);
						tag.put('Type','Public');
						Id recordId = Id.valueOf(String.valueOf(recordsForTagType[i/10].get('Id')));
						tag.put('ItemId',recordId);
						tagsToInsert.add(tag);
						if(tagNameToRecordIdSet.get(nameStr)==null){tagNameToRecordIdSet.put(nameStr,new Set<Id>());}
						tagNameToRecordIdSet.get(nameStr).add(recordId);
					}
				}
				
			}
			
			insert tagsToInsert;
			
			List<String> nameList = new List<String>();
			nameList.addAll(tagNameSet);
			String insertedTagNameWrappedString = '\''+String.join(nameList, '\',\'')+'\'';

			//Execute migration
			Test.startTest();
			tagMigrationBatch migrationBatch = new tagMigrationBatch();
			//Have to pass a string as the set var would be out of scope
			migrationBatch.query = 'SELECT Id FROM TagDefinition WHERE Name IN ('+insertedTagNameWrappedString+')';
			Database.executeBatch(migrationBatch);
			Test.stopTest();

			//Ensure topics are created
			Map<Id,Topic> topics = new Map<Id,Topic>([SELECT Id,Name FROM Topic WHERE Name IN :tagNameSet]);
			system.assertEquals(topics.keySet().size(),tagNameSet.size());

			//Ensure topics are assigned, we won't fail if topics assignments are not created due to Chatter for Topics not being enabled
			List<TopicAssignment> topicAssignments = [SELECT EntityId, TopicId, Topic.Name FROM topicAssignment WHERE TopicId IN :topics.keySet()];
			for(TopicAssignment topicAssign : topicAssignments){
				Set<Id> recordIdSet = tagNameToRecordIdSet.get(topicAssign.Topic.Name);
				system.assert(recordIdSet.contains(topicAssign.EntityId));
			}
		}
	}

	@isTest static void testVFPage(){
		//Test button press
		tagMigration migrationClass = new tagMigration();
		migrationClass.executeBatch();
		system.assert(migrationClass.batchId != null);
	}
	
}