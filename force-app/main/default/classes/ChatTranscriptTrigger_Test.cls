@isTest
public class ChatTranscriptTrigger_Test {
	/*@testSetup
    static void setup() {
        TriggersTest.activaTriggers();
                
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
        
        Account acc = new Account();
        acc.FirstName = 'Chat';
        acc.LastName = 'Test';
        acc.Email__c = 'test@email.com';
        insert acc;
        
        Lead le = new Lead();
        le.LastName = 'ChatLead';
        le.Email = 'testlead@email.com';
        insert le;
    }
    
    @isTest
    static void matchAccountEmailTest() {
        User us = [SELECT Id FROM User WHERE Name = :Label.UserAutomatedProcess LIMIT 1];
        LiveChatVisitor visitor = [SELECT Id FROM LiveChatVisitor LIMIT 1];
        
        System.runAs(us) {
            LiveChatTranscript chat = new LiveChatTranscript();
        	chat.LiveChatVisitorId = visitor.Id;
        	chat.AccountId = null;
        	chat.LeadId = null;
        	chat.CustomerName__c = 'Chat';
        	chat.CustomerLastname__c = 'Test';
        	chat.CustomerEmail__c = 'test@email.com';
            //chat.Status = 'In Progress';
            
            Test.startTest();
            insert chat;
            
            chat.CustomerEmail__c = '';
            update chat;
            Test.stopTest();
        }
    }
    
    @isTest
    static void matchLeadEmailTest() {
        User us = [SELECT Id FROM User WHERE Name = :Label.UserAutomatedProcess LIMIT 1];
        LiveChatVisitor visitor = [SELECT Id FROM LiveChatVisitor LIMIT 1];
        
        System.runAs(us) {
            LiveChatTranscript chat = new LiveChatTranscript();
        	chat.LiveChatVisitorId = visitor.Id;
        	chat.AccountId = null;
        	chat.LeadId = null;
        	chat.CustomerName__c = 'Chat';
        	chat.CustomerLastname__c = 'Test';
        	chat.CustomerEmail__c = 'testlead@email.com';
            
            Test.startTest();
            insert chat;
            Test.stopTest();
        }
    }
    
    @isTest
    static void deleteTest() {
        LiveChatVisitor visitor = [SELECT Id FROM LiveChatVisitor LIMIT 1];
        
        LiveChatTranscript chat = new LiveChatTranscript();
        chat.LiveChatVisitorId = visitor.Id;
        
        Test.startTest();
        insert chat;
        delete chat;
        Test.stopTest();
    }*/
}