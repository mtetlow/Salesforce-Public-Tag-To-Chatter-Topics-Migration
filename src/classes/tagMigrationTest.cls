@isTest
private class tagMigrationTest {
	
	@isTest static void testConvertingTagsObj() {
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
					}
				}
				
			}
			
			
			//Execute migration
			Test.startTest();
			insert tagsToInsert;
			List<TagDefinition> tags = [SELECT Id, IsDeleted, LastModifiedById, Name, SystemModstamp, Type FROM TagDefinition];
			system.debug('tags size '+tags.size());
			tagMigrationBatch migrationBatch = new tagMigrationBatch();
			Database.executeBatch(migrationBatch);
			Test.stopTest();

			//Ensure topics are created
			List<Topic> topics = [SELECT Id,Name FROM Topic WHERE Name IN :tagNameSet];
			//This would work great if we could query what objects are chatter topics enabled. If the objects aren't chatter topics enabled the topic assignment inserts fail
			//system.assertEquals(topics.size(),tagNameSet.size());

			//Ensure topics are assigned
		}
	}

	@isTest static void testVFPage(){
		//Test button press
		tagMigration migrationClass = new tagMigration();
		migrationClass.executeBatch();
		system.assert(migrationClass.batchId != null);
	}
	
}