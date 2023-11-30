public with sharing class DetalleVentaHandler implements ITriggerHandler {
    private TriggerExecutionHelper infoTrigger = new TriggerExecutionHelper();
    
    public Map<String,Vehiculo__c> mapVehiculoById = new Map<String,Vehiculo__c>();
    public Map<String,Opportunity> mapOpportunityByExternalId = new Map<String,Opportunity>();
   
    public Map<String,Vehiculo__c> mapVehiculoToUpdate = new Map<String,Vehiculo__c>();
    public Map<String, List<Detalle_Oferta__c>> mapDetalleOfertaByOpp = new Map<String,List<Detalle_Oferta__c>>();
    public Map<String,Centro__c> mapCentroById = new Map<String,Centro__c>();
    
 
    public DetalleVentaHandler(Schema.sObjectType soType) {
        InfoTrigger.setTipoHandler(soType);
    }
    
    public TriggerExecutionHelper getInfo() {
        return infoTrigger;
    }
    
    public void bulkBefore() {
        mapVehiculoById.clear();
       // mapOpportunityById.clear();
        mapDetalleOfertaByOpp.clear();
        List<String> vehiculosId = new List<String>();
        List<String> centrosId = new List<String>();
        List<String> externalSalesProcessId = new List<String>();
        
        if (Trigger.new != null) {
            for (SObject objeto : Trigger.New) {
                Detalle_venta__c dVenta = (Detalle_venta__c) objeto;
                if (dVenta.Vehiculo__c != null) {
                    vehiculosId.add(dVenta.Vehiculo__c);
                }
                if(dVenta.Centro__c != null){
                    centrosId.add(dVenta.Centro__c);
                }
                if(dVenta.Opportunity__c== null && !String.isBlank(dVenta.External_Id__c)){
                    List<String> splitExternalId = dVenta.External_Id__c.split('/');
                    if(splitExternalId != null && !splitExternalId.isEmpty()){
                        externalSalesProcessId.add(splitExternalId[0]);
                    }
                }
            }
            if(!vehiculosId.isEmpty()){
                mapVehiculoById = VehiculoGateway.getVehicleById(vehiculosId);
            }
            if(!centrosId.isEmpty()){
                mapCentroById = CentroGateway.getCenterById(centrosId);
            }
            if(!externalSalesProcessId.isEmpty()){
                mapOpportunityByExternalId = OpportunityGateway.getOppByIdVentaDMS(externalSalesProcessId);
            }
        }
       
   }

    public void bulkAfter() {
        mapVehiculoToUpdate.clear();
        List<String> vehiculosId = new List<String>();
        List<String> opportunityId = new List<String>();
       
    	if (Trigger.new != null) {
            for (SObject objeto : Trigger.New) {
                Detalle_venta__c dVenta = (Detalle_venta__c) objeto;
                if (dVenta.Vehiculo__c != null) {
                    vehiculosId.add(dVenta.Vehiculo__c);
                }
                if(dVenta.Opportunity__c != null){
                    opportunityId.add(dVenta.Opportunity__c);
                }
            }
            
            if(!vehiculosId.isEmpty() && mapVehiculoById.isEmpty() ){
                mapVehiculoById = VehiculoGateway.getVehicleById(vehiculosId);
            }
            if(!opportunityId.isEmpty()){
          //      mapOpportunityById = OpportunityGateway.getOppById(opportunityId);
                mapDetalleOfertaByOpp = DetalleOfertaGateway.getDOfertaByOppId(opportunityId);
            }
        }
    
        }

    public void beforeInsert(sObject so) {
        Detalle_venta__c dVenta =(Detalle_venta__c) so;
        List<String> splitExternalId = !String.isBlank(dVenta.External_Id__c)? dVenta.External_Id__c.split('/'):new List<String>();
        if(dVenta.Vehiculo__c != null && mapVehiculoById.containsKey(dVenta.Vehiculo__c)){
            Vehiculo__c veh = mapVehiculoById.get(dVenta.Vehiculo__c);
            dVenta.Propietario__c = dVenta.Propietario__c == null?veh.Propietario__c: dVenta.Propietario__c;
            dVenta.Comprador__c = dVenta.Comprador__c == null? veh.Comprador__c:dVenta.Comprador__c;
            if(dVenta.Centro__c != null && mapCentroById.containsKey(dVenta.Centro__c)){
                Centro__c centro = mapCentroById.get(dVenta.Centro__c);
                dVenta.Name = centro.Concesionario__r.Nombre_Comercial__c +'/'+centro.Id_Centro_Sima__c +'/'+veh.MarcaString__c +'/'+veh.VIN__c;
            }
            else {
                dVenta.Name = veh.MarcaString__c+'/'+veh.VIN__c;
            }
        }
        if(dVenta.Opportunity__c == null && !splitExternalId.isEmpty() && mapOpportunityByExternalId.containsKey(splitExternalId[0])){
            Opportunity opp = mapOpportunityByExternalId.get(splitExternalId[0]);
            dVenta.Opportunity__c = opp.Id;
            dVenta.Vendedor__c = opp.Vendedor__c;
        }
      }
    
    public void beforeUpdate(sObject old, sObject so) {
        Detalle_venta__c dVenta =(Detalle_venta__c) so;
        List<String> splitExternalId = !String.isBlank(dVenta.External_Id__c)? dVenta.External_Id__c.split('/'):new List<String>();
        if(dVenta.Vehiculo__c != null && mapVehiculoById.containsKey(dVenta.Vehiculo__c)){
            Vehiculo__c veh = mapVehiculoById.get(dVenta.Vehiculo__c);
            dVenta.Propietario__c = dVenta.Propietario__c== null ? veh.Propietario__c: dVenta.Propietario__c;
            dVenta.Comprador__c = dVenta.Comprador__c == null ? veh.Comprador__c: dVenta.Comprador__c;
            if(dVenta.Centro__c != null && mapCentroById.containsKey(dVenta.Centro__c)){
                Centro__c centro = mapCentroById.get(dVenta.Centro__c);
                dVenta.Name = centro.Concesionario__r.Nombre_Comercial__c +'/'+centro.Id_Centro_Sima__c +'/'+veh.MarcaString__c +'/'+veh.VIN__c;
            }
            else {
                dVenta.Name = veh.MarcaString__c+'/'+veh.VIN__c;
            }
        }
        if(dVenta.Opportunity__c == null && !splitExternalId.isEmpty() && mapOpportunityByExternalId.containsKey(splitExternalId[0])){
            Opportunity opp = mapOpportunityByExternalId.get(splitExternalId[0]);
            dVenta.Opportunity__c = opp.Id;
            dVenta.Vendedor__c = opp.Vendedor__c;
        }
     
       }
    
    public void beforeDelete(sObject so) {}
    
    public void afterInsert(sObject so) {
    	Detalle_venta__c dVenta = (Detalle_venta__c) so;
        if(dVenta.Vehiculo__c != null && mapVehiculoById.containsKey(dVenta.Vehiculo__c) 
           && dVenta.Opportunity__c != null && mapDetalleOfertaByOpp.containsKey(dVenta.Opportunity__c)  ){
            Vehiculo__c veh = mapVehiculoById.get(dVenta.Vehiculo__c);
            Vehiculo__c vehiculoToUpdate;
            List<Detalle_Oferta__c> listDOferta = mapDetalleOfertaByOpp.get(dVenta.Opportunity__c);
            for(Detalle_Oferta__c dOferta : listDOferta){
            	if(!String.isBlank(dOferta.vin__c) && dOferta.vin__c.equalsIgnoreCase(veh.VIN__c)){
                	vehiculoToUpdate = new Vehiculo__c();
                    vehiculoToUpdate.Id = veh.Id;
                    vehiculoToUpdate.Accesories__c = dOferta.Accessories__c;
                    vehiculoToUpdate.Services__c = dOferta.Services__c;
                    vehiculoToUpdate.equipments__c = dOferta.Equipment__c;
                    break;
                 }
            }
            if(vehiculoToUpdate != null){
            	mapVehiculoToUpdate.put(vehiculoToUpdate.Id, vehiculoToUpdate);
            }
       	}
    }
    
    public void afterUpdate(sObject old, sObject so) {
      }
    
    public void afterDelete(sObject so) {}
    
    public void andFinally() {
        
        if(!mapVehiculoToUpdate.isEmpty()){
            update mapVehiculoToUpdate.values();
        }
    }
}