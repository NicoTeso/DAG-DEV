public class AccountApiRestServiceController {
    private static Map<String, Schema.RecordTypeInfo> rtMapConsentimientoByName = Schema.SObjectType.Consentimientos__c.getRecordTypeInfosByName();
    
    /*
    * Método principal de inserción y actualización de un cliente y cliente concesionario
	*/
    public static ResponseApi upsertCliente(AccountApiRestModel req) {
        ResponseApi response = new ResponseApi();
        try {
             Concesionario__c concesionario = ConcesionarioGateway.getConcessionaireByCompanyId(req.accountApi.companyId);
        	 String auxIdExternal = req.accountApi.customerId+'/'+ req.accountApi.companyId;
        	 Cliente_Concesionario__c clienteConcesionario = ClienteConcesionarioGateway.getClienteConcesionarioByIdExternal(auxIdExternal);
        	 List<Cliente_Concesionario__c> listClienteConcesionario = new List<Cliente_Concesionario__c>();
             Account cliente;
        	 response.Message = '';
        	 Boolean buscar = false;
             if (clienteConcesionario != null) {
                    // Encontrado mediante IDs externas
                    if (clienteConcesionario.Cliente__r.isPersonAccount != req.accountApi.isPersonAccount) {
						throw new CustomException('No coinciden los campos isPersonAccount');
					}
                    
                    // Modificamos registro del cliente
					cliente = upsertCliente(req, clienteConcesionario.Cliente__c, response);
                    buscar = true;
                    upsertClienteConcesionario(req, clienteConcesionario, cliente, concesionario);
                  
                }
            else if(!String.isBlank(req.accountApi.documento)){
                cliente = AccountGateway.getAccountByDocumento(req.accountApi.documento);
                if(cliente !=null){
                    cliente = upsertCliente(req, cliente.Id, response);
                    upsertClienteConcesionario(req, null, cliente, concesionario);
                }
                else {
                    cliente = upsertCliente(req,'', response);
                    upsertClienteConcesionario(req, null, cliente, concesionario);
                }
            }
            else{
                cliente = upsertCliente(req, '', response);
                upsertClienteConcesionario(req, null, cliente, concesionario);
                	}
            //Respuesta, todo correcto 
            // Luego lo cambiamos con las excepciones etc
			response.Status = Label.errorStatus_Success;
        	response.Message += Label.responseMessage_Success + ' ';
        } catch(Exception e) {
            response.ErrorCode = '500';
            response.Status = Label.errorStatus_Error;
        	response.Message += Label.responseMessage_Error + ' ' + e.getMessage() + ' línea: ' + e.getLineNumber() + ' ; ';
            System.debug(response.Message);

            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.accountApi.customerId+'/'+ req.accountApi.companyId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'AccountApiRestServiceController.upsertCliente';
                        
            insert exc;
        }
        
        System.debug(response.Status);
        return response;
    }
    
    /*
    * Método principal de actualización de un cliente con los externalInfo mediante un cliente concesionario
	*/
    public static ResponseApi updateExternalInfoCliente(AccountApiRestModel req) {
        List<Account> listaCliente = [SELECT Id,
                                      		 IsPersonAccount,
                                      		 Occupation__pc,
                                      		 ChildrenCount__pc,
                                      	 	 PersonBirthdate,
                                      		 gender__pc,
                                      		 incomes__pc,
                                      		 position__pc,
                                      		 maritalStatus__pc,
                                        	 economicSector__pc
                                      FROM Account
                                      WHERE Id IN (SELECT Cliente__c
                                                   FROM Cliente_Concesionario__c
                                                   WHERE Id_Cliente_DMS__c = :req.accountApi.customerId
                                                   		AND Concesionario__r.Id_Concesionario_Sima__c = :req.accountApi.companyId)];
        Account cliente;
                
        if (!listaCliente.isEmpty() && listaCliente[0].isPersonAccount ) {
            cliente = listaCliente[0];
          	cliente.Occupation__pc = !String.isBlank(req.accountApi.occupation) ? req.accountApi.companyId + '-' + req.accountApi.occupation : null;
            cliente.ChildrenCount__pc = !String.isBlank(req.accountApi.childrenCount) && req.accountApi.childrenCount.isNumeric() ? Integer.valueOf(req.accountApi.childrenCount) : null;
            cliente.PersonBirthdate = !String.isBlank(req.accountApi.personBirthdate) ? Date.valueOf(req.accountApi.personBirthdate) : null;
            cliente.gender__pc = req.accountApi.gender;
            cliente.incomes__pc = req.accountApi.incomes;
            cliente.position__pc = req.accountApi.position;
            cliente.maritalStatus__pc = req.accountApi.maritalStatus;
            cliente.economicSector__pc = !String.isBlank(req.accountApi.economicSector) ? req.accountApi.companyId + '-' + req.accountApi.economicSector : null;
            
            upsert cliente;
        }
        else {
            throw new CustomException(Label.errorStatus_Error);
        }
        
        ResponseApi response = new ResponseApi();
		response.Status = Label.errorStatus_Success;
        response.Message = Label.responseMessage_Success;
        
        return response;
    }
    
    /*
    * Método principal para actualizar consentimientos de un cliente
	*/
    public static ResponseApi upsertConsent(AccountApiRestModel req) {
        //Buscar al cliente y con esto 
        ResponseApi response = new ResponseApi();
        response.Message = '';
        Cliente_Concesionario__c cConcesionario = ClienteConcesionarioGateway.getClienteConcesionarioByIdExternal(req.accountApi.customerId, req.accountApi.companyId);
        Contact contacto = ContactGateway.getContactByAccountId(cConcesionario.Cliente__c);
        try {
			if (cConcesionario != null) {
                //Map<String, Consentimientos__c> mapConsentsByValue = ConsentimientosGateway.getConsentimientosValueByAccountId(cConcesionario.Cliente__c);
                //map reune id's de concesionario y de channelValue para los diferentes tipos de consentimientos
                Map<String, Consentimientos__c> mapConsentsByValue = new Map<String,Consentimientos__c>();
                List<Consentimientos__c> listConsentimiento = ConsentimientosGateway.getConsentimientosByAccountId(cConcesionario.Cliente__c);
                for(Consentimientos__c consentimiento : listConsentimiento ){
                    String recordTypeDN  = ConsentimientosGateway.getRecordTypeDeveloperNameById(consentimiento.recordTypeId);
                    if(recordTypeDN.equalsIgnoreCase('Email') || recordTypeDN.equalsIgnoreCase('Movil') || recordTypeDN.equalsIgnoreCase('Telefono')){
                        mapConsentsByValue.put(consentimiento.ChannelValue__c, consentimiento);
                    }
                    else if (recordTypeDN.equalsIgnoreCase('Encuestas_satisfacion')){
                        mapConsentsByValue.put(consentimiento.Concesionario__r.Id_Concesionario_Sima__c, consentimiento);
                    }
                }
                Set<Consentimientos__c> lstConsentsToUpdate = new Set<Consentimientos__c >();
                Map<String, Consentimientos__c> mapConsentimientoTuUpdateById = new Map<String, Consentimientos__c>();
               	Datetime consentDate = Datetime.valueOf(req.accountapi.DateConsent.replace('T',' '));
                
                for (AccountApiRestModel.MethodsOfContactConsent consent : req.accountApi.methodOfContactConsent) {
                    String channelValue;

                    if(consent.purposeId.equalsIgnoreCase('CustomerSatisfactionSales') || consent.purposeId.equalsIgnoreCase('CustomerSatisfactionAfterSales') ){
                        String field = consent.purposeId + '__c';
                        Consentimientos__c consentimientoEncuesta;
                        if(mapConsentimientoTuUpdateById.containsKey(req.accountApi.companyId)){
                            consentimientoEncuesta = mapConsentimientoTuUpdateById.get(req.accountApi.companyId);
                        }
                        else{
                            if(mapConsentsByValue.containsKey(req.accountApi.companyId)){
                                consentimientoEncuesta = mapConsentsByValue.get(req.accountApi.companyId);
                            }
                            else if(consent.value.equalsIgnoreCase('Deny')) {
                                consentimientoEncuesta = new Consentimientos__c();
                                consentimientoEncuesta.Contact__c = contacto.Id;
                                consentimientoEncuesta.Concesionario__r = new Concesionario__c(Id_Concesionario_Sima__c = req.accountApi.companyId);
                                consentimientoEncuesta.RecordTypeId = ConsentimientosGateway.getRecordTypeIdByDeveloperName('Encuestas_satisfacion');
                            }
                        }
                        if (consentimientoEncuesta != null){
    	                    consentimientoEncuesta.put(field, consent.value);
        	                consentimientoEncuesta.Fecha_de_captura__c = consentDate;
            	            consentimientoEncuesta.EnviarAmulesoft__c = false;
                	        mapConsentimientoTuUpdateById.put(req.accountApi.companyId, consentimientoEncuesta);
                        }            
                    }
                    else {
                    	if (consent.channelType.equalsIgnoreCase('SMS') || consent.channelType.equalsIgnoreCase('Call')) {
                        channelValue =  DataValidations.validatePhone(consent.channelValue) ? DataValidations.transformPhone(consent.channelValue) : '';
                    }
                    	else { 
                        channelValue = !String.isBlank(consent.channelValue)?consent.channelValue.toLowerCase(): consent.channelValue;
                    }
                    
                    	if (!String.isBlank(channelValue) && mapConsentsByValue.containsKey(channelValue)) {
                        Consentimientos__c consentToUpdate = mapConsentsByValue.get(channelValue);
                        
                        if (consentToUpdate.Fecha_de_captura__c == null || (consentToUpdate.Fecha_de_captura__c != null && consentDate >= consentToUpdate.Fecha_de_captura__c)) {
                            consentToUpdate.Fecha_de_captura__c = consentDate;
                            consentToUpdate.EnviarAmulesoft__c = false;
                            String field = consent.purposeId;
                            
                            if (consent.channelType.equalsIgnoreCase('SMS')) {
                                field += 'SMS__c';
                            }
                            else if (consent.channelType.equalsIgnoreCase('Call') || consent.channelType.equalsIgnoreCase('Email')) {
                                field += '__c';
                            }
                            
                            consentToUpdate.put(field, consent.value);
                            mapConsentsByValue.put(channelValue, consentToUpdate);
                            mapConsentimientoTuUpdateById.put(consentToUpdate.Id, consentToUpdate);
                        }
                    }	
                    }
                   
                }
            
                if (!mapConsentimientoTuUpdateById.isEmpty()) {
                    upsert mapConsentimientoTuUpdateById.values();
                    ExternalServiceController.sendConsentimientoMulesoft(contacto.Id, cConcesionario.External_Id__c);
                }
                response.Status = Label.errorStatus_Success;
            }
            else {
                //No hay cliente concesionario
                response.Status = Label.errorStatus_Error;
                response.ErrorCode = '510';
                response.Message = 'No existe cliente concesionario';
            }
        } catch(Exception e) {
            response.ErrorCode = '510';
            response.Status = Label.errorStatus_Error;
            response.Message = e.getMessage();

            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.accountApi.customerId+'/'+ req.accountApi.companyId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'AccountApiRestServiceController.upsertConsent';
            
            insert exc;
            
        }
        
        return response;
    }
    /*
    private static Account existeClienteEmailOrPhone(AccountApiRestModel req) {
        Account cliente = null;
        String email = '';
        String phone = '';
        String mobile = '';
        
        List<String> lstEmails = new List<String>();
        List<String> lstPhoneNumbers = new List<String>();
        
        for (AccountApiRestModel.MethodsOfContact method : req.accountApi.methodsOfContact) {
            if (method.channel == Label.channelEmail) {
                if (DataValidations.validateEmail(method.value)) {
                    email = method.value.toLowerCase();
                    lstEmails.add(email);
                } 
        	}
        	else if (method.channel == Label.channelPhone) {
                if (DataValidations.validatePhone(DataValidations.clearPhone(method.value))) {
                    phone = DataValidations.clearPhone(method.value);
                    lstPhoneNumbers.add(phone);
                }
        	}
        	else if (method.channel == Label.channelMobile) {
                if (DataValidations.validatePhone(DataValidations.clearPhone(method.value))) {
                    mobile = DataValidations.clearPhone(method.value);
                    lstPhoneNumbers.add(mobile);
                }
        	}
        }
        
        if (!lstEmails.isEmpty() || !lstPhoneNumbers.isEmpty()) {
            List<Account> listAccount = [SELECT Id,
                                         		FirstName,
                                         		LastName,
                                         		isPersonAccount,
                                         		PersonEmail,
                                                Email__c,
                                                Other_Email__c,
                                         		OtherEmail__pc,
                                                Phone,
                                                Other_Phone__c,
                                         		PersonOtherPhone, 
                                                PersonMobilePhone,
                                         		Mobile__c,
                                                Other_Mobile__c,
                                         		OtherMobilePhone__pc,
                                         		RecordTypeId,
                                         		Name,
                                         		Marca_registrada__c,
                                         		Pais__c,
                                         		Pais__r.ISO_31661_alfa2__c,
                                         		Tipo_de_documento_cuenta_personal__c,
                                         		Tipo_de_documento_empresa__c,
                                         		Documento__c,
                                         		Salutation,
                                         		BillingAddressId__c,
                                         		BillingStreet,
                                         		BillingCity,
                                         		BillingCountry,
                                         		BillingPostalCode,
                                         		BillingState,
                                         		ShippingAddressId__c,
                                         		ShippingStreet,
                                         		ShippingCity,
                                         		ShippingCountry,
                                         		ShippingPostalCode,
                                         		ShippingState
                                         FROM Account
                                         WHERE ((FirstName = :req.accountApi.firstName AND lastName = :req.accountApi.lastName)
                                         	OR Name = :req.accountApi.name)
                                         	AND ((PersonEmail != '' AND PersonEmail IN :lstEmails)
                                                OR (Email__c != '' AND Email__c IN :lstEmails)
                                                OR (Other_Email__c != '' AND Other_Email__c IN :lstEmails)
                                                OR (OtherEmail__pc != '' AND OtherEmail__pc IN :lstEmails)
                                            	OR (Phone != '' AND Phone IN: lstPhoneNumbers)
                                                OR (Other_Phone__c != '' AND Other_Phone__c IN: lstPhoneNumbers)
                                                OR (PersonOtherPhone != '' AND PersonOtherPhone IN: lstPhoneNumbers)
                                                OR (Mobile__c != '' AND Mobile__c IN: lstPhoneNumbers)
                                            	OR (PersonMobilePhone != '' AND PersonMobilePhone IN :lstPhoneNumbers)
                                                OR (Other_Mobile__c	 != '' AND Other_Mobile__c	 IN :lstPhoneNumbers))];
            
        	if (!listAccount.isEmpty()) {
                //puede encontrar varios, pero devolvemos el primero ya que no existe cliente con ese documento 
                cliente = listAccount[0];
            }
        }
        
		return cliente;
    }
    */
    // Crea o actualiza registro cliente y consentimientos
    private static Account upsertCliente(AccountApiRestModel req, String idCliente, ResponseApi response) {
        Map<String, Contact> mapAccountIdContacts = new Map<String, Contact>();
        Map<String, Consentimientos__c> mapConsentsByMethodValue = new Map<String, Consentimientos__c>();
        Map<String, Consentimientos__c> mapConsentsByMethoValueToUpsert = new Map<String, Consentimientos__c>();
        List<Consentimientos__c> lstConsents = new List<Consentimientos__c>();
       	Account cliente = new Account();
        List<String> lstCountries = new List<String>{req.accountApi.pais, req.accountApi.billingCountryIso, req.accountApi.shippingCountryIso};
		Map<String, Pais__c> mapCountries = PaisGateway.getPaisByAlfa2(lstCountries);
        Pais__c pais = mapCountries.get(req.accountApi.pais);
        System.debug('País: ' + pais);
        Pais__c billingCountry = mapCountries.get(req.accountApi.billingCountryIso);
        System.debug('billingCountry: ' + billingCountry);
        Pais__c shippingCountry = mapCountries.get(req.accountApi.shippingCountryIso);
        System.debug('shippingCountry: ' + shippingCountry);
        Boolean duplicado = false;
        
        if (idCliente == '') {
            // Nuevo cliente
            Map<String, Schema.RecordTypeInfo> rtMapByDName = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
            String idRecordType = req.accountApi.isPersonAccount ? 
                rtMapByDName.get('PersonAccount').getRecordTypeId() : rtMapByDName.get('Cliente_Empresa').getRecordTypeId();
            cliente.RecordTypeId = idRecordType;
			cliente.Fecha_Alta_Sima__c = Datetime.now();
        }
        else {
            // Cliente ya existente
            // Buscamos sus contactos
            // Buscamos sus consentimientos
            cliente.Id = idCliente;
            //mapAccountIdContacts = ContactGateway.getContactByAccountId(new List<String>{idCliente});
            List<Consentimientos__c> lstConsentsByContact = [SELECT Id, ChannelValue__c, Medio_de_contacto__c, RecordTypeId
                                                         	 FROM Consentimientos__c
                                                         	 WHERE Contact__c IN
                                                         		(SELECT Id FROM Contact WHERE AccountId = :idCliente)];
            
        	for (Consentimientos__c consent : lstConsentsByContact) {
            	mapConsentsByMethodValue.put(consent.ChannelValue__c, consent);
        	}
        }
        
        if (!req.accountApi.isPersonAccount) {
            cliente.Name = req.accountApi.name;
        }
        else {
            cliente.FirstName = req.accountApi.firstName;
        	cliente.LastName = req.accountApi.lastName; 
        }
        
        cliente.Marca_registrada__c = req.accountApi.tradeName;
        cliente.Pais__c = pais != null ? pais.Id : null;
        
        // Keep old document type if document type in JSON is empty
        if (!String.isBlank(req.accountApi.tipoDocumento)) {
            cliente.Tipo_de_documento_cuenta_personal__c = Label.docType_VATId.equalsIgnoreCase(req.accountApi.tipoDocumento)
                || Label.docType_VATIdForForeigners.equalsIgnoreCase(req.accountApi.tipoDocumento)
                || Label.docType_Passport.equalsIgnoreCase(req.accountApi.tipoDocumento) 
                || Label.docType_OtherCountryVATId.equalsIgnoreCase(req.accountApi.tipoDocumento)
                ? req.accountApi.tipoDocumento : null;
        }
        
        if (!String.isBlank(req.accountApi.tipoDocumentoEmpresa)) {
            cliente.Tipo_de_documento_empresa__c = Label.docType_VATId.equalsIgnoreCase(req.accountApi.tipoDocumentoEmpresa)
                || Label.docType_OtherCountryVATId.equalsIgnoreCase(req.accountApi.tipoDocumentoEmpresa)
                ? req.accountApi.tipoDocumentoEmpresa : null;
        }

        // Keep old document number if document number in JSON is empty
        if (!String.isBlank(req.accountApi.documento)) {
            cliente.Documento__c = req.accountApi.documento.toUpperCase();
        }
        
        if (billingCountry != null) {
            cliente.BillingAddressId__c = req.accountApi.billingAddressId;
            cliente.BillingStreet = !String.isBlank(req.accountApi.billingStreet) ? req.accountApi.billingStreet.toUpperCase():req.accountApi.billingAddress.toUpperCase(); 
        	cliente.BillingCity = !String.isBlank(req.accountApi.billingCity) ? req.accountApi.billingCity.toUpperCase():'';
        	cliente.BillingCountry = billingCountry != null ? billingCountry.Name.toUpperCase() : '';
        	cliente.BillingPostalCode =!String.isBlank(req.accountApi.billingPostalCode) ? req.accountApi.billingPostalCode.toUpperCase():'';
        	cliente.BillingState = !String.isBlank(req.accountApi.billingState)? req.accountApi.billingState.toUpperCase():'';
        }
        
        if (shippingCountry != null) {
            cliente.ShippingAddressId__c = req.accountApi.shippingAddressId;
            cliente.ShippingStreet = !String.isBlank(req.accountApi.shippingStreet) ? req.accountApi.shippingStreet.toUpperCase() : req.accountApi.shippingAddress.toUpperCase(); 
        	cliente.ShippingCity = !String.isBlank(req.accountApi.shippingCity) ? req.accountApi.shippingCity.toUpperCase() : '';
       	 	cliente.ShippingCountry = shippingCountry != null ? shippingCountry.Name.toUpperCase() : '';
        	cliente.ShippingPostalCode = !String.isBlank(req.accountApi.shippingPostalCode) ? req.accountApi.shippingPostalCode.toUpperCase() : '';
        	cliente.ShippingState = !String.isBlank(req.accountApi.shippingState) ? req.accountApi.shippingState.toUpperCase() : '';
        }
        
        cliente.ultima_modificacion_DMS__c = Datetime.now();
        
        // FORMAS DE CONTACTO En Cliente
        String errorCode = '';
        String errorMessage = '';
        
        for (AccountApiRestModel.MethodsOfContact methodsContact : req.accountApi.methodsOfContact) {
            if (methodsContact.channel == Label.channelEmail) {
				if (DataValidations.validateEmail(methodsContact.value)) {
					if (!req.accountApi.isPersonAccount) {
                    	if (String.isBlank(cliente.Email__c)) {
                        	cliente.Email__c = methodsContact.value;
                            methodsContact.channelFinal = Label.channelEmail;
                    	}
                    	else if(String.isBlank(cliente.Other_Email__c) && !cliente.Email__c.equalsIgnoreCase(methodsContact.value)) {
                        	cliente.Other_Email__c = methodsContact.value;
                            methodsContact.channelFinal = Label.channelOtherEmail;
                    	}
                	}
                	else {
                    	if (String.isBlank(cliente.PersonEmail)) {
                        	cliente.PersonEmail = methodsContact.value.toLowerCase();
                            methodsContact.channelFinal = Label.channelEmail;
                            
                            if (!mapConsentsByMethodValue.containsKey(cliente.PersonEmail)) {
                                Consentimientos__c consent = creaConsentimiento(cliente.PersonEmail, Label.channelEmail, 'Email');
                            	mapConsentsByMethoValueToUpsert.put(cliente.PersonEmail,consent);
                                //lstConsents.add(consent);
                            }
                            else {
                                // lo tenemos ya creado 
                                Consentimientos__c consent = mapConsentsByMethodValue.get(cliente.PersonEmail);
                                
                                if (!consent.Medio_de_contacto__c.equalsIgnoreCase(Label.channelEmail)) {
                                    consent.Medio_de_contacto__c = Label.channelEmail;
                                    mapConsentsByMethoValueToUpsert.put(cliente.PersonEmail,consent);
                                    //lstConsents.add(consent);
                                }
                            }
                    	}
                    	else if (String.isBlank(cliente.OtherEmail__pc) && !cliente.PersonEmail.equalsIgnoreCase(methodsContact.value) ) {
                        	cliente.OtherEmail__pc = methodsContact.value.toLowerCase();
                            methodsContact.channelFinal = Label.channelOtherEmail;
                            
                            if (!mapConsentsByMethodValue.containsKey(cliente.OtherEmail__pc)) {
                                Consentimientos__c consent = creaConsentimiento(cliente.OtherEmail__pc, Label.channelOtherEmail, 'Email');
                                mapConsentsByMethoValueToUpsert.put(cliente.OtherEmail__pc, consent);
                            	//lstConsents.add(consent);
                            }
                            else {
                                //lo tenemos ya creado 
                                Consentimientos__c consent = mapConsentsByMethodValue.get(cliente.OtherEmail__pc);
                                
                                if (!consent.Medio_de_contacto__c.equalsIgnoreCase(Label.channelOtherEmail)) {
                                    consent.Medio_de_contacto__c = Label.channelOtherEmail;
                                    mapConsentsByMethoValueToUpsert.put(cliente.OtherEmail__pc, consent);
                                    //lstConsents.add(consent);
                                }
                    		}
                        }
                        else {
                            //Otro email para consentimiento
                            if (!mapConsentsByMethodValue.containsKey(methodsContact.value.toLowerCase())){
                                 Consentimientos__c consent = creaConsentimiento(methodsContact.value.toLowerCase(), Label.channelOther, 'Email');
                                 mapConsentsByMethoValueToUpsert.put(methodsContact.value.toLowerCase(), consent);
                                //lstConsents.add(consent);
                            }
                        }
                	}
                }
                else {
                    errorCode = '501';
                    errorMessage = Label.errorMessage_invalidEmail + ' : ' + methodsContact.value + ' ; ';
                }
        	}    
            else if (methodsContact.channel == Label.channelWebsite) {
                cliente.Website = methodsContact.value;
            }
            else if (methodsContact.channel == Label.channelPhone || methodsContact.channel == Label.channelMobile) {
                // Telefónico
                // Limpiar valor del telefono
                String replaced = DataValidations.clearPhone(methodsContact.value);
                System.debug('REPLACED: ' + replaced);
                
                if (!String.isBlank(replaced) && !replaced.equalsIgnoreCase(methodsContact.value)) {
                    methodsContact.value = replaced;
                    errorCode = '503';
                    errorMessage = Label.errorMessage_cleanPhone + ' : ' + methodsContact.value + ' ; ';
                }
                
                // Validar
                System.debug('VALIDACIÓN: ' + DataValidations.validatePhone(methodsContact.value));
                
                if (!String.isBlank(methodsContact.value) && DataValidations.validatePhone(methodsContact.value)) {
					System.debug('Es móvil: ' + DataValidations.isMobile(methodsContact.value));
                    String phone = DataValidations.transformPhone(methodsContact.value);
                    
                    if (DataValidations.isMobile(methodsContact.value)) {
                        if (!req.accountApi.isPersonAccount) {
                    		if (String.isBlank(cliente.Mobile__c)) {
                        		cliente.Mobile__c = phone;
                                methodsContact.channelFinal = Label.channelMobile;
                            }
                    		else if (String.isBlank(cliente.Other_Mobile__c) && !cliente.Mobile__c.equalsIgnoreCase(phone)) {
                    			cliente.Other_Mobile__c	 = phone;
                                methodsContact.channelFinal = Label.channelOtherMobile;
                			}
                		}
                		else {
                     		if (String.isBlank(cliente.PersonMobilePhone)) {
                        		cliente.PersonMobilePhone = phone;
                                methodsContact.channelFinal = Label.channelMobile;
                                
                                if (!mapConsentsByMethodValue.containsKey(cliente.PersonMobilePhone)) {
                                	Consentimientos__c consent = creaConsentimiento(cliente.PersonMobilePhone, Label.channelMobile, 'Móvil');
                            		mapConsentsByMethoValueToUpsert.put(cliente.PersonMobilePhone, consent);
                                    //lstConsents.add(consent);
                            	}
                                else {
                                	// lo tenemos ya creado 
                                	Consentimientos__c consent = mapConsentsByMethodValue.get(cliente.PersonMobilePhone);
                                	
                                    if (!consent.Medio_de_contacto__c.equalsIgnoreCase(Label.channelMobile)) {
                                    	consent.Medio_de_contacto__c = Label.channelMobile;
                                        mapConsentsByMethoValueToUpsert.put(cliente.PersonMobilePhone, consent);
                                    	//lstConsents.add(consent);
                                	}
                            	}
                    		}
                    		else if (String.isBlank(cliente.OtherMobilePhone__pc) && !cliente.PersonMobilePhone.equalsIgnoreCase(phone)) {
                    			cliente.OtherMobilePhone__pc = phone;
                                methodsContact.channelFinal = Label.channelOtherMobile;
                                
                                if (!mapConsentsByMethodValue.containsKey(cliente.OtherMobilePhone__pc)) {
                                	Consentimientos__c consent = creaConsentimiento(cliente.OtherMobilePhone__pc, Label.channelOtherMobile, 'Móvil');
                            		mapConsentsByMethoValueToUpsert.put(cliente.OtherMobilePhone__pc, consent);
                                    //lstConsents.add(consent);
                            	}
                                else {
                                	// lo tenemos ya creado 
                                	Consentimientos__c consent = mapConsentsByMethodValue.get(cliente.OtherMobilePhone__pc);
                                	
                                    if (!consent.Medio_de_contacto__c.equalsIgnoreCase(Label.channelOtherMobile)) {
                                    	consent.Medio_de_contacto__c = Label.channelOtherMobile;
                                        mapConsentsByMethoValueToUpsert.put(cliente.OtherMobilePhone__pc, consent);
                                    	//lstConsents.add(consent);
                                	}
                            	}
                			}
                            else {
                                 // consentimiento para los otros moviles
                                 if (!mapConsentsByMethodValue.containsKey(methodsContact.value)) {
                                		Consentimientos__c consent = creaConsentimiento(methodsContact.value, Label.channelOther, 'Móvil');
                           		 		mapConsentsByMethoValueToUpsert.put(methodsContact.value, consent);
                                     //lstConsents.add(consent);
                            	 }
                            }
                		}
                    }
                    else {
                        if (!req.accountApi.isPersonAccount) {
                    		if (String.isBlank(cliente.Phone)) {
                        		cliente.Phone = phone;
                                methodsContact.channelFinal = Label.channelPhone;
                    		}
                    		else if (String.isBlank(cliente.Other_Phone__c) && !cliente.Phone.equalsIgnoreCase(phone)) {
                    			cliente.Other_Phone__c = phone;
                                methodsContact.channelFinal = Label.channelOtherPhone;
                			}
                		}
                		else {
                     		if (String.isBlank(cliente.Phone)) {
                        		cliente.Phone = phone;
                                methodsContact.channelFinal = Label.channelPhone;
                                
                                if (!mapConsentsByMethodValue.containsKey(cliente.Phone)) {
                                	Consentimientos__c consent = creaConsentimiento(cliente.Phone, Label.channelPhone, 'Teléfono');
                            		mapConsentsByMethoValueToUpsert.put(cliente.Phone, consent);
                                    //lstConsents.add(consent);
                            	}
                                else {
                                	// lo tenemos ya creado 
                                	Consentimientos__c consent = mapConsentsByMethodValue.get(cliente.Phone);
                                	
                                    if (!consent.Medio_de_contacto__c.equalsIgnoreCase(Label.channelPhone)) {
                                    	consent.Medio_de_contacto__c = Label.channelPhone;
                                        mapConsentsByMethoValueToUpsert.put(cliente.Phone, consent);
                                    	//lstConsents.add(consent);
                                	}
                            	}
                    		}
                    		else if (String.isBlank(cliente.PersonOtherPhone) && !cliente.Phone.equalsIgnoreCase(phone)) {
                    			cliente.PersonOtherPhone = phone;
                                methodsContact.channelFinal = Label.channelOtherPhone;
                                
                                if (!mapConsentsByMethodValue.containsKey(cliente.PersonOtherPhone)) {
                                	Consentimientos__c consent = creaConsentimiento(cliente.PersonOtherPhone, Label.channelOtherPhone, 'Teléfono');
                            		mapConsentsByMethoValueToUpsert.put(cliente.PersonOtherPhone, consent);
                                    //lstConsents.add(consent);
                            	}
                                else {
                                	// lo tenemos ya creado 
                                	Consentimientos__c consent = mapConsentsByMethodValue.get(cliente.PersonOtherPhone);
                                	
                                    if (!consent.Medio_de_contacto__c.equalsIgnoreCase(Label.channelOtherPhone)) {
                                    	consent.Medio_de_contacto__c = Label.channelOtherPhone;
                                        mapConsentsByMethoValueToUpsert.put(cliente.PersonOtherPhone, consent);
                                    	//lstConsents.add(consent);
                                	}
                            	}
                			}
                            else {
                                // para otros telefonos guardar en consentimientos
                                if (!mapConsentsByMethodValue.containsKey(phone)){
                                		Consentimientos__c consent = creaConsentimiento(phone, Label.channelOther, 'Teléfono');
                           		 		mapConsentsByMethoValueToUpsert.put(phone, consent);
                                    //lstConsents.add(consent);
                            	 }
                            }
                		}
                    }
                }
                else {
                    errorCode = '502';
                    errorMessage = Label.errorMessage_invalidPhone + ' : ' + methodsContact.value + ' ; ';
                }
            }
       	}
        
        if (errorCode != '' && errorMessage != '') {
            response.ErrorCode = errorCode;
			response.Message += errorMessage;
        }

        if (cliente.Id != null){
            Account cliente1 = AccountGateway.getAccountById(cliente.Id);
            if (req.accountApi.isPersonAccount){
                if (cliente.PersonEmail != null && cliente.OtherEmail__pc == null && cliente1.OtherEmail__pc != null && cliente.PersonEmail == cliente1.OtherEmail__pc){
                    cliente.OtherEmail__pc = cliente1.PersonEmail;
                } 
                if (cliente.PersonMobilePhone != null && cliente.OtherMobilePhone__pc == null && cliente1.OtherMobilePhone__pc != null && cliente.PersonMobilePhone == cliente1.OtherMobilePhone__pc){
                    cliente.OtherMobilePhone__pc = cliente1.PersonMobilePhone;
                } 
                if (cliente.Phone != null && cliente.PersonOtherPhone == null && cliente1.PersonOtherPhone != null && cliente.Phone == cliente1.PersonOtherPhone){
                    cliente.PersonOtherPhone = cliente1.Phone;
                } 
            } else {
                if (cliente.Email__c != null && cliente.Other_Email__c == null && cliente1.Other_Email__c != null && cliente.Email__c == cliente1.Other_Email__c){
                    cliente.Other_Email__c = cliente1.Email__c;
                } 
                if (cliente.Mobile__c != null && cliente.Other_Mobile__c == null && cliente1.Other_Mobile__c != null && cliente.Mobile__c == cliente1.Other_Mobile__c){
                    cliente.Other_Mobile__c = cliente1.Mobile__c;
                } 
                if (cliente.Phone != null && cliente.Other_Phone__c == null && cliente1.Other_Phone__c != null && cliente.Phone == cliente1.Other_Phone__c){
                    cliente.Other_Phone__c = cliente1.Phone;
                } 
            }   
        }    
        
        if (cliente.Id == null){
            // Find duplicates
            List<Account> lstDuplicates = new List<Account>();
            lstDuplicates.add(cliente);
            //Cambiamos de lugar los telefonos/emails o completamos el otro para tener un mayor exito en la busqueda de duplicados
            Account cliente1 = new Account(); 
            if(req.accountApi.isPersonAccount){
                cliente1.RecordTypeId = cliente.RecordTypeId;
                cliente1.FirstName = cliente.FirstName;
        	    cliente1.LastName = cliente.LastName; 
                if (cliente.OtherEmail__pc == null && cliente.PersonEmail != null) {
                    cliente1.OtherEmail__pc = cliente.PersonEmail;
                } else if (cliente.OtherEmail__pc != null && cliente.PersonEmail != null){
                    cliente1.OtherEmail__pc = cliente.PersonEmail;
                    cliente1.PersonEmail = cliente.OtherEmail__pc;
                }
                if (cliente.OtherMobilePhone__pc == null && cliente.PersonMobilePhone != null) {
                    cliente1.OtherMobilePhone__pc = cliente.PersonMobilePhone;
                } else if (cliente.OtherMobilePhone__pc != null && cliente.PersonMobilePhone != null){
                    cliente1.OtherMobilePhone__pc = cliente.PersonMobilePhone;
                    cliente1.PersonMobilePhone = cliente.OtherMobilePhone__pc;
                }
                if (cliente.PersonOtherPhone == null && cliente.Phone != null) {
                    cliente1.PersonOtherPhone = cliente.Phone;
                } else if (cliente.PersonOtherPhone != null && cliente.Phone != null) {
                    cliente1.PersonOtherPhone = cliente.Phone;
                    cliente1.Phone = cliente.PersonOtherPhone;
                }
            } else {
                cliente1.RecordTypeId = cliente.RecordTypeId;
                cliente1.Name = cliente.Name;
                if (cliente.Other_Email__c == null && cliente.Email__c != null) {
                    cliente1.Other_Email__c = cliente.Email__c;
                } else if (cliente.Other_Email__c != null && cliente.Email__c != null) {
                    cliente1.Other_Email__c = cliente.Email__c;
                    cliente1.Email__c = cliente.Other_Email__c;
                }
                if (cliente.Other_Mobile__c == null && cliente.Mobile__c != null) {
                    cliente1.Other_Mobile__c = cliente.Mobile__c;
                } else if (cliente.Other_Mobile__c != null && cliente.Mobile__c != null) {
                    cliente1.Other_Mobile__c = cliente.Mobile__c;
                    cliente1.Mobile__c = cliente.Other_Mobile__c;
                }
                if (cliente.Other_Phone__c == null && cliente.Phone != null) {
                    cliente1.Other_Phone__c = cliente.Phone;
                } else if (cliente.Other_Phone__c != null && cliente.Phone != null){
                    cliente1.Other_Phone__c = cliente.Phone;
                    cliente1.Phone = cliente.Other_Phone__c;
                }
            }
            lstDuplicates.add(cliente1);
            
            System.debug('=====>LSTDUPS: ' + lstDuplicates);
        
            if (Datacloud.FindDuplicates.findDuplicates(lstDuplicates).size() > 0) {
                for (Datacloud.FindDuplicatesResult resultFindDuplicate: Datacloud.FindDuplicates.findDuplicates(lstDuplicates)){
                    System.debug('=====>LSTDUPSRESULT0: ' + resultFindDuplicate);
                    for (Datacloud.DuplicateResult recordDuplicate: resultFindDuplicate.getDuplicateResults()){
                         System.debug('recordDuplicate:'+recordDuplicate);
                         String ruleDuplicateDN = recordDuplicate.getDuplicateRule();
                         if(!ruleDuplicateDN.equalsIgnoreCase('PAccountLead')){
                            List<Datacloud.MatchRecord> recordListMatch = recordDuplicate.getMatchResults()[0].getMatchRecords();
                            System.debug('=====>RECORDLISTMATCH: ' + recordListMatch);
                            if (!recordListMatch.isEmpty()) {
                                Datacloud.MatchRecord recordMatch = recordListMatch[0];
                                SObject record = recordMatch.getRecord();
                                System.debug('RECORD: ' + record);
                                Account auxAcc = (Account) record;
                        
                                if (auxAcc != null) {
                                    system.debug('auxAcc:'+auxAcc);
                                    cliente.Id = auxAcc.Id;
                                    
                                    if (req.accountApi.isPersonAccount){

                                       cliente.PersonEmail = !String.isBlank(cliente.PersonEmail)?cliente.PersonEmail:auxAcc.PersonEmail;
                                       cliente.OtherEmail__pc = !String.isBlank(cliente.OtherEmail__pc)?cliente.OtherEmail__pc:auxAcc.OtherEmail__pc;
                                       cliente.PersonMobilePhone = !String.isBlank(cliente.PersonMobilePhone)?cliente.PersonMobilePhone:auxAcc.PersonMobilePhone;
                                       cliente.OtherMobilePhone__pc = !String.isBlank(cliente.OtherMobilePhone__pc)?cliente.OtherMobilePhone__pc:auxAcc.OtherMobilePhone__pc;
                                       cliente.Phone = !String.isBlank(cliente.Phone)?cliente.Phone:auxAcc.Phone;
                                       cliente.PersonOtherPhone = !String.isBlank(cliente.PersonOtherPhone)?cliente.PersonOtherPhone:auxAcc.PersonOtherPhone;
                                        
                                       if (cliente.PersonEmail == null && cliente.OtherEmail__pc != null ) {
                                           cliente.PersonEmail = cliente.OtherEmail__pc;
                                           cliente.OtherEmail__pc = null;
                                       }
                                       if (cliente.PersonEmail != null && cliente.OtherEmail__pc != null && cliente.PersonEmail == cliente.OtherEmail__pc){
                                           if (auxAcc.PersonEmail != null && auxAcc.PersonEmail != cliente.OtherEmail__pc) {
                                               cliente.OtherEmail__pc = auxAcc.PersonEmail;
                                           } else {
                                               cliente.OtherEmail__pc = null;
                                           }
                                       }
                                       if (cliente.OtherEmail__pc == null && auxAcc.PersonEmail != null && cliente.PersonEmail != null && auxAcc.PersonEmail != cliente.PersonEmail){
                                           cliente.OtherEmail__pc = auxAcc.PersonEmail;
                                       }
                                        
                                       if (cliente.PersonMobilePhone == null && cliente.OtherMobilePhone__pc != null ) {
                                           cliente.PersonMobilePhone = cliente.OtherMobilePhone__pc;
                                           cliente.OtherMobilePhone__pc = null;
                                       }
                                       if (cliente.PersonMobilePhone != null && cliente.OtherMobilePhone__pc != null && cliente.PersonMobilePhone == cliente.OtherMobilePhone__pc){
                                           if (auxAcc.PersonMobilePhone != null && auxAcc.PersonMobilePhone != cliente.OtherMobilePhone__pc) {
                                               cliente.OtherMobilePhone__pc = auxAcc.PersonMobilePhone;
                                           } else {
                                               cliente.OtherMobilePhone__pc = null;
                                           }
                                       }
                                       if (cliente.OtherMobilePhone__pc == null && auxAcc.PersonMobilePhone != null && cliente.PersonMobilePhone != null && auxAcc.PersonMobilePhone != cliente.PersonMobilePhone){
                                           cliente.OtherMobilePhone__pc = auxAcc.PersonMobilePhone;
                                       }
                                        
                                       if (cliente.Phone == null && cliente.PersonOtherPhone != null ) {
                                           cliente.Phone = cliente.PersonOtherPhone;
                                           cliente.PersonOtherPhone = null;
                                       }
                                       if (cliente.Phone != null && cliente.PersonOtherPhone != null && cliente.Phone == cliente.PersonOtherPhone){
                                           if (auxAcc.Phone != null && auxAcc.Phone != cliente.PersonOtherPhone) {
                                               cliente.PersonOtherPhone = auxAcc.Phone;
                                           } else {
                                               cliente.PersonOtherPhone = null;
                                           }
                                       }
                                       if (cliente.PersonOtherPhone == null && auxAcc.Phone != null && cliente.Phone != null && auxAcc.Phone != cliente.Phone){
                                           cliente.PersonOtherPhone = auxAcc.Phone;
                                       }
                                        
                                    }
                                    else {
                                       cliente.Email__c = !String.isBlank(cliente.Email__c)?cliente.Email__c:auxAcc.Email__c;
                                       cliente.Other_Email__c = !String.isBlank(cliente.Other_Email__c)?cliente.Other_Email__c:auxAcc.Other_Email__c;
                                       cliente.Phone = !String.isBlank(cliente.Phone)?cliente.Phone:auxAcc.Phone;
                                       cliente.Other_Phone__c = !String.isBlank(cliente.Other_Phone__c)?cliente.Other_Phone__c:auxAcc.Other_Phone__c;
                                       cliente.Mobile__c = !String.isBlank(cliente.Mobile__c)?cliente.Mobile__c:auxAcc.Mobile__c;
                                       cliente.Other_Mobile__c = !String.isBlank(cliente.Other_Mobile__c)?cliente.Other_Mobile__c:auxAcc.Other_Mobile__c;

                                       if (cliente.Email__c == null && cliente.Other_Email__c != null ) {
                                           cliente.Email__c = cliente.Other_Email__c;
                                           cliente.Other_Email__c = null;
                                       }
                                       if (cliente.Email__c != null && cliente.Other_Email__c != null && cliente.Email__c == cliente.Other_Email__c){
                                           if (auxAcc.Email__c != null && auxAcc.Email__c != cliente.Other_Email__c) {
                                               cliente.Other_Email__c = auxAcc.Email__c;
                                           } else {
                                               cliente.Other_Email__c = null;
                                           }
                                       }
                                       if (cliente.Other_Email__c == null && auxAcc.Email__c != null && cliente.Email__c != null && auxAcc.Email__c != cliente.Email__c){
                                           cliente.Other_Email__c = auxAcc.Email__c;
                                       }
                                        
                                       if (cliente.Mobile__c == null && cliente.Other_Mobile__c != null ) {
                                           cliente.Mobile__c = cliente.Other_Mobile__c;
                                           cliente.Other_Mobile__c = null;
                                       }
                                       if (cliente.Mobile__c != null && cliente.Other_Mobile__c != null && cliente.Mobile__c == cliente.Other_Mobile__c){
                                           if (auxAcc.Mobile__c != null && auxAcc.Mobile__c != cliente.Other_Mobile__c) {
                                               cliente.Other_Mobile__c = auxAcc.Mobile__c;
                                           } else {
                                               cliente.Other_Mobile__c = null;
                                           }
                                       }
                                       if (cliente.Other_Mobile__c == null && auxAcc.Mobile__c != null && cliente.Mobile__c != null && auxAcc.Mobile__c != cliente.Mobile__c){
                                           cliente.Other_Mobile__c = auxAcc.Mobile__c;
                                       }
                                        
                                       if (cliente.Phone == null && cliente.Other_Phone__c != null ) {
                                           cliente.Phone = cliente.Other_Phone__c;
                                           cliente.Other_Phone__c = null;
                                       }
                                       if (cliente.Phone != null && cliente.Other_Phone__c != null && cliente.Phone == cliente.Other_Phone__c){
                                           if (auxAcc.Phone != null && auxAcc.Phone != cliente.Other_Phone__c) {
                                               cliente.Other_Phone__c = auxAcc.Phone;
                                           } else {
                                               cliente.Other_Phone__c = null;
                                           }
                                       }
                                       if (cliente.Other_Phone__c == null && auxAcc.Phone != null && cliente.Phone != null && auxAcc.Phone != cliente.Phone){
                                           cliente.Other_Phone__c = auxAcc.Phone;
                                       }

                                    }
                                    duplicado = true;
                                    break; 
                                }
                                else {
                                   new customException('FAIL');
                                }
                            }
                            else {
                               System.debug('NO recordMatch');
                            }
                         } 		
                         else {
                            system.debug('Duplicado con Lead crear registro duplicado: regla:'+ ruleDuplicateDN);
                            system.debug('duplicado:'+  recordDuplicate.getMatchResults()[0].getMatchRecords());
                         }
                    }
                }                                       
            }    
            else {
                System.debug('NO DUPLICATES!');
            }
                
        }
    
        // Crear o actualizar Cuenta de cliente
       	upsert cliente;
        System.debug('INSERT CLIENTE: ' + cliente);
        
        // Añade el contacto relacionado con el cliente a los consentimientos
        Contact conCliente;
        //Si se ha encontrado por duplicado
         cliente = AccountGateway.getAccountById(cliente.Id);
        if(duplicado && cliente.IsPersonAccount){
              //buscamos nuevamente el contact
            mapAccountIdContacts = ContactGateway.getContactByAccountId(new List<String>{cliente.Id});
            conCliente = mapAccountIdContacts.get(cliente.Id);
            for (Consentimientos__c consent :[SELECT Id, ChannelValue__c, Medio_de_contacto__c, RecordTypeId,Contact__c
                                              FROM Consentimientos__c
                                              WHERE Contact__c =:conCliente.Id]) {
                if(mapConsentsByMethoValueToUpsert.containsKey(consent.ChannelValue__c)){
                    Consentimientos__c aux = mapConsentsByMethoValueToUpsert.get(consent.ChannelValue__c);
                    aux.Id = consent.Id;
                    aux.contact__c = consent.contact__c;
                    mapConsentsByMethoValueToUpsert.put(consent.ChannelValue__c, aux);
                }
                else {
                    consent.Medio_de_contacto__c = Label.channelOther;
                    mapConsentsByMethoValueToUpsert.put(consent.ChannelValue__c, consent);
        	}
        	}
        }
        else if(mapAccountIdContacts.isEmpty() && cliente.IsPersonAccount){
            mapAccountIdContacts = ContactGateway.getContactByAccountId(new List<String>{cliente.Id});
            conCliente = mapAccountIdContacts.get(cliente.Id);
        }
        else if(cliente.IsPersonAccount){
             conCliente = mapAccountIdContacts.get(cliente.Id);
        }
          
        //Ponemos a los consentimientos la relacion con el contacto y el tipo de medio de contacto correcto
        for(String value :mapConsentsByMethoValueToUpsert.keySet()){
            Consentimientos__c consent = mapConsentsByMethoValueToUpsert.get(value);
            if (cliente.PersonEmail != null && consent.ChannelValue__c == cliente.PersonEmail){
                consent.Medio_de_contacto__c = Label.channelEmail;
            }
            if (cliente.OtherEmail__pc != null && consent.ChannelValue__c == cliente.OtherEmail__pc){
                consent.Medio_de_contacto__c = Label.channelOtherEmail;
            }
            if (cliente.PersonMobilePhone != null && consent.ChannelValue__c == cliente.PersonMobilePhone){
                consent.Medio_de_contacto__c = Label.channelMobile;
            }
            if (cliente.OtherMobilePhone__pc != null && consent.ChannelValue__c == cliente.OtherMobilePhone__pc){
                consent.Medio_de_contacto__c = Label.channelOtherMobile;
            }
            if (cliente.Phone != null && consent.ChannelValue__c == cliente.Phone){
                consent.Medio_de_contacto__c = Label.channelPhone;
            }
            if (cliente.PersonOtherPhone != null && consent.ChannelValue__c == cliente.PersonOtherPhone){
                consent.Medio_de_contacto__c = Label.channelOtherPhone;
            }
            consent.contact__c = conCliente.Id;
            mapConsentsByMethoValueToUpsert.put(value,consent);
        }
        if (!mapConsentsByMethoValueToUpsert.isEmpty()) {
         	upsert mapConsentsByMethoValueToUpsert.values();
        }
      	system.debug('cliente:devuelto:'+cliente);
        return cliente;
    }
    
    // Crea instancia de  un consentimiento
    private static Consentimientos__c creaConsentimiento(String valor, String channel, String recordTypeName) {
        Consentimientos__c consent = new Consentimientos__c();
		consent.ChannelValue__c = valor;
		consent.Medio_de_contacto__c = channel;
		System.debug('recordtype: ' + rtMapConsentimientoByName);
		System.debug('recordtypeN :  ' + recordTypeName);

		consent.RecordTypeId = rtMapConsentimientoByName.get(recordTypeName).getRecordTypeId();
		consent.CustomerSatisfaction__c = 'Unknown';
		consent.MarketResearch__c = 'Unknown';
		consent.EventInvitation__c = 'Unknown';
		consent.AfterSales__c = 'Unknown';
		consent.ProductSale__c = 'Unknown';
		consent.CustomerSatisfactionSMS__c = 'Unknown';
		consent.MarketResearchSMS__c = 'Unknown';
		consent.AfterSalesSMS__c = 'Unknown';
		consent.ProductSaleSMS__c = 'Unknown';
		consent.EventInvitationSMS__c = 'Unknown';
        consent.EnviarAmulesoft__c = false;
        
        return consent;
    }
    
    // Crea o actualiza registro "Cliente_Concesionario"
    private static void upsertClienteConcesionario(AccountApiRestModel req, Cliente_Concesionario__c clienteConcesionario,Account cliente, Concesionario__c concesionario) {
        List<Cliente_Concesionario__c> cConcesionarioToUpsert = new List<Cliente_Concesionario__c>();
        List<Cliente_Concesionario__c> cConcesionarios = ClienteConcesionarioGateway.searchClienteConcesionariosByAccountId(cliente.Id);
        
        if (clienteConcesionario == null) {
        	clienteConcesionario = new Cliente_Concesionario__c();
            clienteConcesionario.Concesionario__c = concesionario.Id;
            clienteConcesionario.Cliente__c = cliente.Id;
        }
        
        clienteConcesionario.Documento__c = !String.isBlank(req.accountApi.documento) ? req.accountApi.documento.toUpperCase() : cliente.Documento__c;
        clienteConcesionario.Id_Cliente_DMS__c = req.accountApi.customerId;		// y falla aqui ya que no esta declarado el clienteConcesionario
        clienteConcesionario.ID_BillingAddress__c = req.accountApi.billingAddressId;
        clienteConcesionario.ID_ShippingAddress__c = req.accountApi.shippingAddressId;
        clienteConcesionario.External_Id__c = req.accountApi.customerId +'/'+req.accountApi.companyId;
        System.debug('Estamos encima de los metodos de contacto: ' + req.accountApi.methodsOfContact);
        
        for (AccountApiRestModel.MethodsOfContact method : req.accountApi.methodsOfContact) {
            System.debug('MÉTODO DE CONTACTO: ' + method);
            
            if (method.channel == Label.channelWebsite) {
                clienteConcesionario.ID_Website__c = method.id;
            }
            else if (method.channel == Label.channelEmail && !String.isBlank(method.channelFinal)) {
                if (method.channelFinal.equalsIgnoreCase(Label.channelEmail)) {
                    clienteConcesionario.ID_Email__c = method.id;
                    clienteConcesionario.Email__c = method.value.toLowerCase();
                }
                else {
                    clienteConcesionario.ID_OtherEmail__c = method.id;
                    clienteConcesionario.OtherEmail__c = method.value.toLowerCase();
                }
            }
            else if ((method.channel == Label.channelMobile || method.channel == Label.channelPhone) && !String.isBlank(method.channelFinal)) {
                String phone = DataValidations.transformPhone(method.value);
                
                if (method.channelFinal.equalsIgnoreCase(Label.channelPhone)) {
                    clienteConcesionario.ID_Phone__c = method.id;
                    clienteConcesionario.Phone__c = phone;
                }
                else if(method.channelFinal.equalsIgnoreCase(Label.channelOtherPhone)) {
                    clienteConcesionario.ID_OtherPhone__c = method.id;
                    clienteConcesionario.OtherPhone__c = phone;
                }
                else if(method.channelFinal.equalsIgnoreCase(Label.channelMobile)) {
                    clienteConcesionario.ID_PersonMobilePhone__c = method.id;
                    clienteConcesionario.Mobile__c = phone;
                }
                else if (method.channelFinal.equalsIgnoreCase(Label.channelOtherMobile)) {
                    clienteConcesionario.ID_OtherPersonMobilePhone__c = method.id;
                    clienteConcesionario.OtherMobile__c = phone;
                }
            }
        }

        cConcesionarioToUpsert.add(clienteConcesionario);
        
        // Actualizar clienteConcesionarios relacionados con el cliente con el documento
        if (!cConcesionarios.isEmpty()) {
            for (Cliente_Concesionario__c cConcesionario : cConcesionarios) {
                if (!String.isBlank(req.accountApi.documento) && cConcesionario.Id != clienteConcesionario.Id ) {
                    cConcesionario.Documento__c = req.accountApi.documento.toUpperCase(); 
                    cConcesionarioToUpsert.add(cConcesionario);
                }
            }
        }
        List<Cliente_Concesionario__c> cConcesionarioExternal = new List<Cliente_Concesionario__c>();
        List<Cliente_Concesionario__c> cConcesionarioNotExternal = new List<Cliente_Concesionario__c>();
        if (!cConcesionarioToUpsert.isEmpty()) {
            for(Cliente_Concesionario__c cConcesionario : cConcesionarioToUpsert) {
                if(!String.isBlank(cConcesionario.External_Id__c)){
                    cConcesionarioExternal.add(cConcesionario);
                }
                else {
                    cConcesionarioNotExternal.add(cConcesionario);
                }
                
            }  

            if(!cConcesionarioExternal.isEmpty()){
//                upsert cConcesionarioExternal External_Id__c;
                Schema.SObjectField f = Cliente_Concesionario__c.Fields.External_Id__c;
                Database.UpsertResult [] cr = Database.upsert(cConcesionarioExternal, f); 
                for (Database.UpsertResult sr: cr) {
                     if (sr.isSuccess()) {
                         System.debug('Actualiza CConcesionario OK'+ sr.getId());
                     } else {
                         for(Database.Error err : sr.getErrors()) {
                             System.debug('Actualiza CConcesionario ERROR');
                             System.debug(err.getStatusCode() + ': ' + err.getMessage());
                             System.debug('Campos: ' + err.getFields());
                             
                             Exception__c exc = new Exception__c ();
                             exc.idObjetos__c = req.accountApi.customerId+'/'+ req.accountApi.companyId;
                             exc.Exception__c = err.getStatusCode() + '// ' + err.getMessage();
                             exc.Linea__c = 820;
                             exc.JSON_Entrada__c = JSON.serialize(req);
                             exc.Clase_Metodo__c = 'AccountApiRestServiceController.upsertClienteConcesionario';
                        
                             insert exc;
                         }
                     }       
                }
            }    
            
            if(!cConcesionarioNotExternal.isEmpty()){
                upsert cConcesionarioNotExternal;
            }
        }
    }
}