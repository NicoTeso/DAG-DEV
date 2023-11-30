public class ChatTranscriptHandler implements ITriggerHandler {
    private TriggerExecutionHelper infoTrigger = new TriggerExecutionHelper();
    
    //public Map<String,List<String>> mapEmailToAccountsId = new Map<String, List<String>>();
    //public Map<String,List<String>> mapEmailToLeadsId = new Map<String, List<String>>();
    //public Map<String,Contact> mapContactByAccountId = new Map<String,Contact>();
    
    public ChatTranscriptHandler (Schema.sObjectType soType) {
        InfoTrigger.setTipoHandler(soType);
    }
    
    public TriggerExecutionHelper getInfo() {
        return infoTrigger;
    }
    
    public void bulkBefore() {
        /*
        mapEmailToAccountsId.clear();
        mapEmailToLeadsId.clear();
        List<String> listEmail = new List<String>();
        
        if (Trigger.new != null) {
            for (SObject objeto:Trigger.new) {
            	LiveChatTranscript chat = (LiveChatTranscript) objeto;
                
                if (!String.isBlank(chat.CustomerEmail__c)) {
                    listEmail.add(chat.CustomerEmail__c);
                }
            }
            
            if (!listEmail.isEmpty()) {
                mapEmailToAccountsId = AccountGateway.getAccountIdByEmails(listEmail);
                mapEmailToLeadsId = LeadGateway.getLeadIdByEmails(listEmail);
            }
            
            if (!mapEmailToAccountsId.isEmpty()) {
                List<String> idsAccount = new List<String>();
                
                for (List<String> listIds : mapEmailToAccountsId.values()) {
                    idsAccount.addAll(listIds);
                }
                
                mapContactByAccountId = ContactGateway.getContactByAccountId(idsAccount);
            }
		}
*/
    }
    
    public void bulkAfter() {}
    
    public void beforeInsert(sObject so) {
        /*
        LiveChatTranscript chat = (LiveChatTranscript) so;
        String usuario = System.UserInfo.getName();
        System.debug('ChatTranscriptHandler:beforeInsert: ' + chat);
        if(Label.UserAutomatedProcess.equalsIgnoreCase(usuario)){
             if (!String.isBlank(chat.CustomerEmail__c) && chat.AccountId == null && chat.LeadId == null) {
            		List<String> cuentas = mapEmailToAccountsId.containsKey(chat.CustomerEmail__c) ? mapEmailToAccountsId.get(chat.CustomerEmail__c) : null;
                 	List<String> candidatos = mapEmailToLeadsId.containsKey(chat.CustomerEmail__c) ? mapEmailToLeadsId.get(chat.CustomerEmail__c): null;
            		//System.debug('cuentas: ' + cuentas);
            		//System.debug('cuentas: ' + cand);
            		if (cuentas != null ) {
                        if(cuentas.size() == 1){
                            String accountId = cuentas[0];
                			chat.AccountId = accountId;
                			chat.ContactId = mapContactByAccountId.containsKey(accountId) ? mapContactByAccountId.get(accountId).Id : null;
            			}
            		}
                 	else if(candidatos != null &&  candidatos.size() == 1){
                    	//miramos los lead
                    	String leadId = candidatos[0];
                		chat.LeadId = leadId;
                	}
        		}
        }
*/
       
    }
    
    public void beforeUpdate(sObject old, sObject so) {
        /*
        LiveChatTranscript chatOld = (LiveChatTranscript) so;
        LiveChatTranscript chat = (LiveChatTranscript) so;
        String usuario = System.UserInfo.getName();
        System.debug('ChatTranscriptHandler:beforeUpdate:'+ chat);
        System.debug('ChatTranscriptHandler:beforeUpdate:'+ chatOld);
        System.debug('Chat:status:'+chat.Status);
        System.debug('usuario:'+ usuario);
        
        if (Label.StatusInProgress.equalsIgnoreCase(chat.Status) && Label.UserAutomatedProcess.equalsIgnoreCase(usuario)) {
            if (chat.CustomerEmail__c != chatOld.customerEmail__c && chatOld.AccountId == null 
               && String.isBlank(chat.CustomerEmail__c) && chat.AccountId == null && chat.LeadId == null ) {
                List<String> cuentas = mapEmailToAccountsId.containsKey(chat.CustomerEmail__c) ? mapEmailToAccountsId.get(chat.CustomerEmail__c) : null;
                List<String> candidatos = mapEmailToLeadsId.containsKey(chat.CustomerEmail__c) ? mapEmailToLeadsId.get(chat.CustomerEmail__c): null;
            	
                if (cuentas != null ) {
                        if(cuentas.size() == 1){
                            String accountId = cuentas[0];
                			chat.AccountId = accountId;
                			chat.ContactId = mapContactByAccountId.containsKey(accountId) ? mapContactByAccountId.get(accountId).Id : null;
            			}
            		}
                 	else if(candidatos != null &&  candidatos.size() == 1){
                    	//miramos los lead
                    	String leadId = candidatos[0];
                		chat.LeadId = leadId;
                	}
        	}
        }
*/
    }
    
    public void beforeDelete(sObject so) {}
    
    public void afterInsert(sObject so) {}
    
    public void afterUpdate(sObject old, sObject so) {}
    
    public void afterDelete(sObject so) {}
    
    public void andFinally() {}
}