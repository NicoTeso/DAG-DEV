public class AccountAndLeadByEmailController {
    
    @AuraEnabled
    public static String getListResponse(String id) {
        //Query 10 accounts
        List<AccountAndLeadByEmailController.Response> listResponse = new List<AccountAndLeadByEmailController.Response>();
        LiveChatTranscript chat = AccountAndLeadByEmailController.getLIveChat(id);
        
        if (chat != null && !String.isBlank(chat.CustomerEmail__c)) {
        	for (Account cuenta : [SELECT Id, Name, Email__c, IsPersonAccount, PersonEmail, Other_Email__c, OtherEmail__pc
                                   FROM Account
                                   WHERE Email__c = :chat.CustomerEmail__c
                                   		OR PersonEmail = :chat.CustomerEmail__c
                                   		OR Other_Email__c = :chat.CustomerEmail__c
                                   		OR OtherEmail__pc = :chat.CustomerEmail__c
                                   LIMIT 10]) {
            	AccountAndLeadByEmailController.Response response = new AccountAndLeadByEmailController.Response();
            	response.Id = cuenta.Id;
            	response.Name = cuenta.Name;  
            	response.Email = chat.CustomerEmail__c;
            	response.Tipo = cuenta.IsPersonAccount ? 'C. Física' : 'C. Jurídico';
            	listResponse.add(response);
            }
            
            for (Lead candidato : [SELECT Id, Email, Name FROM Lead WHERE Email = :chat.CustomerEmail__c LIMIT 10]) {
                AccountAndLeadByEmailController.Response response = new AccountAndLeadByEmailController.Response();
                response.Id = candidato.Id;
                response.Name = candidato.Name;  
                response.Email = chat.CustomerEmail__c;
                response.Tipo = 'Candidato';
                listResponse.add(response);
            }
        }
        else{ 
            Case caso = AccountAndLeadByEmailController.getCase(id);
            if(caso != null && (!String.isBlank(caso.SuppliedEmail) || !String.isBlank(caso.SuppliedPhone))){
                for (Account cuenta : [SELECT Id, Name,IsPersonAccount, PersonEmail, OtherEmail__pc, Phone, PersonMobilePhone, PersonOtherPhone, OtherMobilePhone__pc
                                   FROM Account
                                   WHERE (PersonEmail != NULL AND PersonEmail = :caso.SuppliedEmail )
                                   OR (OtherEmail__pc != NULL AND OtherEmail__pc = :caso.SuppliedEmail)
                                   OR (Phone != NULL AND Phone = :caso.SuppliedPhone)
                                   OR (PersonMobilePhone != NULL AND PersonMobilePhone = :caso.SuppliedPhone)
                                   OR (PersonOtherPhone != NULL AND PersonOtherPhone = :caso.SuppliedPhone)
                                   OR (OtherMobilePhone__pc != NULL AND OtherMobilePhone__pc = :caso.SuppliedPhone)
                                   LIMIT 10]) {
				AccountAndLeadByEmailController.Response response = new AccountAndLeadByEmailController.Response();
            	response.Id = cuenta.Id;
            	response.Name = cuenta.Name; 
                                       
                if(!String.isBlank(cuenta.PersonEmail) && cuenta.PersonEmail.equalsIgnoreCase(caso.SuppliedEmail)){
                	response.Email = cuenta.PersonEmail;                
                }
                else if(!String.isBlank(cuenta.OtherEmail__pc) && cuenta.OtherEmail__pc.equalsIgnoreCase(caso.SuppliedEmail)){
            		response.Email = cuenta.PersonEmail; 
                }  
                
                if(!String.isBlank(cuenta.Phone) && cuenta.Phone.equalsIgnoreCase(caso.SuppliedPhone)){
                    response.Phone = cuenta.Phone;                       
                }
                else if(!String.isBlank(cuenta.PersonMobilePhone) && cuenta.PersonMobilePhone.equalsIgnoreCase(caso.SuppliedPhone)){
                	response.Phone = cuenta.PersonMobilePhone;                         
                }
                else if(!String.isBlank(cuenta.PersonOtherPhone) && cuenta.PersonOtherPhone.equalsIgnoreCase(caso.SuppliedPhone)){
                	response.Phone = cuenta.PersonOtherPhone;                          
                }
                else if(!String.isBlank(cuenta.OtherMobilePhone__pc) && cuenta.OtherMobilePhone__pc.equalsIgnoreCase(caso.SuppliedPhone)){
                	response.Phone = cuenta.OtherMobilePhone__pc;                          
                }
            	response.Tipo = 'Case';
            	listResponse.add(response);            
            }
        	}
        }
        
        String respuestaJSON = JSON.serialize(listResponse);
        
        return respuestaJSON;
	}
    
	@AuraEnabled
    public static String relacionar(String id, String idAux, String tipo) {
        String respuesta = '';
        LiveChatTranscript chat;
        Case caso;
        system.debug('entro en la relacion id:'+ id + ' idAux:'+ idAux);
        
        if (!String.isBlank(id) && !String.isBlank(idAux)) {
            system.debug('entro en el no es vacío y el tipo es : '+ tipo);
        	if (tipo.equalsIgnoreCase('C. Física') || tipo.equalsIgnoreCase('C. Jurídico')){
                chat = new liveChatTranscript();
                chat.Id = id;
                chat.AccountId = idAux;
        	}
        	else if (tipo.equalsIgnoreCase('Candidato')) {
            	chat = new liveChatTranscript();
            	chat.Id = id;
            	chat.LeadId = idAux;
        	}
            else if(tipo.equalsIgnoreCase('Case')){
                List<Case> casos = [select id, RecordType.DeveloperName, isClosed, AccountId, Lead__c from Case where id = : id ];
                if (!casos.isEmpty()){
                    caso =casos[0];
                    if(caso.IsClosed){
                        respuesta ='El caso esta cerrado';
                        caso = null;
                    }
                    else if(caso.RecordType.DeveloperName.equalsIgnoreCase('Gestion_de_Lead')){
                        caso = new Case();
            			caso.Id = id;
            			caso.Lead__c = null;
                		caso.AccountId = idAux;
          
                    }
                    else{
                        respuesta ='El caso no es de gestión de lead';
                        caso = null;
                    }
                }
              	caso = new Case();
            	caso.Id = id;
            	caso.Lead__c = null;
                caso.AccountId = idAux;
          
            }
        
            if (chat != null) {
               system.debug('entro para actualizar el chat');
               update chat;
               respuesta = 'Se ha relacionado correctamente';
        	}
            if(caso != null){
               system.debug('entro para actualizar el caso');
               update caso;
                respuesta ='Se ha relacionado conrrectamente';
            }
            
        }
        return respuesta;
    }
    
    @AuraEnabled
    public static String getObject(Id identificador){
        Schema.SObjectType sObjectType;
        String respuesta='';
        if(!String.isBlank(identificador)){
            sObjectType = identificador.getSobjectType();
            respuesta = String.valueOf(sObjectType);
            
        }
        return respuesta;
    }
    
    
    
    public static List<Account> getAccountsByChatId(String id) {
        // Query 10 accounts
        List<Account> accList = new List<Account>();
        LiveChatTranscript chat = AccountAndLeadByEmailController.getLIveChat(id);
        
        if (chat != null) {
        	 accList = [SELECT Id, Name, Email__c, RecordType.Name, PersonEmail, Other_Email__c, OtherEmail__pc
                        FROM Account
                        WHERE Email__c = :chat.CustomerEmail__c
                        	OR PersonEmail = :chat.CustomerEmail__c
                        	OR Other_Email__c = :chat.CustomerEmail__c
                        	OR OtherEmail__pc = :chat.CustomerEmail__c
                        LIMIT 10]; 
        }
        
        return accList;
    }
    public static List<Lead> getLeads(String email) {
        //Query 10 accounts
        List<Lead> leadList = [SELECT Id, Email, Name
                               FROM Lead  WHERE  Email = :email LIMIT 10]; 

        return leadList;
    }
    
    public static LiveChatTranscript getLiveChat(String id) {
        //Query 10 accounts
        LiveChatTranscript chat;
        List<LiveChatTranscript> listChat = [SELECT Id, CustomerEmail__c
                                 			 FROM LiveChatTranscript WHERE id = :id LIMIT 1]; 
        
        if (!listChat.isEmpty()) {
            chat = listChat[0];
        }
        
        return chat;
    }
    
    public static Case getCase(String id) {
        //Query 10 accounts
        Case caso;
        List<Case> listCases = [SELECT Id, SuppliedEmail,SuppliedPhone, SuppliedName FROM Case WHERE id = :id LIMIT 1]; 
        
        if (!listCases.isEmpty()) {
            caso = listCases[0];
        }
        
        return caso;
    }
    
    public class Response {
        public String Id {get;set;}
        public String Name {get;set;}
        public String Email {get;set;}
        public String Phone {get;set;}
        public String Tipo {get;set;}
    }
}