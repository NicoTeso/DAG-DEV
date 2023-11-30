@isTest
public class AccountTrigger_Test {
	@testSetup
    static void setup() {
        TriggersTest.activaTriggers();
		CreaObjetos.creaPais();
    }
    
    @isTest static void AccountConsentimientoEmailTest() {
        String email = 'pruebaemail@test.com';
        Account acc = creaObjetos.creaCuentaPersonal('Test', 'Personal');
        acc.PersonEmail = 'pruebaotheremail@test.com';
        Test.startTest();
        insert acc;
        
        List<Consentimientos__c> listConsentimientos = new List<Consentimientos__c>();
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id limit 1];
        Consentimientos__c consentimientoPersonEmail = CreaObjetos.creaConsentimientoOther(email, con.Id, Label.channelEmail,false);
       	listConsentimientos.add(consentimientoPersonEmail);
        insert listConsentimientos;
        
        Pais__c pais = [select Id FROM pais__c limit 1];
       	
        
        acc.PersonEmail = email;
        acc.Pais__c = pais.Id;
        update acc;
        Test.stopTest();
        
        Consentimientos__c consentimiento = [select id, ChannelValue__c, Medio_de_contacto__c,contact__c from Consentimientos__c where contact__c = :con.Id limit 1];
    	Account cuenta = [select id, PersonEmail, OtherEmail__pc from Account where Id = :acc.Id limit 1 ];
        system.assertEquals(consentimiento.ChannelValue__c, cuenta.PersonEmail);
        system.assertEquals(consentimiento.Medio_de_contacto__c, Label.channelEmail);
        
    }
    
    @isTest static void AccountConsentimientoOtherEmailTest() {
        String email = 'pruebaotheremail@test.com';
        Account acc = creaObjetos.creaCuentaPersonal('Test', 'Personal');
        acc.OtherEmail__pc = 'pruebaemail@test.com';
       
        Test.startTest();
        insert acc;
        List<Consentimientos__c> listConsentimientos = new List<Consentimientos__c>();
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id limit 1];
        Consentimientos__c consentimientoOtherEmail = CreaObjetos.creaConsentimientoOther(email, con.Id, Label.channelEmail,false);
       	listConsentimientos.add(consentimientoOtherEmail);
        insert listConsentimientos;
        
        Pais__c pais = [select Id FROM pais__c limit 1];
       	
        acc.OtherEmail__pc = email;
        acc.Pais__c = pais.Id;
        update acc;
        Test.stopTest();
        
        Consentimientos__c consentimiento = [select id, ChannelValue__c, Medio_de_contacto__c,contact__c from Consentimientos__c where contact__c = :con.Id limit 1];
    	Account cuenta = [select id, PersonEmail, OtherEmail__pc from Account where Id = :acc.Id limit 1 ];
        system.assertEquals(consentimiento.ChannelValue__c, cuenta.OtherEmail__pc);
        system.assertEquals(consentimiento.Medio_de_contacto__c, Label.channelOtherEmail);
    }
    
    @isTest static void AccountConsentimientoPhoneTest() {
        String phone = '919999999';
        Account acc = creaObjetos.creaCuentaPersonal('Test', 'Personal');
        acc.Phone ='999999999';
        Test.startTest();
        insert acc;
        
        List<Consentimientos__c> listConsentimientos = new List<Consentimientos__c>();
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id limit 1];
        Consentimientos__c consentimientoPersonEmail = CreaObjetos.creaConsentimientoOther(phone, con.Id, Label.channelPhone,false);
       	listConsentimientos.add(consentimientoPersonEmail);
        insert listConsentimientos;
        
        Pais__c pais = [select Id FROM pais__c limit 1];
        
        acc.phone = phone;
        acc.Pais__c = pais.Id;
        update acc;
        Test.stopTest();
        
        Consentimientos__c consentimiento = [select id, ChannelValue__c, Medio_de_contacto__c,contact__c from Consentimientos__c where contact__c = :con.Id limit 1];
    	Account cuenta = [select id, Phone from Account where Id = :acc.Id limit 1 ];
        system.assertEquals(consentimiento.ChannelValue__c, cuenta.phone);
        system.assertEquals(consentimiento.Medio_de_contacto__c, Label.channelPhone);
    }
    
    @isTest static void AccountConsentimientoOtherPhoneTest() {
        String phone = '919999999';
        Account acc = creaObjetos.creaCuentaPersonal('Test', 'Personal');
        
        acc.PersonOtherPhone ='999999999';
        Test.startTest();
        insert acc;
        
        List<Consentimientos__c> listConsentimientos = new List<Consentimientos__c>();
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id limit 1];
        Consentimientos__c consentimientoPersonEmail = CreaObjetos.creaConsentimientoOther(phone, con.Id, Label.channelPhone,false);
       	listConsentimientos.add(consentimientoPersonEmail);
        insert listConsentimientos;
        
        Pais__c pais = [select Id FROM pais__c limit 1];
       	
        acc.PersonOtherPhone = phone;
        acc.Pais__c = pais.Id;
        update acc;
        Test.stopTest();
        
        Consentimientos__c consentimiento = [select id, ChannelValue__c, Medio_de_contacto__c,contact__c from Consentimientos__c where contact__c = :con.Id limit 1];
    	Account cuenta = [select id,PersonOtherPhone  from Account where Id = :acc.Id limit 1 ];
        system.assertEquals(consentimiento.ChannelValue__c, cuenta.PersonOtherPhone);
        system.assertEquals(consentimiento.Medio_de_contacto__c, Label.channelOtherPhone);
    }
    
    @isTest static void AccountConsentimientoMobileTest() {
        String mobile = '619999999';
        Account acc = creaObjetos.creaCuentaPersonal('Test', 'Personal');
        acc.PersonMobilePhone = '699999999';
        Test.startTest();
        insert acc;
        
        List<Consentimientos__c> listConsentimientos = new List<Consentimientos__c>();
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id limit 1];
        Consentimientos__c consentimientoPersonEmail = CreaObjetos.creaConsentimientoOther(mobile, con.Id, Label.channelMobile,false);
       	listConsentimientos.add(consentimientoPersonEmail);
        insert listConsentimientos;
        
        Pais__c pais = [select Id FROM pais__c limit 1];
        
        acc.PersonMobilePhone = mobile;
        acc.Pais__c = pais.Id;
        update acc;
        Test.stopTest();
        
        Consentimientos__c consentimiento = [select id, ChannelValue__c, Medio_de_contacto__c,contact__c from Consentimientos__c where contact__c = :con.Id limit 1];
    	Account cuenta = [select id, PersonMobilePhone  from Account where Id = :acc.Id limit 1 ];
        system.assertEquals(consentimiento.ChannelValue__c, cuenta.PersonMobilePhone);
        system.assertEquals(consentimiento.Medio_de_contacto__c, Label.channelMobile);
    }
    
    @isTest static void AccountConsentimientoOtherMobileTest() {
        String mobile = '619999999';
        Account acc = creaObjetos.creaCuentaPersonal('Test', 'Personal');
        acc.OtherMobilePhone__pc = '699999999';
        Test.startTest();
        insert acc;
        
        List<Consentimientos__c> listConsentimientos = new List<Consentimientos__c>();
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id limit 1];
        Consentimientos__c consentimientoPersonEmail = CreaObjetos.creaConsentimientoOther(mobile, con.Id, Label.channelMobile,false);
       	listConsentimientos.add(consentimientoPersonEmail);
        insert listConsentimientos;
        
        Pais__c pais = [select Id FROM pais__c limit 1];
        
        acc.OtherMobilePhone__pc = mobile;
        acc.Pais__c = pais.Id;
        update acc;
        Test.stopTest();
        
        Consentimientos__c consentimiento = [select id, ChannelValue__c, Medio_de_contacto__c,contact__c from Consentimientos__c where contact__c = :con.Id limit 1];
    	Account cuenta = [select id, OtherMobilePhone__pc from Account where Id = :acc.Id limit 1 ];
        system.assertEquals(consentimiento.ChannelValue__c, cuenta.OtherMobilePhone__pc);
        system.assertEquals(consentimiento.Medio_de_contacto__c, Label.channelOtherMobile);
    }
    
    @isTest
    static void helperNoPersonalAccountTest() {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Email__c = '';
        acc.Other_Email__c = '';
        
        Test.startTest();
        insert acc;
        Test.stopTest();
    }
    
    @isTest
    static void deleteTest() {
        Account acc = creaObjetos.creaCuentaPersonal('Test', 'Personal');
        
        Test.startTest();
        insert acc;
        delete acc;
        Test.stopTest();
    }
}