public class LC_VehicleGuaranteeController {
    
    @AuraEnabled
    public static String getShow(String recordId){
       Map<String,Boolean> response = new Map<String,Boolean>();
        if(!String.isBlank(recordId)){
            List<Vehiculo__c> lstVehicles = [SELECT Id,Name,Concesionario__c,Propietario__c, MarcaString__c, VIN__c,kms__c,
                                             Kms_contrato_prestacion__c,Fecha_contrato_fin_e_garantia__c, Fecha_contrato_inicio_e_garantia__c,
                                             Fecha_fin_garantia__c, Fecha_inicio_garantia__c
                                     	  	FROM Vehiculo__c
                                    	  	WHERE Id = :recordId];
            if(!lstVehicles.isEmpty()){
                Vehiculo__c vehiculo = lstVehicles[0];
                response.put('respuesta',true);
                Boolean garantia = vehiculo.Fecha_inicio_garantia__c != null ? true : false;
                Boolean garantiaExt = vehiculo.Fecha_contrato_inicio_e_garantia__c != null ? true : false;
                response.put('showGarantia', garantia);
                response.put('showExtGarantia', garantiaExt);
            }
            else {
                response.put('respuesta', false);
            }
        }
        else {
            response.put('respuesta', false);
        }
        return JSON.serialize(response);
   }   
}