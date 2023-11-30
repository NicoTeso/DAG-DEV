public class ConsentimientoHelper {
	public static Map<String, Map<String, Consentimientos__c>> mapConsents = new Map<String, Map<String, Consentimientos__c>>();
    
    public static void createMap() {
        if (Trigger.new != null) {
            List<String> lstContactId = new List<String>();
            
            for (SObject so : Trigger.new) {
                Consentimientos__c consent = (Consentimientos__c) so;
                
                if (!String.isBlank(consent.Contact__c)) {
                    lstContactId.add(consent.Contact__c);
                }                
            }
            
            List<Consentimientos__c> lstConsents = [SELECT Id, ChannelValue__c, Contact__c FROM Consentimientos__c WHERE Contact__c IN :lstContactId];
            Map<String, Consentimientos__c> mapInner;
            
            for (Consentimientos__c consent : lstConsents) {
                mapInner = mapConsents.containsKey(consent.Contact__c) ? mapConsents.get(consent.Contact__c) : new Map<String, Consentimientos__c>();
                mapInner.put(consent.ChannelValue__c, consent);
                mapConsents.put(consent.Contact__c, mapInner);
            }
        }
    }
	/*
    public static void verifyConsentChannelValue(Consentimientos__c consent) {
        if (mapConsents.containsKey(consent.Contact__c)) {
            Map<String, Consentimientos__c> mapAux = mapConsents.get(consent.Contact__c);
            
            if (!mapAux.containsKey(consent.ChannelValue__c)) {
                throw new CustomException('');
            }
        }
    }
 	*/
    public static void validationsBefore(Consentimientos__c consent) {
        Map<Id, Schema.RecordTypeInfo> rtMapConsentimientoById = Schema.SObjectType.Consentimientos__c.getRecordTypeInfosById();
        String rtName = rtMapConsentimientoById.get(consent.RecordTypeId).getDeveloperName();
        system.debug('emailCOnsent:'+ consent.ChannelValue__c);
        
        if (rtName.equalsIgnoreCase('Email')
            && !DataValidations.validateEmail(consent.ChannelValue__c)) {
            consent.addError('No es un email válido');
        }
        else if (rtName.equalsIgnoreCase('Telefono') 
                 && (!DataValidations.validatePhone(consent.ChannelValue__c) || DataValidations.isMobile(consent.ChannelValue__c)) ) {
            consent.addError('No es un teléfono válido');
        }
        else if (rtName.equalsIgnoreCase('Movil')
                 && (!DataValidations.validatePhone(consent.ChannelValue__c) || !DataValidations.isMobile(consent.ChannelValue__c))) {
            consent.addError('No es un móvil válido');
        }
        
        //verificar que no este creado 
    }
    
    public static void transformationsBefore(Consentimientos__c consent) {
        Map<Id, Schema.RecordTypeInfo> rtMapConsentimientoById = Schema.SObjectType.Consentimientos__c.getRecordTypeInfosById();
        String rtName = rtMapConsentimientoById.get(consent.RecordTypeId).getDeveloperName();
        
        if (rtName.equals('Telefono') || rtName.equals('Movil')) {
            consent.ChannelValue__c = DataValidations.transformPhone(consent.ChannelValue__c);
        }
    }
}