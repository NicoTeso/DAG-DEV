@isTest
public class CaseHandler_Test {
    @testSetup
    static void setup() {
        TriggersTest.activaTriggers();
        CreaObjetos.creaPais();
        
        Account acc = CreaObjetos.creaCuentaPersonal('CaseTest', 'Personal');
        acc.PersonEmail = 'pruebaotheremail@test.com';
        acc.OtherEmail__pc = 'pruebaemail@test.com';
        acc.Phone ='999999999';
        acc.PersonMobilePhone = '699999999';
        insert acc;
        
        Concesionario__c conces = CreaObjetos.creaConcesionario('A000001');
        conces.Domicilio__c = 'Test domicilio';
        conces.CIF__c = '123123123';
        insert conces;
        Concesionario__c conces02 = CreaObjetos.creaConcesionario('A0002NO');
        conces02.Es_SIMA__c= false;
        conces02.Domicilio__c ='prueba';
        insert conces02;
        
        Centro__c center = new Centro__c();
        center.Name = 'Centro01';
        center.Concesionario__c = conces.Id;
        center.Gestiona_LEAD__c = true;
        insert center;

        Centro__c center02 = new Centro__c();
        center02.Name = 'Centro02';
        center02.Concesionario__c = conces02.Id;
        center02.Gestiona_LEAD__c = true;
        insert center02;
        
        Gestion_Lead__c gLead = new Gestion_Lead__c();
        gLead.Centro__c = center.Id;
        gLead.Marca__c = 'AUDI';
        gLead.Intencion_de_compra__c = 'Prueba';
        gLead.Gestor_Lead__c = 'CC';
        gLead.Origen__c = 'Landing';
        gLead.RecordTypeId = Schema.SObjectType.Gestion_Lead__c.getRecordTypeInfosByDeveloperName().get('Gestion_Lead_VN').getRecordTypeId();
        
        insert gLead;
        
        Gestion_Lead__c gLead02 = new Gestion_Lead__c();
        gLead02.Centro__c = center02.Id;
        gLead02.Marca__c = 'AUDI';
        gLead02.Intencion_de_compra__c = 'Prueba';
        gLead02.Gestor_Lead__c = 'CC';
        gLead02.Origen__c = 'Landing';
        gLead02.RecordTypeId = Schema.SObjectType.Gestion_Lead__c.getRecordTypeInfosByDeveloperName().get('Gestion_Lead_VN').getRecordTypeId();
        insert gLead02;

        Gestion_Lead__c gLead03 = new Gestion_Lead__c();
        gLead03.Centro__c = center.Id;
        gLead03.Intencion_de_compra__c = 'Financiar';
        gLead03.Gestor_Lead__c = 'CC';
        gLead03.Origen__c = 'e-commerce';
        gLead03.RecordTypeId = Schema.SObjectType.Gestion_Lead__c.getRecordTypeInfosByDeveloperName().get('Gestion_Lead_VO').getRecordTypeId();
        insert gLead03;
        
        Campaign camp = new Campaign();
        camp.Name = 'CampaginTest';
        insert camp;
        
        Lead le = new Lead();
        le.LastName = 'CaseLead';
        insert le;
    }
    
    @isTest
    static void ConsentLeadIdInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        
        Case ca = new Case();
        //ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Web';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        List<Consentimientos__c> lstConsents = new List<Consentimientos__c>();
        Consentimientos__c consentPersonEmail = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, Label.channelEmail);
        consentPersonEmail.Lead__c = le.Id;
        lstConsents.add(consentPersonEmail);
        Consentimientos__c consentPersonOtherEmail = CreaObjetos.creaConsentimientoOther(acc.OtherEmail__pc, con.Id, Label.channelEmail,false);
        consentPersonOtherEmail.Lead__c = le.Id;
        lstConsents.add(consentPersonOtherEmail);
        
        Test.startTest();
        insert lstConsents;
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        Test.stopTest();
    }
    
    @isTest
    static void ConsentNoLeadIdInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Consentimientos__c consentimiento = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, 'Email');
        SYSTEM.debug('consentimeitno:' + consentimiento);
        insert consentimiento;
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Web';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }
//inma
    @isTest
    static void FriendANoLeadIdInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id, Concesionario__c  FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Consentimientos__c consentimiento = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, 'Email');
        SYSTEM.debug('consentimeitno:' + consentimiento);
        insert consentimiento;

        Salesman__c salesman = new Salesman__c();
        salesman.Email__c = 'foo@bar.com';
        insert salesman;
        
        Opportunity opp = CreaObjetos.creaOportunidad(acc.Id, center.Concesionario__c, center.Id, 'tesrop1' );
        opp.Vendedor__c = salesman.Id;
        opp.Name = 'test/opp';
        insert opp;        
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Landing';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.RecommendBy__c = opp.Id;
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }

    @isTest
    static void FriendBNoLeadIdInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id, Concesionario__c  FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Consentimientos__c consentimiento = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, 'Email');
        SYSTEM.debug('consentimeitno:' + consentimiento);
        insert consentimiento;

        Salesman__c salesman = new Salesman__c();
        salesman.Email__c = 'foo@bar.com';
        insert salesman;
        
        Opportunity opp = CreaObjetos.creaOportunidad(acc.Id, center.Concesionario__c, center.Id, 'tesrop1' );
        opp.Vendedor__c = salesman.Id;
        opp.Name = 'test/opp';
        insert opp;        
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Landing';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.RecommendBy__c = opp.Id;
        ca.Description = 'trae a un amigo';
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }

    @isTest
    static void FriendCNoLeadIdInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id, Concesionario__c  FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Consentimientos__c consentimiento = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, 'Email');
        SYSTEM.debug('consentimeitno:' + consentimiento);
        insert consentimiento;

        Salesman__c salesman = new Salesman__c();
        salesman.Email__c = 'foo@bar.com';
        insert salesman;
        
        Opportunity opp = CreaObjetos.creaOportunidad(acc.Id, center.Concesionario__c, center.Id, 'tesrop1' );
        opp.Vendedor__c = salesman.Id;
        opp.Name = 'test/opp';
        insert opp;        
        
        Vehiculo__c vehicle = CreaObjetos.creaVehiculo('VIN01', acc.Id, 'HYUNDAI', 'E9887YYJ');
        insert vehicle; 
        
        Detalle_venta__c detV = CreaObjetos.creaDetalleVenta(center.Concesionario__c, center.Id, vehicle.Id);
        detV.Opportunity__c = opp.Id;
        detV.Vendedor__c = salesman.Id;
        detV.Comprador__c = acc.Id;
        detV.Propietario__c = acc.Id;
        
        insert detV;        
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Landing';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.RecommendBy__c = opp.Id;
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }

    @isTest
    static void FriendDNoLeadIdInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id, Concesionario__c  FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Consentimientos__c consentimiento = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, 'Email');
        SYSTEM.debug('consentimeitno:' + consentimiento);
        insert consentimiento;

        Salesman__c salesman = new Salesman__c();
        salesman.Email__c = 'foo@bar.com';
        insert salesman;
        
        Opportunity opp = CreaObjetos.creaOportunidad(acc.Id, center.Concesionario__c, center.Id, 'tesrop1' );
        opp.Vendedor__c = salesman.Id;
        opp.Name = 'test/opp';
        insert opp;        
        
        Vehiculo__c vehicle = CreaObjetos.creaVehiculo('VIN01', acc.Id, 'HYUNDAI', 'E9887YYJ');
        insert vehicle; 
        
        Detalle_venta__c detV = CreaObjetos.creaDetalleVenta(center.Concesionario__c, center.Id, vehicle.Id);
        detV.Opportunity__c = opp.Id;
        detV.Vendedor__c = salesman.Id;
        detV.Comprador__c = acc.Id;
        detV.Propietario__c = acc.Id;
        
        insert detV;        
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Landing';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.RecommendBy__c = opp.Id;
        ca.Description = 'trae a un amigo';
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }

    @isTest
    static void SorteoNoLeadIdInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id, Concesionario__c  FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Consentimientos__c consentimiento = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, 'Email');
        SYSTEM.debug('consentimeitno:' + consentimiento);
        insert consentimiento;
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Landing';
        ca.Intencion_de_compra__c = 'Sorteo';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.Description = 'trae a un amigo';
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }
//inma1
    @isTest
    static void EmailNoLeadIdInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id, Concesionario__c  FROM Centro__c WHERE Name = 'Centro02' LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Consentimientos__c consentimiento = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, 'Email');
        SYSTEM.debug('consentimeitno:' + consentimiento);
        insert consentimiento;
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Landing';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.Description = 'trae a un amigo';
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }

    @isTest
    static void EmailVONoLeadIdInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id, Concesionario__c  FROM Centro__c WHERE Name = 'Centro01' LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Consentimientos__c consentimiento = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, 'Email');
        SYSTEM.debug('consentimeitno:' + consentimiento);
        insert consentimiento;
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='e-commerce';
        ca.Intencion_de_compra__c = 'Financiar';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.Description = 'trae a un amigo';
        ca.brandVO__c = 'AUDI';
        ca.modelVO__c = 'A1';    
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead_VO').getRecordTypeId();
        
        System.debug('Inma1-caso:'+ca);
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }
    
//inma
    
     @isTest
    static void ConsentAccountIdNewInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        
        Case ca = new Case();
        ca.AccountId = acc.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Web';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }
    
     @isTest
    static void ConsentChangeAccountInMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        
        Case ca = new Case();
        ca.Lead__c = le.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Web';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        ca.AccountId = acc.Id;
        ca.Lead__c = null;
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }
    
     @isTest
    static void ConsentChangeAccount2InMapTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Consentimientos__c consentimiento = CreaObjetos.creaConsentimiento(acc.PersonEmail, con.Id, 'Email');
        SYSTEM.debug('consentimeitno:' + consentimiento);
        insert consentimiento;
        
        
        Case ca = new Case();
        ca.Lead__c = le.Id;
        ca.Centro__c = center.Id;
        ca.Marca__c = 'AUDI';
        ca.Origin ='Web';
        ca.Intencion_de_compra__c = 'Prueba';
        ca.Campana__c = camp.Id;
        //ca.Lead__c = le.Id;
        ca.SuppliedPhone = '918887765';
        ca.SuppliedEmail = 'case@test.com';
        ca.EnvioMulesoft__c = 'OK';
        ca.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Gestion_de_Lead').getRecordTypeId();
        
        
        Test.startTest();
        insert ca;        
        
        ca.SuppliedPhone = '918887766';
        ca.AccountId = acc.Id;
        ca.Lead__c = null;
        update ca;
        
        System.debug('===>CASE: ' + ca);
        
        //delete ca;
        Test.stopTest();
    }
    
   
    
    @isTest
    static void InvalidPhoneTest() {
        Case ca = new Case();
        
        Test.startTest();        
        ca.SuppliedPhone = '555';
        //ca.SuppliedEmail = 'invalid';
        insert ca;
        Test.stopTest();
    }
    
    @isTest
    static void DeleteTest() {
        Case ca = new Case();
        
        Test.startTest();        
        insert ca;
        delete ca;
        Test.stopTest();
    }
    
    @isTest
    static void CasoReservaFeriaAvisCanceladoVOTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Case caso = new Case();
        caso.Centro__c = center.Id;
        caso.Marca__c = 'AUDI';
        caso.Origin =Label.origenFeriaAvis;
        caso.Intencion_de_compra__c = Label.IntencionCReserva;
        caso.Campana__c = camp.Id;
        caso.Lead__c = le.Id;
        caso.SuppliedPhone = '918887765';
        caso.SuppliedEmail = 'case@test.com';
        caso.bookingStatus__c = 'Cancelado';
        caso.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.RtCaseGestionLeadVO).getRecordTypeId();
        
        Test.startTest();
        insert caso;        
        Test.stopTest();
        Case casoComprobacion = [select id, status, Motivo_de_cierre__c from Case where id = :caso.Id];
        system.debug('caso:'+ casoComprobacion);
    }
   
    @isTest
    static void CasoReservaFeriaAvisPagoRealizadoVOTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Case caso = new Case();
        caso.Centro__c = center.Id;
        caso.Marca__c = 'AUDI';
        caso.Origin = Label.origenFeriaAvis;
        caso.Intencion_de_compra__c = Label.IntencionCReserva;
        caso.Campana__c = camp.Id;
        caso.Lead__c = le.Id;
        caso.SuppliedPhone = '918887765';
        caso.SuppliedEmail = 'case@test.com';
        caso.bookingStatus__c = 'Pago realizado';
        caso.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.RtCaseGestionLeadVO).getRecordTypeId();
        
        Test.startTest();
        insert caso;        
        Test.stopTest();
        Case casoComprobacion = [select id, status, Motivo_de_cierre__c from Case where id = :caso.Id];
        system.debug('caso:'+ casoComprobacion);
    }
    
    @isTest
    static void CasoInformacionFeriaAvisVOTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Case caso = new Case();
        caso.Centro__c = center.Id;
        caso.Marca__c = 'AUDI';
        caso.Origin =Label.origenFeriaAvis;
        caso.Intencion_de_compra__c = Label.IntencionCInformacion;
        caso.Campana__c = camp.Id;
        caso.Lead__c = le.Id;
        caso.SuppliedPhone = '918887765';
        caso.SuppliedEmail = 'case@test.com';
        caso.bookingStatus__c = 'Pago realizado';
        caso.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.RtCaseGestionLeadVO).getRecordTypeId();
        
        Test.startTest();
        insert caso;        
        Test.stopTest();
        Case casoComprobacion = [select id, status, Motivo_de_cierre__c from Case where id = :caso.Id limit 1];
        system.debug('caso:'+ casoComprobacion);
    }
    
    @isTest
    static void CasoConcesionarioExternoVOTest() {
        Account acc = [SELECT Id, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone FROM Account LIMIT 1];
        Centro__c center = [SELECT Id FROM Centro__c LIMIT 1];
        Campaign camp = [SELECT Id FROM Campaign LIMIT 1];
        Concesionario__c concess = [select id FROM Concesionario__c where Id_Concesionario_Sima__c = :'A0002NO' LIMIT 1];
        Lead le = [SELECT Id FROM Lead LIMIT 1];
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        
        Case caso = new Case();
        caso.Centro__c = center.Id;
        caso.Marca__c = 'AUDI';
        caso.Origin ='Email';
        caso.Intencion_de_compra__c = 'Reserva';
        caso.Campana__c = camp.Id;
        caso.Lead__c = le.Id;
        caso.SuppliedPhone = '918887765';
        caso.SuppliedEmail = 'case@test.com';
        caso.Propietario_Vehiculo__c = concess.Id;
        caso.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.RtCaseGestionLeadVO).getRecordTypeId();
        
        Test.startTest();
        insert caso;        
        Test.stopTest();
        Case casoComprobacion = [select id, status, Motivo_de_cierre__c from Case where id = :caso.Id];
        system.debug('caso:'+ casoComprobacion);
    }
   
    
   
}