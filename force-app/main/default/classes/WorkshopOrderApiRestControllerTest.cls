@isTest
public class WorkshopOrderApiRestControllerTest {

     @testSetup
    static void setup() {
        TriggersTest.activaTriggers();
        Concesionario__c concess = CreaObjetos.creaConcesionario('999');
        insert concess;
        
        Account cli = CreaObjetos.creaCuentaPersonal('Prueba', 'lastname');
        insert cli;
        
        Cliente_Concesionario__c cliConcess = CreaObjetos.creaClienteConcesionario(cli.Id, concess.Id, 'c01', '999');
 	    insert cliConcess;
        
        Centro__c center = CreaObjetos.creaCentro(concess.Id);
        center.Id_Centro_Sima__c = '999-5';
        upsert center;
        
        Salesman__c salesman = new Salesman__c();
        salesman.Email__c = 'foo@bar.com';
        insert salesman;
        
        
        
    }
    
    @isTest
    static void newWorkshopOrderException501() {
        WorkshopOrderApiRestModel req = new WorkshopOrderApiRestModel();
        WorkshopOrderApiRestModel.PayLoad payload = new WorkshopOrderApiRestModel.PayLoad();
        req.payLoad = payload;
        Test.startTest();
        ResponseApi response = WorkshopOrderApiRestController.createworkshopOrder(req);
        Test.stopTest();
    }
   
    @isTest
    static void newWorkshopOrderException502() {
        WorkshopOrderApiRestModel req = new WorkshopOrderApiRestModel();
        WorkshopOrderApiRestModel.PayLoad payload = new WorkshopOrderApiRestModel.PayLoad();
        payload.workshopOrderId ='prueba1';
        payload.workshopCode ='5';
        payload.companyCode ='170';
        payload.centerCode ='1';
        req.payload = payload;
        Test.startTest();
        ResponseApi response = WorkshopOrderApiRestController.createworkshopOrder(req);
        Test.stopTest();
    }
  
    @isTest
    static void newWorkshopOrderException503() {
         WorkshopOrderApiRestModel req = new WorkshopOrderApiRestModel();
        WorkshopOrderApiRestModel.PayLoad payload = new WorkshopOrderApiRestModel.PayLoad();
        payload.workshopOrderId ='prueba1';
        payload.workshopCode ='5';
        payload.companyCode ='999';
        payload.centerCode ='5';
        payload.customerId ='c01';
        payload.customerDepositaryId ='c01';
        payload.customerOwnerId ='c01';
        req.payload = payload;
        Test.startTest();
        ResponseApi response = WorkshopOrderApiRestController.createworkshopOrder(req);
        Test.stopTest();
    }
   
    @isTest
    static void newWorkshopOrderException504() {
         WorkshopOrderApiRestModel req = new WorkshopOrderApiRestModel();
        WorkshopOrderApiRestModel.PayLoad payload = new WorkshopOrderApiRestModel.PayLoad();
        payload.workshopOrderId ='prueba1';
        payload.workshopCode ='5';
        payload.companyCode ='999';
        payload.centerCode ='5';
        payload.vin ='VIN01';
        payload.customerId ='c02';
        payload.customerDepositaryId ='c02';
        payload.customerOwnerId ='c02';
        req.payload = payload;
        Test.startTest();
        ResponseApi response = WorkshopOrderApiRestController.createworkshopOrder(req);
        Test.stopTest();
    }
   
    @isTest
    static void newWorkshopOrderException505() {
         WorkshopOrderApiRestModel req = new WorkshopOrderApiRestModel();
        WorkshopOrderApiRestModel.PayLoad payload = new WorkshopOrderApiRestModel.PayLoad();
        payload.workshopOrderId ='prueba1';
        payload.workshopCode ='5';
        payload.companyCode ='999';
        payload.centerCode ='5';
        payload.vin='VIN01';
        payload.customerId = 'c01';
        payload.customerDepositaryId ='c02';
        payload.customerOwnerId ='c01';
        req.payload = payload;
        Test.startTest();
        ResponseApi response = WorkshopOrderApiRestController.createworkshopOrder(req);
        Test.stopTest();
    }
   
     @isTest
    static void newWorkshopOrderException506() {
         WorkshopOrderApiRestModel req = new WorkshopOrderApiRestModel();
        WorkshopOrderApiRestModel.PayLoad payload = new WorkshopOrderApiRestModel.PayLoad();
        payload.workshopOrderId ='prueba1';
        payload.workshopCode ='5';
        payload.companyCode ='999';
        payload.centerCode ='5';
        payload.vin='VIN01';
        payload.customerId = 'c01';
        payload.customerDepositaryId ='c01';
        payload.customerOwnerId ='c02';
        req.payload = payload;
        Test.startTest();
        ResponseApi response = WorkshopOrderApiRestController.createworkshopOrder(req);
        Test.stopTest();
    }
   
    
}