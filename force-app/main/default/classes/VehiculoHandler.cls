public  with sharing class VehiculoHandler implements ITriggerHandler {
    private TriggerExecutionHelper infoTrigger = new TriggerExecutionHelper();
    Map<String,Cliente_Concesionario__c> mapClienteConcesionarioByExternalId = new Map<String,Cliente_Concesionario__c>();
    List<String> vehiculoIdToCalculoTarget = new List<String>();
    public VehiculoHandler(Schema.sObjectType soType) {
        InfoTrigger.setTipoHandler(soType);
    }
    
    public TriggerExecutionHelper getInfo() {
        return infoTrigger;
    }
    
    public void bulkBefore() {
        vehiculoIdToCalculoTarget.clear();
        List<String> externalCustomerIds = new List<String>();
        mapClienteConcesionarioByExternalId.clear();
        if (Trigger.new != null) {
            for (SObject objeto : Trigger.New) {
                Vehiculo__c vehiculo = (Vehiculo__c) objeto;
                if(!String.isBlank(vehiculo.PropietarioTXT__c)){
                    externalCustomerIds.add(vehiculo.PropietarioTXT__c);
                }
                if(!String.isBlank(vehiculo.CompradorTXT__c)){
                    externalCustomerIds.add(vehiculo.CompradorTXT__c);
                }
                if(!String.isBlank(vehiculo.DepositarioTXT__c)){
                    externalCustomerIds.add(vehiculo.DepositarioTXT__c);
                }
            }
            
            mapClienteConcesionarioByExternalId = ClienteConcesionarioGateway.getClienteConcesionarioByIdExternal(externalCustomerIds);
            
        }
        
        
    }
    public void bulkAfter() {
        vehiculoIdToCalculoTarget.clear();
    }

    public void beforeInsert(sObject so) {
        Vehiculo__c vehiculo = (Vehiculo__c) so;
        
        Datetime ahora = Datetime.now();
        
        if(vehiculo.Propietario__c == null && !String.isBlank(vehiculo.PropietarioTXT__c) && mapClienteConcesionarioByExternalId.containsKey(vehiculo.PropietarioTXT__c)){
            Cliente_Concesionario__c propietarioConcesionario = mapClienteConcesionarioByExternalId.get(vehiculo.PropietarioTXT__c);
            vehiculo.Propietario__c = propietarioConcesionario.Cliente__c;
            if (vehiculo.Fecha_desde_AUX__c != null){
                vehiculo.Fecha_desde__c = vehiculo.Fecha_desde_AUX__c;   
            }   
        }
        
        if(vehiculo.Comprador__c == null && !String.isBlank(vehiculo.CompradorTXT__c) && mapClienteConcesionarioByExternalId.containsKey(vehiculo.CompradorTXT__c)){
            Cliente_Concesionario__c compradorConcesionario = mapClienteConcesionarioByExternalId.get(vehiculo.CompradorTXT__c);
            vehiculo.Comprador__c = compradorConcesionario.Cliente__c;
        }

        if(vehiculo.Depositario__c == null && !String.isBlank(vehiculo.DepositarioTXT__c) && mapClienteConcesionarioByExternalId.containsKey(vehiculo.DepositarioTXT__c)){
            Cliente_Concesionario__c depositarioConcesionario = mapClienteConcesionarioByExternalId.get(vehiculo.DepositarioTXT__c);
            vehiculo.Depositario__c = depositarioConcesionario.Cliente__c;
        }

        if(vehiculo.Propietario__c == null && !String.isBlank(vehiculo.DepositarioTXT__c) && mapClienteConcesionarioByExternalId.containsKey(vehiculo.DepositarioTXT__c)){
            Cliente_Concesionario__c propietarioConcesionario = mapClienteConcesionarioByExternalId.get(vehiculo.DepositarioTXT__c);
            vehiculo.Propietario__c = propietarioConcesionario.Cliente__c;
            if (vehiculo.Fecha_desde_AUX__c != null){
                vehiculo.Fecha_desde__c = vehiculo.Fecha_desde_AUX__c;   
            }   
        }
        
        //vehiculo.RecalcularTarget__c = false;
       // if (!String.isBlank(vehiculo.MarcaString__c) && Label.BrandTarget.contains(vehiculo.MarcaString__c.toUpperCase())){
       //     vehiculo.RecalcularTarget__c = true;
       // }

        if (vehiculo.Fecha_primera_matriculacion__c != null && vehiculo.Fecha_actualizacion_kms__c != null ){
             if (vehiculo.Fecha_actualizacion_kms__c > vehiculo.Fecha_primera_matriculacion__c){ 
                 vehiculo.Dias_actualizacion_kms__c = vehiculo.Fecha_primera_matriculacion__c.date().daysBetween(vehiculo.Fecha_actualizacion_kms__c.date());
             }    
             vehiculo.kms_diarios__c = vehiculo.kms__c != null && vehiculo.Dias_actualizacion_kms__c != null &&  vehiculo.kms__c != 0 && vehiculo.Dias_actualizacion_kms__c != 0  ? vehiculo.kms__c.divide(vehiculo.Dias_actualizacion_kms__c, 0, System.RoundingMode.UP) : 0;                      
        } 
        
        
        if (!String.isBlank(vehiculo.MarcaString__c) && vehiculo.MarcaString__c.equalsIgnoreCase('HYUNDAI')) {
                	vehiculo.Fecha_cumpleanos__c =  vehiculo.Fecha_inicio_garantia__c != null ? vehiculo.Fecha_inicio_garantia__c.date().addYears(1) : null;
              		vehiculo.Numero_de_cumpleanos__c = vehiculo.Fecha_inicio_garantia__c != null ? 1:null;
                }
		

        //vehiculo.RecalcularTarget__c = false;
        ///if(vehiculo.RecalcularTarget__c){
        //    vehiculoIdToCalculoTargetBefore.add(vehiculo.Id);
        //    vehiculo.RecalcularTarget__c = false;
        //}
    }
    
    public void beforeUpdate(sObject old, sObject so) {
        Vehiculo__c vehiculo = (Vehiculo__c) so;
        Vehiculo__c vehiculoOld = (Vehiculo__c) old;
	
         
        if((vehiculo.Propietario__c == null &&!String.isBlank(vehiculo.PropietarioTXT__c) && mapClienteConcesionarioByExternalId.containsKey(vehiculo.PropietarioTXT__c))||
           (vehiculo.Propietario__c != null &&!String.isBlank(vehiculo.PropietarioTXT__c) && vehiculo.PropietarioTXT__c != vehiculoOld.PropietarioTXT__c  && mapClienteConcesionarioByExternalId.containsKey(vehiculo.PropietarioTXT__c))){
            Cliente_Concesionario__c propietarioConcesionario = mapClienteConcesionarioByExternalId.get(vehiculo.PropietarioTXT__c);
            vehiculo.Propietario__c = propietarioConcesionario.Cliente__c;
            if (vehiculo.Fecha_desde_AUX__c != null){
                vehiculo.Fecha_desde__c = vehiculo.Fecha_desde_AUX__c;   
            }   
        }
        
        if((vehiculo.Comprador__c == null && !String.isBlank(vehiculo.CompradorTXT__c) && mapClienteConcesionarioByExternalId.containsKey(vehiculo.CompradorTXT__c))||
           (vehiculo.Comprador__c != null && !String.isBlank(vehiculo.CompradorTXT__c) && vehiculoOld.CompradorTXT__c != vehiculo.CompradorTXT__c && mapClienteConcesionarioByExternalId.containsKey(vehiculo.CompradorTXT__c))){
            Cliente_Concesionario__c compradorConcesionario = mapClienteConcesionarioByExternalId.get(vehiculo.CompradorTXT__c);
            vehiculo.Comprador__c = compradorConcesionario.Cliente__c;
        }

        if(vehiculo.Depositario__c == null && !String.isBlank(vehiculo.DepositarioTXT__c) && mapClienteConcesionarioByExternalId.containsKey(vehiculo.DepositarioTXT__c)){
            Cliente_Concesionario__c depositarioConcesionario = mapClienteConcesionarioByExternalId.get(vehiculo.DepositarioTXT__c);
            vehiculo.Depositario__c = depositarioConcesionario.Cliente__c;
        }

        if(vehiculo.Propietario__c == null && !String.isBlank(vehiculo.DepositarioTXT__c) && mapClienteConcesionarioByExternalId.containsKey(vehiculo.DepositarioTXT__c)){
            Cliente_Concesionario__c propietarioConcesionario = mapClienteConcesionarioByExternalId.get(vehiculo.DepositarioTXT__c);
            vehiculo.Propietario__c = propietarioConcesionario.Cliente__c;
            if (vehiculo.Fecha_desde_AUX__c != null){
                vehiculo.Fecha_desde__c = vehiculo.Fecha_desde_AUX__c;   
            }   
        }
        
        if (!String.isBlank(vehiculoOld.ModeloString__c)){
            vehiculo.ModeloString__c = vehiculoOld.ModeloString__c;     
        }
        
        //vehiculo.RecalcularTarget__c = false;
        if (!system.isBatch() && !String.isBlank(vehiculo.MarcaString__c) && Label.BrandTarget.contains(vehiculo.MarcaString__c.toUpperCase())){
            vehiculo.RecalcularTarget__c = true;
        }
        
        if (((vehiculo.kms__c != null) && (vehiculoOld.kms__c != vehiculo.kms__c) && (UserInfo.getName() != 'Integrador Integrador'))||((vehiculo.kms__c != null) && (vehiculo.Fecha_actualizacion_kms__c == null))){
            vehiculo.Fecha_actualizacion_kms__c = Datetime.now();
        }
        
        if (vehiculo.Fecha_primera_matriculacion__c != null && vehiculo.Fecha_actualizacion_kms__c != null){
             if (vehiculo.Fecha_actualizacion_kms__c > vehiculo.Fecha_primera_matriculacion__c){ 
                 vehiculo.Dias_actualizacion_kms__c = vehiculo.Fecha_primera_matriculacion__c.date().daysBetween(vehiculo.Fecha_actualizacion_kms__c.date());
             }     
             vehiculo.kms_diarios__c  =vehiculo.kms__c  != null && vehiculo.Dias_actualizacion_kms__c!= null &&  vehiculo.kms__c != 0 && vehiculo.Dias_actualizacion_kms__c != 0  ? vehiculo.kms__c.divide(vehiculo.Dias_actualizacion_kms__c, 0, System.RoundingMode.UP) : 0;                      
        } 
		
         //   vehiculo.RecalcularTarget__c = false;
        if(vehiculo.RecalcularTarget__c){
            vehiculoIdToCalculoTarget.add(vehiculo.Id);
            vehiculo.RecalcularTarget__c = false;
        }
    }
    
    public void beforeDelete(sObject so) {}
    
    public void afterInsert(sObject so) {
        Vehiculo__c vehiculo = (Vehiculo__c) so;
        if (!String.isBlank(vehiculo.MarcaString__c) && Label.BrandTarget.contains(vehiculo.MarcaString__c.toUpperCase())){
            vehiculoIdToCalculoTarget.add(vehiculo.Id);
        }
        
    }
    
    public void afterUpdate(sObject old, sObject so) {
        
    }
    
    public void afterDelete(sObject so) {}
    
    public void andFinally() {
        
        system.debug('vehiculoIdToCalculoTarget: '+vehiculoIdToCalculoTarget);
        if(!vehiculoIdToCalculoTarget.isEmpty()){
            for (String vehiculoId: vehiculoIdToCalculoTarget) {
                 ManagerService.manageService(vehiculoId);
            }
        }
    }

}