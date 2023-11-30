public class LC_vehicleCampaignsController {

    @AuraEnabled
    public static String getCampaignsByVehicle(String recordId){
        List<Campania_Vehiculo__c> campanias = new List<Campania_Vehiculo__c>();
        if(!String.isBlank(recordId)){
            campanias = [select Id, Name, Vehiculo__c, Codigo__c, Tipo__c, Descripcion__c from Campania_Vehiculo__c
                        where Vehiculo__c = :recordId];
        }
        return JSON.serialize(campanias);
    }
}