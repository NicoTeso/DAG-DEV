@isTest
public class AccountAndLeadByEmailController_Test {
    @testSetup
    static void setup() {
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        
        LiveChatTranscript chat = new LiveChatTranscript();
        chat.LiveChatVisitorId = visitor.Id;
        chat.CustomerEmail__c = 'test@email.com';
        insert chat;
        
        Account acc = new Account();
        acc.Name = 'Test Acc';
        acc.Email__c = 'test@email.com';
        insert acc;
        
        Lead le = new Lead();
        le.LastName = 'Test';
        le.Email = 'test@email.com';
        insert le;
    }
    
	@isTest
    static void getAccountAndLeadsTest() {
        LiveChatTranscript chat = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        
        chat = AccountAndLeadByEmailController.getLiveChat(chat.Id);
        
        Test.startTest();
        List<Account> lstAccounts = AccountAndLeadByEmailController.getAccountsByChatId(chat.Id);
        List<Lead> lstLeads = AccountAndLeadByEmailController.getLeads(chat.CustomerEmail__c);
        Test.stopTest();
    }
    
    @isTest
    static void relationTest() {
        LiveChatTranscript chat = [SELECT Id FROM LiveChatTranscript LIMIT 1];
		Account acc = [SELECT Id FROM Account LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        AccountAndLeadByEmailController.relacionar(chat.Id, acc.Id, 'C. Física');
        AccountAndLeadByEmailController.relacionar(chat.Id, le.Id, 'Candidato');
        Test.stopTest();
    }
    
    @isTest
    static void getListResponseTest() {
        LiveChatTranscript chat = [SELECT Id FROM LiveChatTranscript LIMIT 1];
        
        Test.startTest();
        String response = AccountAndLeadByEmailController.getListResponse(chat.id);
        Test.stopTest();
    }
}