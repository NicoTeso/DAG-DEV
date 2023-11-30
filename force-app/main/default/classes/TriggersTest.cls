@isTest
public class TriggersTest {

    public static void activaTriggers(){
        Triggers__c triggers = new Triggers__c();
        triggers.AuxAccountTrigger__c = true;
        triggers.AuxConsentimientoTrigger__c = true;
        triggers.AccountTrigger__c = true;
        triggers.CaseTrigger__c = true;
        triggers.ChatTranscriptTrigger__c = true;
        triggers.ConsentimientoTrigger__c = true;
        triggers.TaskTrigger__c = true;
        triggers.DetalleVentaTrigger__c = true;
        triggers.VehiculoTrigger__c = true;
        triggers.EncuestaTrigger__c = true;
        triggers.PaseTallerTrigger__c = true;
        insert triggers; 
   }
}