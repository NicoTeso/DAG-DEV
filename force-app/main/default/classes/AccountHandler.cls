public with sharing class AccountHandler implements ITriggerHandler {
    private TriggerExecutionHelper infoTrigger = new TriggerExecutionHelper();
    
    public Map<String, Pais__c> mapPaisById = new Map<String, Pais__c>();
    public Map<String, Map<String, Consentimientos__c>> mapConsentimientoValueByAccountId = new Map<String,Map<String, Consentimientos__c>>();
   	public Map<String, Map<String, Consentimientos__c>> mapConsentimientoValueByAccountIdToUpdate = new Map<String, Map<String, Consentimientos__c>>();
    
    public AccountHandler(Schema.sObjectType soType) {
        InfoTrigger.setTipoHandler(soType);
    }
    
    public TriggerExecutionHelper getInfo() {
        return infoTrigger;
    }
    
    public void bulkBefore() {
        mapPaisById.clear();
        List<String> paisesId = new List<String>();
        
        if (Trigger.new != null) {
            for (SObject objeto : Trigger.New) {
                Account cuenta = (Account) objeto;
                
                if (cuenta.Pais__c != null) {
                    paisesId.add(cuenta.Pais__c);
                }
            }
        }
        
        mapPaisById = PaisGateway.getPaisById(paisesId);
    }

    public void bulkAfter() {
        mapConsentimientoValueByAccountId.clear();
        mapConsentimientoValueByAccountIdToUpdate.clear();
        
        if (Trigger.new != null) {
            List<String> listId = new List<String>();
            
            for (SObject objeto : Trigger.New) {
                Account cuenta = (Account) objeto;
                listId.add(cuenta.Id);
            }
            
            mapConsentimientoValueByAccountId = ConsentimientosGateway.getConsentimientosByAccountId(listId);
        }
    }

    public void beforeInsert(sObject so) {
        System.debug('BEFORE INSERT');
        Account acc = (Account) so;
        AccountHelper.validationsBefore(acc, mapPaisById);
        AccountHelper.transformationsBefore(acc);
    }
    
    public void beforeUpdate(sObject old, sObject so) {
        System.debug('BEFORE UPDATE');
        Account acc = (Account) so;
        AccountHelper.validationsBefore(acc, mapPaisById);
        AccountHelper.transformationsBefore(acc);
    }
    
    public void beforeDelete(sObject so) {}
    
    public void afterInsert(sObject so) {
        Account cuenta = (Account) so;
       	String recordTypeDeveloperName = AccountGateway.getRecordTypeDeveloperNameById(cuenta.RecordTypeId);
        System.debug('recordTypeDeveloperName: ' + recordTypeDeveloperName);
        
        
    }
    
    public void afterUpdate(sObject old, sObject so) {
        Account cuenta = (Account) so;
       	String recordTypeDeveloperName = AccountGateway.getRecordTypeDeveloperNameById(cuenta.RecordTypeId);
        System.debug('recordTypeDeveloperName:'+ recordTypeDeveloperName);
        
        if (Label.RtAccountPerson.equalsIgnoreCase(recordTypeDeveloperName)) {
        	System.debug('mapConsentimientoValueByAccountId: ' + mapConsentimientoValueByAccountId);
            
            //Consentimientos
            if (mapConsentimientoValueByAccountId.containsKey(cuenta.Id)) {
                Map<String, Consentimientos__c> mapConsentimientoByValue = mapConsentimientoValueByAccountId.get(cuenta.Id);
                
                //Email
                if (!String.isBlank(cuenta.PersonEmail) && mapConsentimientoByValue.containsKey(cuenta.PersonEmail)) {
                    Consentimientos__c consentimiento = mapConsentimientoByValue.get(cuenta.PersonEmail);
                    
                    if (consentimiento != null && !Label.channelEmail.equalsIgnoreCase(consentimiento.Medio_de_contacto__c)) {
                        Map<String,Consentimientos__c> mapConsentimientoByValueToUpdate = mapConsentimientoValueByAccountIdToUpdate.containsKey(cuenta.Id)
                            ? mapConsentimientoValueByAccountIdToUpdate.get(cuenta.Id) : new Map<String, Consentimientos__c>();
                        Consentimientos__c consentimientosToUpdate = mapConsentimientoByValueToUpdate.containsKey(cuenta.PersonEmail)
                            ? mapConsentimientoByValueToUpdate.get(cuenta.PersonEmail) : new Consentimientos__c();
                        consentimientosToUpdate.Id = consentimiento.Id;
                        consentimientosToUpdate.Medio_de_contacto__c = Label.channelEmail;
                        mapConsentimientoByValueToUpdate.put(cuenta.PersonEmail, consentimientosToUpdate);
                        mapConsentimientoValueByAccountIdToUpdate.put(cuenta.Id, mapConsentimientoByValueToUpdate);
                    }
                }
                
                //Telefono
                if (!String.isBlank(cuenta.Phone) && mapConsentimientoByValue.containsKey(cuenta.Phone)){
                    Consentimientos__c consentimiento = mapConsentimientoByValue.get(cuenta.Phone);
                    if(consentimiento != null && !Label.channelPhone.equalsIgnoreCase(consentimiento.Medio_de_contacto__c)){
                        Map<String,Consentimientos__c> mapConsentimientoByValueToUpdate = mapConsentimientoValueByAccountIdToUpdate.containsKey(cuenta.Id) ? mapConsentimientoValueByAccountIdToUpdate.get(cuenta.Id):new Map<String,Consentimientos__c>();
                        Consentimientos__c consentimientosToUpdate = mapConsentimientoByValueToUpdate.containsKey(cuenta.Phone) ? mapConsentimientoByValueToUpdate.get(cuenta.Phone):new Consentimientos__c();
                        consentimientosToUpdate.Id = consentimiento.Id;
                        consentimientosToUpdate.Medio_de_contacto__c = Label.channelPhone;
                        mapConsentimientoByValueToUpdate.put(cuenta.Phone, consentimientosToUpdate);
                        mapConsentimientoValueByAccountIdToUpdate.put(cuenta.Id, mapConsentimientoByValueToUpdate);
                    }
                }
                
                //Movil
				if (!String.isBlank(cuenta.PersonMobilePhone) && mapConsentimientoByValue.containsKey(cuenta.PersonMobilePhone)) {
                    Consentimientos__c consentimiento = mapConsentimientoByValue.get(cuenta.PersonMobilePhone);
                    
                    if (consentimiento != null && !Label.channelMobile.equalsIgnoreCase(consentimiento.Medio_de_contacto__c)) {
                        Map<String, Consentimientos__c> mapConsentimientoByValueToUpdate = mapConsentimientoValueByAccountIdToUpdate.containsKey(cuenta.Id)
                            ? mapConsentimientoValueByAccountIdToUpdate.get(cuenta.Id) : new Map<String,Consentimientos__c>();
                        Consentimientos__c consentimientosToUpdate = mapConsentimientoByValueToUpdate.containsKey(cuenta.PersonMobilePhone)
                            ? mapConsentimientoByValueToUpdate.get(cuenta.PersonMobilePhone) : new Consentimientos__c();
                        consentimientosToUpdate.Id = consentimiento.Id;
                        consentimientosToUpdate.Medio_de_contacto__c = Label.channelMobile;
                        mapConsentimientoByValueToUpdate.put(cuenta.PersonMobilePhone, consentimientosToUpdate);
                        mapConsentimientoValueByAccountIdToUpdate.put(cuenta.Id, mapConsentimientoByValueToUpdate);
                    }
                }
                
                //Otro Email
                if (!String.isBlank(cuenta.OtherEmail__pc) && mapConsentimientoByValue.containsKey(cuenta.OtherEmail__pc)) {
                    Consentimientos__c consentimiento = mapConsentimientoByValue.get(cuenta.OtherEmail__pc);
                    
                    if (consentimiento != null && !Label.channelOtherEmail.equalsIgnoreCase(consentimiento.Medio_de_contacto__c)) {
                        Map<String,Consentimientos__c> mapConsentimientoByValueToUpdate = mapConsentimientoValueByAccountIdToUpdate.containsKey(cuenta.Id)
                            ? mapConsentimientoValueByAccountIdToUpdate.get(cuenta.Id) : new Map<String,Consentimientos__c>();
                        Consentimientos__c consentimientosToUpdate = mapConsentimientoByValueToUpdate.containsKey(cuenta.OtherEmail__pc)
                            ? mapConsentimientoByValueToUpdate.get(cuenta.OtherEmail__pc) : new Consentimientos__c();
                        consentimientosToUpdate.Id = consentimiento.Id;
                        consentimientosToUpdate.Medio_de_contacto__c = Label.channelOtherEmail;
                        mapConsentimientoByValueToUpdate.put(cuenta.OtherEmail__pc, consentimientosToUpdate);
                        mapConsentimientoValueByAccountIdToUpdate.put(cuenta.Id, mapConsentimientoByValueToUpdate);
                    }
                }
                
                //Otro telefono
                if (!String.isBlank(cuenta.PersonOtherPhone) && mapConsentimientoByValue.containsKey(cuenta.PersonOtherPhone)) {
                    Consentimientos__c consentimiento = mapConsentimientoByValue.get(cuenta.PersonOtherPhone);
                    
                    if (consentimiento != null && !Label.channelOtherPhone.equalsIgnoreCase(consentimiento.Medio_de_contacto__c)) {
                        Map<String,Consentimientos__c> mapConsentimientoByValueToUpdate = mapConsentimientoValueByAccountIdToUpdate.containsKey(cuenta.Id)
                            ? mapConsentimientoValueByAccountIdToUpdate.get(cuenta.Id) : new Map<String,Consentimientos__c>();
                        Consentimientos__c consentimientosToUpdate = mapConsentimientoByValueToUpdate.containsKey(cuenta.PersonOtherPhone)
                            ? mapConsentimientoByValueToUpdate.get(cuenta.PersonOtherPhone) : new Consentimientos__c();
                        consentimientosToUpdate.Id = consentimiento.Id;
                        consentimientosToUpdate.Medio_de_contacto__c = Label.channelOtherPhone;
                        mapConsentimientoByValueToUpdate.put(cuenta.PersonOtherPhone, consentimientosToUpdate);
                        mapConsentimientoValueByAccountIdToUpdate.put(cuenta.Id, mapConsentimientoByValueToUpdate);
                    }
                }
                
                //Otro movil
                if (!String.isBlank(cuenta.OtherMobilePhone__pc) && mapConsentimientoByValue.containsKey(cuenta.OtherMobilePhone__pc)) {
                    Consentimientos__c consentimiento = mapConsentimientoByValue.get(cuenta.OtherMobilePhone__pc);
                    
                    if (consentimiento != null && !Label.channelOtherMobile.equalsIgnoreCase(consentimiento.Medio_de_contacto__c)) {
                        Map<String,Consentimientos__c> mapConsentimientoByValueToUpdate = mapConsentimientoValueByAccountIdToUpdate.containsKey(cuenta.Id)
                            ? mapConsentimientoValueByAccountIdToUpdate.get(cuenta.Id) : new Map<String,Consentimientos__c>();
                        Consentimientos__c consentimientosToUpdate = mapConsentimientoByValueToUpdate.containsKey(cuenta.OtherMobilePhone__pc)
                            ? mapConsentimientoByValueToUpdate.get(cuenta.OtherMobilePhone__pc) : new Consentimientos__c();
                        consentimientosToUpdate.Id = consentimiento.Id;
                        consentimientosToUpdate.Medio_de_contacto__c = Label.channelOtherMobile;
                        mapConsentimientoByValueToUpdate.put(cuenta.OtherMobilePhone__pc, consentimientosToUpdate);
                        mapConsentimientoValueByAccountIdToUpdate.put(cuenta.Id, mapConsentimientoByValueToUpdate);
                    }
                }
            }
        }
    }
    
    public void afterDelete(sObject so) {}
    
    public void andFinally() {
        if (!mapConsentimientoValueByAccountIdToUpdate.isEmpty()) {
            List<Consentimientos__c> listConsentimientoTOUpdate = new List<Consentimientos__c>();
            
            for (String accountId : mapConsentimientoValueByAccountIdToUpdate.keySet()) {
                Map<String, Consentimientos__c> mapConsentimientoByValue = mapConsentimientoValueByAccountIdToUpdate.get(accountId);
            	System.debug('mapConsentimientoByValue: ' + mapConsentimientoByValue);
                listConsentimientoTOUpdate.addAll(mapConsentimientoByValue.values());
            }
            
            update listConsentimientoTOUpdate;
        }
    }
}