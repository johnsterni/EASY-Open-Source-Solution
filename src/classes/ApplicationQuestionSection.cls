/*******************************************************************************
@description This class holds a collection of Requirement Items named ApplicationQuestionGroup and filters these items using the ApplicationFilter logic
@author Huron Consulting Group

Revision (s): 
*******************************************************************************/
public class ApplicationQuestionSection {

    public List<ApplicationQuestionGroup> groups {get;private set;}
    private Application__c application {
        get {
        	if (application == null && groups != null) {
                for (ApplicationQuestionGroup g:groups) {
                    if (g.app != null) {
                        application = g.app;
                        break;
                    }
                }
            }
            return application;
   	 	} set;
    }

    public ApplicationQuestionSection(List<ApplicationQuestionGroup> groups) {
        this.groups = groups;
        setProgress();
    }

    public ApplicationQuestionSection(Application__c app, List<Requirement_Item__c> items, Map<Id, List<Question_Dependency__c>> dQuestions, Map<Id, Requirement_Response__c> responses, Map<Id, List<Question_Response__c>> dResponses, Map<String,Map<String,Schema.SObjectField>> fieldDescribeMap) {
        groups = new List<ApplicationQuestionGroup>();
		application = app;
        for (Requirement_Item__c i:items){
            if(ApplicationFilter.filter(app,i)){
                groups.add(ApplicationQuestionSection.createQuestionGroup(app, i, dQuestions, responses.get(i.Id), dResponses.get(i.Id),fieldDescribeMap));
            }
        }
        
        addDependencies(dQuestions, dResponses);
        setProgress();
    }
    
    public void addDependencies(Map<Id, List<Question_Dependency__c>> dQuestions, Map<Id, List<Question_Response__c>> dResponses) {
        
        Map<Id, ApplicationQuestion> qMap = new Map<Id, ApplicationQuestion>();
        for (ApplicationQuestionGroup g:groups)
            if ((g.questionGroup || g.relatedObject) && g.questions != null && g.item != null)
                for (ApplicationQuestion aq:g.questions)
                    if (aq.question != null)
                        qMap.put(aq.question.Id, aq);
        
        for (ApplicationQuestionGroup g:groups)
            if ((g.questionGroup || g.relatedObject) && g.questions != null && g.item != null)
                g.addQuestionDependencies(qMap, dQuestions, dResponses == null ? null : dResponses.get(g.item.Id));
    }
    
    private void setProgress() {
        for (Integer n = 0; n < groups.size(); n++)
            groups[n].progress = (((Decimal)n + 1) / ((Decimal)groups.size())) * 100;
    }
    
    public static ApplicationQuestionGroup createQuestionGroup(Application__c app, Requirement_Item__c i, Map<Id, List<Question_Dependency__c>> dQuestions, Requirement_Response__c response,  List<Question_Response__c> dResponses, Map<String,Map<String,Schema.SObjectField>> fieldDescribeMap){
        return createQuestionGroup(app, i, dQuestions, response, dResponses, fieldDescribeMap, false);
    }
    
    /*******************************************************************************
    * @description Creates a question group from a single requirement item
    ********************************************************************************/
    public static ApplicationQuestionGroup createQuestionGroup(Application__c app, Requirement_Item__c i, Map<Id, List<Question_Dependency__c>> dQuestions, Requirement_Response__c response,  List<Question_Response__c> dResponses, Map<String,Map<String,Schema.SObjectField>> fieldDescribeMap, Boolean isAppCreate){
        Map<String,Schema.SObjectField> sObjectFields;
        if(String.isNotBlank(i.Related_List_Object__c) && fieldDescribeMap != null && fieldDescribeMap.containskey(i.Related_List_Object__c)){
            sObjectFields = fieldDescribeMap.get(i.Related_List_Object__c);
        }
        return new ApplicationQuestionGroup(app, i, dQuestions, response, dResponses,sObjectFields, isAppCreate);
    }
    /*******************************************************************************
    * @description Asks the QuestionGroup to prepare to be saved
    ********************************************************************************/
    public void processValues(){
        processValues(null);
    }
    public void processValues(Map<String,Object> additionalData) {
        for (ApplicationQuestionGroup g:groups){
            Map<String,Object> addData;
            if(g.item != null && g.item.Id != null && additionalData != null && additionalData.containsKey(g.item.Id)){
                addData = (Map<String,Object>)additionalData.get(g.item.Id);
            }
            g.processValues(addData);
        }
    }
    
    public void pushValuesToObjects() {
        
        if (application == null) return;
        
        Set<String> allFields = new Set<String>();
        Map<String, Object> values = new Map<String, Object>();
        for (ApplicationQuestionGroup g:groups) {
            if (g.questionGroup) {
                for (ApplicationQuestion q:g.questions) {
                    if (q.question != null && String.isNotBlank(q.question.Application_Field__c)) {
                        allFields.add(q.question.Application_Field__c.toLowerCase());
                        q.getShowQuestion();
                        
                        if (q.resp != null)
                            values.put(q.question.Application_Field__c.toLowerCase(), q.resp);
                    }
                }
            }
        }
        
        for (String f:allFields) {
            try {
                application.put(f, values.get(f));
            } catch (Exception e) {}
        }
    }
}