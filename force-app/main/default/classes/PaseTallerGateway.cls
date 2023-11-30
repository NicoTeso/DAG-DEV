public class PaseTallerGateway {
    
     public static Pase_de_taller__c getPaseTallerById(String id) {
        Pase_de_taller__c paseTaller;
        
        if (!String.isBlank(id)) {
            Map<String, Pase_de_taller__c> mapIdToPaseTaller = getPaseTallerById(new List<String>{id});
            paseTaller = mapIdToPaseTaller.containsKey(id) ? mapIdToPaseTaller.get(id) : null;
        }
        
        return paseTaller;
    }
    
    public static Map<String, Pase_de_taller__c> getPaseTallerById(List<String> lstIds) {
        Map<String, Pase_de_taller__c> mapIdToPaseTaller = new Map<String, Pase_de_taller__c>();
        
        if (!lstIds.isEmpty()) {
            for (Pase_de_taller__c paseTaller : [SELECT Id, Name, Concesionario__c, Centro__c, workshopOrderId__c, creationDate__c, receptionDate__c, deliveryDate__c, Vehiculo__c,
                                                 customerDepositary__c, customer__c, customerOwner__c, customerAmount__c, insuranceAmount__c, internalAmount__c,
                                                 warrantyAmount__c, deferenceAmount__c, campaignAmount__c, currencyType__c, serviceAdviser__c, workshopCode__c, kms__c, 
                                                 Centro__r.Activo__c, 
                                                 Centro__r.Gestiona_LEAD__c,
                                                 customerDepositary__r.Name
                                                 FROM Pase_de_taller__c
                                                WHERE Id in :lstIds LIMIT 2000]) {
                
                mapIdToPaseTaller.put(paseTaller.Id, paseTaller);
            }
        }
        
        return mapIdToPaseTaller;
    }
    
    public static Pase_de_taller__c getLastPaseTallerByVehiculoId(String vehiculoId){
        Pase_de_taller__c paseTaller;
        if(!String.isBlank(vehiculoId)){
            Map<String, Pase_de_taller__c> mapGetLastPaseTallerByVehiculo = PaseTallerGateway.getLastPaseTallerByVehiculoId(new Set<String> {vehiculoId});
            if(!mapGetLastPaseTallerByVehiculo.isEmpty() && mapGetLastPaseTallerByVehiculo.containsKey(vehiculoId)){
                paseTaller = mapGetLastPaseTallerByVehiculo.get(vehiculoId);
            }
        }
        
        return paseTaller;
    }
    public static Map<String, Pase_de_taller__c> getLastPaseTallerByVehiculoId(Set<String> vehiculoIds){
        Map<String,Pase_De_taller__c> mapLastPaseTallerByVehiculo = new Map<String,Pase_de_taller__c>();
        for(Pase_de_taller__c pTaller :[Select Id, Name, Concesionario__c, Centro__c, workshopOrderId__c, creationDate__c, deliveryDate__c, Vehiculo__c, customerDepositary__c, customer__c, customerOwner__c, customerAmount__c,
                                        insuranceAmount__c, internalAmount__c, warrantyAmount__c, deferenceAmount__c, campaignAmount__c, currencyType__c, serviceAdviser__c, workshopCode__c, workshopDescription__c, kms__c, receptionDate__c 
                                        From Pase_de_taller__c
                                        Where Vehiculo__c in :vehiculoIds AND CreatedDate >LAST_N_MONTHS:1 order by creationDate__c desc]){
         	if(!mapLastPaseTallerByVehiculo.containsKey(pTaller.Vehiculo__c)){
            	mapLastPaseTallerByVehiculo.put(pTaller.Vehiculo__c, pTaller);                               
            }
        }
        return mapLastPaseTallerByVehiculo;
    }
   
}