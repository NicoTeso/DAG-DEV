@isTest
public class ApiConnect {

    public static void activaApiConnect(){
        ApiConnect__c api = new ApiConnect__c();
        api.ApiClient_id__c='1234';
        api.ApiClient_secret__c='1234';
        api.ApiConsentimiento__c='https://com-dag-exp-sf-dev.de-c1.cloudhub.io/api/v1/customers/consents';
        api.ApiCreateCustomer__c='https://com-dag-exp-sf-dev.de-c1.cloudhub.io/api/v1/customers';
        api.ApiCreateLead__c='https://com-dag-exp-sf-dev.de-c1.cloudhub.io/api/v1/leads';
        insert api;
    }
}