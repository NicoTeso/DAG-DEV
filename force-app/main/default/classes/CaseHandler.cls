public class CaseHandler implements ITriggerHandler {
    private TriggerExecutionHelper infoTrigger = new TriggerExecutionHelper();
    public Map<Id, Schema.RecordTypeInfo> rtMapById = new Map<Id, Schema.RecordTypeInfo>(); 
        
    public Map<String, Gestion_Lead__c> mapGLeadById = new Map<String, Gestion_Lead__c>();

    public Map<String, Detalle_venta__c> mapDetalleVentaByOpportunityId = new Map<String, Detalle_venta__c>();
    
    public Map<String, Opportunity> mapOpportunityById = new Map<String, Opportunity>();

    public Map<String, Pase_de_taller__c> mapPaseTallerById = new Map<String, Pase_de_taller__c>();

    public List<Case> listSendMulesoft = new List<Case>();
    public List<Case> listSendEmail = new List<Case>();
    public List<Case> listSendEmailVO = new List<Case>();
    public Gestion_Lead__c gLead = new Gestion_Lead__c();
    public Map<String,Contact> mapContactByAccountId = new Map<String,Contact>();
    public Map<String,Map<String,Consentimientos__c>> mapConsentimientovalueByAccountId = new Map<String,Map<String,Consentimientos__c>>();
    public Map<String,Map<String,Consentimientos__c>> mapConsentimientovalueByLeadId = new Map<String,Map<String,Consentimientos__c>>();
    public Map<String,Map<String,Consentimientos__c>> mapConsentimientovalueByAOrLToUpsert = new Map<String,Map<String,Consentimientos__c>>();
    public Map<String,Map<String,CampaignMember>> mapCOrLToCMByCampaignId = new Map<String,Map<String,CampaignMember>>();
    public Map<String,Map<String,CampaignMember>> mapCampaignMemberByCOrLByCampaignIdToInsert = new Map<String,Map<String,CampaignMember>>();
    public Map<String,Campaign> mapCampaignById = new Map<String,Campaign>();
    public Map<String, Centro__c> mapCentroById = new Map<String,Centro__c>();
    public Map<String,Concesionario__c> mapConcesionarioById = new Map<String,Concesionario__c>();
    public CaseHandler(Schema.sObjectType soType) {
        InfoTrigger.setTipoHandler(soType);
    }
    
    public TriggerExecutionHelper getInfo() {
        return infoTrigger;
    }
    
    public void bulkBefore() {
        mapGLeadById.clear();
        mapConcesionarioById.clear();
        mapDetalleVentaByOpportunityId.clear();
        mapOpportunityById.clear();
        mapPaseTallerById.clear();
        rtMapById = Schema.SObjectType.Case.getRecordTypeInfosById();
    	List<String> concesionarioPropietarioIds = new List<String>(); 
        if (Trigger.new != null) {
            List<String> listOpportunityId = new List<String>();
            List<String> listPaseTallerId = new List<String>();
            List<String> listCampaign = new List<String>();
            mapGLeadById = CacheUtil.getGestionLeadMap();
            for(SObject objeto :Trigger.new){
                Case caso = (Case) objeto;
                if(caso.Propietario_Vehiculo__c != null){
                    concesionarioPropietarioIds.add(caso.Propietario_Vehiculo__c);
                }
                if(!String.isBlank(caso.RecommendBy__c)){
                    listOpportunityId.add(caso.RecommendBy__c);
                }
                if(!String.isBlank(caso.RecommendByPT__c)){
                    listPaseTallerId.add(caso.RecommendByPT__c);
                }
                if(caso.Campana__c != null){
                    listCampaign.add(caso.Campana__c);
                }
                
            }
            
            if(!concesionarioPropietarioIds.isEmpty()){
                mapConcesionarioById = ConcesionarioGateway.getConcessionaireById(concesionarioPropietarioIds);
            }
            if(!listOpportunityId.isEmpty()){
                mapDetalleVentaByOpportunityId = DetalleVentaGateway.getDetalleVentaByOpportunityId(listOpportunityId);
                mapOpportunityById = OpportunityGateway.getOppById(listOpportunityId);
            }
            if(!listPaseTallerId.isEmpty()){
                mapPaseTallerById = PaseTallerGateway.getPaseTallerById(listPaseTallerId);
            }
            if(!listCampaign.isEmpty()){
                mapCampaignById = CampaignGateway.getCampaignById(listCampaign);
            }
        }
        	
    }
        
    public void bulkAfter() {
        mapGLeadById.clear();
        mapCentroById.clear();
        mapCOrLToCMByCampaignId.clear();
        rtMapById = Schema.SObjectType.Case.getRecordTypeInfosById();
        mapConsentimientovalueByAOrLToUpsert.clear();
    	mapCampaignMemberByCOrLByCampaignIdToInsert.clear();
        mapDetalleVentaByOpportunityId.clear();
        mapOpportunityById.clear();
        mapPaseTallerById.clear();
        mapCampaignById.clear();
        if (Trigger.new != null) {
            List<String> listLeadId = new List<String>();
            List<String> listAccountId = new List<String>();
            List<String> listCampaignId = new List<String>();
            List<String> listCentroId = new List<String>();
            List<String> listOpportunityId = new List<String>();
            List<String> listPaseTallerId = new List<String>();
            for (SObject objeto : Trigger.New) {
                Case caso = (Case) objeto;
                if(!String.isBlank(caso.Lead__c)){
                    listLeadId.add(caso.Lead__c);
                }
                if(!String.isBlank(caso.AccountId)){
                    listAccountId.add(caso.AccountId);
                }  
                if(!String.isBlank(caso.Campana__c)){
                    listCampaignId.add(caso.Campana__c);
                }
                if(!String.isBlank(caso.Centro__c)){
                    listCentroId.add(caso.Centro__c);
                }
                if(!String.isBlank(caso.RecommendBy__c)){
                    listOpportunityId.add(caso.RecommendBy__c);
                }
                if(!String.isBlank(caso.RecommendByPT__c)){
                    listOpportunityId.add(caso.RecommendByPT__c);
                }
            }
           	mapGLeadById = CacheUtil.getGestionLeadMap();
            if(!listAccountId.isEmpty()){
                mapConsentimientovalueByAccountId = ConsentimientosGateway.getConsentimientosByAccountId(listAccountId);
              	mapContactByAccountId = ContactGateway.getContactByAccountId(listAccountId);
            }
            if(!listLeadId.isEmpty()){
                mapConsentimientovalueByLeadId = ConsentimientosGateway.getConsentimientosByLeadId(listLeadId);
            }
            if(!listCampaignId.isEmpty()){
                List<String> listContactId = new List<String>();
                for(Contact contacto :mapContactByAccountId.values()){
                    listContactId.add(contacto.Id);
                }
                mapCOrLToCMByCampaignId = CampaignMemberGateway.getMapCOrLToCampaignMemberByCampaignId(listCampaignId, listContactId, listLeadId );
                mapCampaignById = CampaignGateway.getCampaignById(listCampaignId);
            }
            if(!listOpportunityId.isEmpty()){
                mapDetalleVentaByOpportunityId = DetalleVentaGateway.getDetalleVentaByOpportunityId(listOpportunityId);
                mapOpportunityById = OpportunityGateway.getOppById(listOpportunityId);
                for(Detalle_venta__c detV :mapDetalleVentaByOpportunityId.values()){
                    listCentroId.add(detV.Centro__c);
                }
                for(Opportunity proV :mapOpportunityById.values()){
                    listCentroId.add(proV.Centro__c);
                }
            }
            if(!listPaseTallerId.isEmpty()){
                mapPaseTallerById = PaseTallerGateway.getPaseTallerById(listPaseTallerId);
            }
            if(!listCentroId.isEmpty()){
                mapCentroById = CentroGateway.getCenterById(listCentroId);
            }
        }
    }
    
    public void beforeInsert(sObject so) {
        Case caso = (Case) so;
        String RTDeveloperName = rtMapById.get(caso.RecordTypeId).getDeveloperName();
        
        if (Label.RtCaseGestionLead.equalsIgnoreCase(RTDeveloperName) || Label.RtCaseGestionLeadVO.equalsIgnoreCase(RTDeveloperName)) {
        	if(!String.isBlank(caso.SuppliedPhone)){
                caso.SuppliedPhone = DataValidations.validatePhone(caso.SuppliedPhone)?DataValidations.transformPhone(caso.SuppliedPhone): null;
            }      
            
            if(!String.isBlank(caso.SuppliedEmail) && !DataValidations.validateEmail(caso.SuppliedEmail)){
                caso.SuppliedEmail = null;
            }
            //validación de campo email vacío diferente a campañas hyAmigo
            else if(String.isBlank(caso.SuppliedEmail)){
                 if(caso.Campana__c != null && mapCampaignById.containsKey(caso.Campana__c)){
            		Campaign campania = mapCampaignById.get(caso.Campana__c);
                    if(!Label.CampaignHYAmigo.equalsIgnoreCase(campania.Name)){
                        caso.addError('Email no informado');
                    } 
                }
            }
        }
        
        if (Label.RtCaseGestionLead.equalsIgnoreCase(RTDeveloperName)){
            if( !String.isBlank(caso.Intencion_de_compra__c) &&  caso.Intencion_de_compra__c.contains(Label.IntencionCSorteo)){
                caso.Status = Label.StatusClosed;
                caso.Motivo_de_cierre__c = Label.motivoCierreConcurso; 
            }    
        }
        
        if(Label.RtCaseGestionLeadVO.equalsIgnoreCase(RTDeveloperName)){
           	Concesionario__c concePropietario = mapConcesionarioById.containsKey(caso.Propietario_Vehiculo__c)? mapConcesionarioById.get(caso.Propietario_Vehiculo__c):null;
            if(concePropietario != null && !concePropietario.Es_SIMA__c){
                caso.Status = Label.StatusClosed;
                caso.Motivo_de_cierre__c = Label.motivoCierreConcesionarioExterno; 
            }
            else if( !String.isBlank(caso.Intencion_de_compra__c) &&  caso.Intencion_de_compra__c.contains(Label.IntencionCReserva)){
                if(!String.isBlank(caso.bookingStatus__c) && caso.bookingStatus__c != Label.StatusRPagoRealizado){
                    caso.Status = Label.StatusClosed;
                    caso.Motivo_de_cierre__c =  Label.motivoCierrreReservaFallida;
                }
            }
            if(!String.isBlank(caso.Intencion_de_compra__c) &&  caso.Intencion_de_compra__c.contains(Label.IntencionCInformacion)){
                 if(!String.isBlank(caso.Origin) && caso.Origin.equalsIgnoreCase(Label.origenFeriaAvis)){
                     caso.Status = Label.StatusClosed;
                     caso.Motivo_de_cierre__c = Label.motivoCierreSoloInformacion;
                 }
              }
        }

        if (Label.RtCaseGestionLead.equalsIgnoreCase(RTDeveloperName) && caso.Status != Label.StatusClosed){
            //Si es recomendado lo indicamos en la descripcion
            Gestion_Lead__c gestionLead = new Gestion_Lead__c();
            if (caso.RecommendBy__c != null){
            	Detalle_venta__c DetalleVenta = mapDetalleVentaByOpportunityId.get(caso.RecommendBy__c);
                if (DetalleVenta != null){
                    System.debug('DetalleVenta:'+DetalleVenta);
                    if (caso.Description == null){
                        caso.Description = 'Cliente recomendado por el cliente: '+DetalleVenta.Propietario__r.Name;
                    } else {
                        caso.Description += '\r\nCliente recomendado por el cliente: '+DetalleVenta.Propietario__r.Name;
                    }
                    caso.RecommendByName__c = DetalleVenta.Propietario__r.Name;
                    if (caso.Centro__c == null) {
                        if (DetalleVenta.Centro__r.Activo__c && DetalleVenta.Centro__r.Gestiona_LEAD__c) {
	                        caso.Centro__c = DetalleVenta.Centro__c;
                        }
                    }
                    System.debug('caso.Description: '+caso.Description);
                    System.debug('caso.Centro__c: '+caso.Centro__c);
                } else {
                    Opportunity ProcesoVenta = mapOpportunityById.get(caso.RecommendBy__c);
                    if (ProcesoVenta != null){
                        System.debug('ProcesoVenta:'+ProcesoVenta);
                        if (caso.Description == null){
                            caso.Description = 'Cliente recomendado por el cliente: '+ProcesoVenta.Account.Name;
                        } else {
	                        caso.Description += '\r\nCliente recomendado por el cliente: '+ProcesoVenta.Account.Name;
                        }
                        caso.RecommendByName__c = ProcesoVenta.Account.Name;
                        if (caso.Centro__c == null) {
                            if (ProcesoVenta.Centro__r.Activo__c && ProcesoVenta.Centro__r.Gestiona_LEAD__c) {
                                caso.Centro__c = ProcesoVenta.Centro__c;
                            }
                        }
                        System.debug('caso.Description: '+caso.Description);
                        System.debug('caso.Centro__c: '+caso.Centro__c);
                    }
                }   
            }
            if (caso.RecommendByPT__c != null){
            	Pase_de_taller__c PaseTaller = mapPaseTallerById.get(caso.RecommendByPT__c);
                if (PaseTaller != null){
                    System.debug('PaseTaller:'+PaseTaller);
                    if (caso.Description == null){
                        caso.Description = 'Cliente recomendado por el cliente: '+PaseTaller.customerDepositary__r.Name;
                    } else {
                        caso.Description += '\r\nCliente recomendado por el cliente: '+PaseTaller.customerDepositary__r.Name;
                    }
                    caso.RecommendByName__c = PaseTaller.customerDepositary__r.Name;
                    if (caso.Centro__c == null) {
                        if (PaseTaller.Centro__r.Activo__c && PaseTaller.Centro__r.Gestiona_LEAD__c) {
	                        caso.Centro__c = PaseTaller.Centro__c;
                        }
                    }
                    System.debug('caso.Description: '+caso.Description);
                    System.debug('caso.Centro__c: '+caso.Centro__c);
                }
            }
        }
    }
    
    public void beforeUpdate(sObject old, sObject so) {
        Case caso = (Case) so;
        String RTDeveloperName = rtMapById.get(caso.RecordTypeId).getDeveloperName();
        if (Label.RtCaseGestionLead.equalsIgnoreCase(RTDeveloperName) || Label.RtCaseGestionLeadVO.equalsIgnoreCase(RTDeveloperName)) {
        	if(!String.isBlank(caso.SuppliedPhone)){
                caso.SuppliedPhone =DataValidations.validatePhone(caso.SuppliedPhone)?DataValidations.transformPhone(caso.SuppliedPhone): null;
            }      
            if(!String.isBlank(caso.SuppliedEmail) && !DataValidations.validateEmail(caso.SuppliedEmail)){
                caso.SuppliedEmail = null;
            } 
        }
    }
    
    public void beforeDelete(sObject so) {}
    
    public void afterInsert(sObject so) {
        System.debug('entra en afterInsert');
        //si estos campos vienen llenos: Centro__c, Marca__c, Intencion_de_compra__c
        Case caso = (Case) so;
        Boolean consentimientoSend = true;
        String RTDeveloperName = rtMapById.get(caso.RecordTypeId).getDeveloperName();
        System.debug('RTDeveloperName'+RTDeveloperName);
        System.debug('caso: '+caso);
        System.debug('Label.RtCaseGestionLead'+Label.RtCaseGestionLead);
        //Gestion Lead
        if (Label.RtCaseGestionLead.equalsIgnoreCase(RTDeveloperName) || Label.RtCaseGestionLeadVO.equalsIgnoreCase(RTDeveloperName) ) {
            //gestion automática Lead envio Mulesoft
            if (Label.RtCaseGestionLead.equalsIgnoreCase(RTDeveloperName) && caso.Status != Label.StatusClosed){
                //Si es recomendado lo derivamos al vendedor de la operación desde el que se recomendo, sin intervencion de OPP
                Gestion_Lead__c gestionLead;
                Boolean EnvioGestor = false; 
                if (caso.RecommendBy__c != null){
            	 	Detalle_venta__c DetalleVenta = mapDetalleVentaByOpportunityId.get(caso.RecommendBy__c);
                    if (DetalleVenta != null){
                        if (DetalleVenta.Vendedor__r.Email__c !=null && DetalleVenta.Intermediario__c == null){
                            System.debug('DetalleVenta:'+DetalleVenta);
                            gestionLead = new Gestion_Lead__c();
                            gestionLead.Centro__c = DetalleVenta.Centro__c;
                            gestionLead.Centro_destino__c = DetalleVenta.Centro__c;
                            gestionLead.Gestor_Lead__c = Label.gestorLeadExposicion;
                            gestionLead.Intencion_de_compra__c = caso.Intencion_de_compra__c;
                            gestionLead.Marca__c = caso.Marca__c;
                            gestionLead.Origen__c = caso.Origin;
                            gestionLead.RecordTypeId = Schema.SObjectType.Gestion_Lead__c.getRecordTypeInfosByDeveloperName().get(Label.RtGLeadVN).getRecordTypeId();
                            gestionLead.EmailAsesor__c = DetalleVenta.Vendedor__r.Email__c;
                            System.debug('gestionLead creado:'+gestionLead);
                        } else {
                            //Para los casos con interemediario o con el gestor sin informar se enviara el lead al gestor de lead del centro
                            //que tiene la venta
                            System.debug('entra por aqui');
                            EnvioGestor = true; 
                        }
                    } else {
                    	Opportunity ProcesoVenta = mapOpportunityById.get(caso.RecommendBy__c);
                        if (ProcesoVenta != null){
                            if (ProcesoVenta.Vendedor__r.Email__c !=null){
                                System.debug('ProcesoVenta:'+ProcesoVenta);
                                gestionLead = new Gestion_Lead__c();
                                gestionLead.Centro__c = ProcesoVenta.Centro__c;
                                gestionLead.Centro_destino__c = ProcesoVenta.Centro__c;
                                gestionLead.Gestor_Lead__c = Label.gestorLeadExposicion;
                                gestionLead.Intencion_de_compra__c = caso.Intencion_de_compra__c;
                                gestionLead.Marca__c = caso.Marca__c;
                                gestionLead.Origen__c = caso.Origin;
                                gestionLead.RecordTypeId = Schema.SObjectType.Gestion_Lead__c.getRecordTypeInfosByDeveloperName().get(Label.RtGLeadVN).getRecordTypeId();
                                gestionLead.EmailAsesor__c = ProcesoVenta.Vendedor__r.Email__c;
                                System.debug('gestionLead creado2:'+gestionLead);
                            } else {
                                //Para los casos con interemediario o con el gestor sin informar se enviara el lead al gestor de lead del centro
                                //que tiene el proceso de venta
                                System.debug('entra por aqui 1');
                                EnvioGestor = true; 
                        	}
                        }
                    }   
                } 

                if (caso.RecommendByPT__c != null){
                    System.debug('entra por aqui 2');
                    EnvioGestor = true; 
                } 

                System.debug('caso.Centro__c:'+caso.Centro__c); 
                System.debug('caso.Marca__c:'+caso.Marca__c); 
                System.debug('caso.Intencion_de_compra__c:'+caso.Intencion_de_compra__c);
                System.debug('caso.Origin:'+caso.Origin);

                // Buscamos la Gestion Lead que corresponde al caso
                if (gestionLead == null &&
                    caso.Centro__c != null && 
                    !String.isBlank(caso.Marca__c) && 
                    !String.isBlank(caso.Intencion_de_compra__c) && 
                    !String.isBlank(caso.Origin) ) {
            	 	for (Gestion_Lead__c gLead  :mapGLeadById.values()) {
                		if (Label.RtGLeadVN.equalsIgnoreCase(gLead.RecordType.DeveloperName)
                            && gLead.Centro__c == caso.Centro__c && caso.Marca__c.equalsIgnoreCase(gLead.Marca__c)
                        	&& caso.Intencion_de_compra__c.contains(gLead.Intencion_de_compra__c)
                        	&& caso.Origin == gLead.Origen__c) {
                    		gestionLead = gLead;
                            System.debug('gLead: '+gLead);    
                    		break;
                		}
            		}
                }
                
                //si la gestión lead es de concesionario, se deriava automáticamente
                if (gestionLead != null && (Label.gestorLeadExposicion.equalsIgnoreCase(gestionLead.Gestor_Lead__c) || EnvioGestor)) {
                    System.debug('entra a envio directo');
                    Centro__c centro = mapCentroById.get(gestionLead.Centro__c);
                    if(!centro.Concesionario__r.Es_SIMA__c){
                       listSendEmail.add(caso);
                    }
                    else{
                      	listSendMulesoft.add(caso);
                    }
                    consentimientoSend=false;
                    gLead = gestionLead;
                }
            }
            else if (Label.RtCaseGestionLeadVO.equalsIgnoreCase(RTDeveloperName) && caso.Status != Label.StatusClosed){
                if (caso.Centro__c != null && !String.isBlank(caso.Intencion_de_compra__c) && !String.isBlank(caso.Origin) ) {
            		Gestion_Lead__c gestionLead;
            		for (Gestion_Lead__c gLead  :mapGLeadById.values()) {
                		if (Label.RtGLeadVO.equalsIgnoreCase(gLead.RecordType.DeveloperName)
                            && gLead.Centro__c == caso.Centro__c 
                        	&& caso.Intencion_de_compra__c.contains(gLead.Intencion_de_compra__c)
                        	&& caso.Origin == gLead.Origen__c
                        	) {
                    		gestionLead = gLead;
                    		break;
                		}
            		}
               		 if (gestionLead != null &&  Label.gestorLeadExposicion.equalsIgnoreCase(gestionLead.Gestor_Lead__c)) {
                    	Centro__c centro = mapCentroById.get(caso.Centro__c);
                    	listSendEmailVO.add(caso);
                   		consentimientoSend=false;
                    	gLead = gestionLead;
                	}
        		}
            }
			
            //Consentimientos 
			Campaign campana = caso.Campana__c != null &&  mapCampaignById.containsKey(caso.Campana__c)?mapCampaignById.get(caso.Campana__c):null;
            if(Label.RtCaseGestionLead.equalsIgnoreCase(RTDeveloperName) && campana != null && campana.Name.equalsIgnoreCase(Label.CampaignHYAmigo)){
                //Consentimiento Lead para campaña HY Amigo
                if(!String.isBlank(caso.Lead__c) && mapConsentimientovalueByLeadId.containsKey(caso.Lead__c)){
                	Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.Lead__c)?mapConsentimientovalueByAOrLToUpsert.get(caso.Lead__c): new Map<String,Consentimientos__c>();
                    Map<String,Consentimientos__c> mapConsentimientoByValue = mapConsentimientovalueByLeadId.get(caso.Lead__c);
                    if(!String.isBlank(caso.SuppliedEmail)){
                        String email = caso.SuppliedEmail.toLowerCase();
                        Consentimientos__c consentimientoToUpdate;
                        if(!mapConsentimientoByValue.containsKey(email)){
                            consentimientoToUpdate = CaseHelper.CreateConsentimientoBase(email, caso, Label.channelEmail );
                            consentimientoToUpdate.Lead__c = caso.Lead__c;
                        	consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        	mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate); 
                        }
                       
                    }
                	if(!String.isBlank(caso.SuppliedPhone)){
                        Consentimientos__c consentimientoToUpdate;
                        String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                        if(!mapConsentimientoByValue.containsKey(caso.SuppliedPhone)){
                            consentimientoToUpdate = CaseHelper.createConsentimientoBase(caso.SuppliedPhone, caso, tipo);
                            consentimientoToUpdate.Lead__c = caso.Lead__c;
                        	consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        	mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                        }
                        
                    }
                	if(!mapConsentimietosByValueToUpsert.isEmpty()){
                     	mapConsentimientovalueByAOrLToUpsert.put(caso.Lead__c,mapConsentimietosByValueToUpsert);
                 	}
             }
            	else if(!String.isBlank(caso.Lead__c)){
                    //Son nuevos
                    Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.Lead__c)?mapConsentimientovalueByAOrLToUpsert.get(caso.Lead__c): new Map<String,Consentimientos__c>();
                    if(!String.isBlank(caso.SuppliedEmail)){
                        String email = caso.SuppliedEmail.toLowerCase();
                        Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimientoBase(email, caso, Label.channelEmail );
                        consentimientoToUpdate.Lead__c = caso.Lead__c;
                        consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate);
                    }
                	if(!String.isBlank(caso.SuppliedPhone)){
                        String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                        Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimientoBase(caso.SuppliedPhone, caso, tipo);
                        consentimientoToUpdate.Lead__c = caso.Lead__c;
                        consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                    }
                	if(!mapConsentimietosByValueToUpsert.isEmpty()){
                     	mapConsentimientovalueByAOrLToUpsert.put(caso.Lead__c,mapConsentimietosByValueToUpsert);
                 	}
            }
                
                //Consentimientos Account para campaña HY Amigo
            	system.debug('mapContactByAccountId:'+ mapContactByAccountId);
            	system.debug('mapConsentimientovalueByAccountId:' +mapConsentimientovalueByAccountId);
            	if(!String.isBlank(caso.AccountId) && mapContactByAccountId.containsKey(caso.AccountId) && mapConsentimientovalueByAccountId.containsKey(caso.AccountId)){
                    //buscar o crear consentimientos para cuentas
                    Contact contacto = mapContactByAccountId.get(caso.AccountId);
                    if(contacto.Account.IsPersonAccount){
                        Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.AccountId)?mapConsentimientovalueByAOrLToUpsert.get(caso.AccountId): new Map<String,Consentimientos__c>();
                        Map<String,Consentimientos__c> mapConsentimientoByValue = mapConsentimientovalueByAccountId.get(caso.AccountId);
                        if(!String.isBlank(caso.SuppliedEmail)){
                            String email = caso.SuppliedEmail.toLowerCase();
                            Consentimientos__c consentimientoToUpdate;
                            if(!mapConsentimientoByValue.containsKey(email)){
                                consentimientoToUpdate = CaseHelper.createConsentimientoBase(email, caso, Label.channelEmail );
                                consentimientoToUpdate.Contact__c = contacto.Id ;
                                consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                                consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                                mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate);
                            }
                        }
                        if(!String.isBlank(caso.SuppliedPhone)){
                            Consentimientos__c consentimientoToUpdate;
                            String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                            if(!mapConsentimientoByValue.containsKey(caso.SuppliedPhone)){
                                consentimientoToUpdate = CaseHelper.createConsentimientoBase(caso.SuppliedPhone, caso, tipo);
                                consentimientoToUpdate.Contact__c = contacto.Id;
                                consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                                consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                                mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                            }
                            
                        }
                        if(!mapConsentimietosByValueToUpsert.isEmpty()){
                            mapConsentimientovalueByAOrLToUpsert.put(caso.AccountId,mapConsentimietosByValueToUpsert);
                        }
                        
                    }
            	}
            	else if(!String.isBlank(caso.AccountId) && mapContactByAccountId.containsKey(caso.AccountId)){
                    //Son nuevos
                    Contact contacto = mapContactByAccountId.get(caso.AccountId);
                    if(contacto.Account.IsPersonAccount){
                        Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.AccountId)?mapConsentimientovalueByAOrLToUpsert.get(caso.AccountId): new Map<String,Consentimientos__c>();
                        //Map<String,Consentimientos__c> mapConsentimientoByValue = new Map<String,Consentimientos__c>();
                        if(!String.isBlank(caso.SuppliedEmail)){
                            String email = caso.SuppliedEmail.toLowerCase();
                            Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimientoBase(email, caso, Label.channelEmail );
                            consentimientoToUpdate.Contact__c = contacto.Id;
                            consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                            consentimientoToUpdate.EnviarAmulesoft__c =false;
                            mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate);
                        }
                        if(!String.isBlank(caso.SuppliedPhone)){
                            String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                            Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimientoBase(caso.SuppliedPhone, caso, tipo);
                            consentimientoToUpdate.Contact__c = contacto.Id;
                            consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                            consentimientoToUpdate.EnviarAmulesoft__c =false;
                            mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                        }
                        if(!mapConsentimietosByValueToUpsert.isEmpty()){
                            mapConsentimientovalueByAOrLToUpsert.put(caso.AccountId,mapConsentimietosByValueToUpsert);
                        }
                    }
                        
            	}
            }
            else {
                //Consentimientos lead genérico
                if(!String.isBlank(caso.Lead__c) && mapConsentimientovalueByLeadId.containsKey(caso.Lead__c)){
                	Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.Lead__c)?mapConsentimientovalueByAOrLToUpsert.get(caso.Lead__c): new Map<String,Consentimientos__c>();
                    Map<String,Consentimientos__c> mapConsentimientoByValue = mapConsentimientovalueByLeadId.get(caso.Lead__c);
                    if(!String.isBlank(caso.SuppliedEmail)){
                        String email = caso.SuppliedEmail.toLowerCase();
                        Consentimientos__c consentimientoToUpdate;
                        if(mapConsentimientoByValue.containsKey(email)){
                            consentimientoToUpdate = mapConsentimientoByValue.get(email);
                            consentimientoToUpdate = CaseHelper.AssigmentConsentimientos(consentimientoToUpdate,caso,Label.channelEmail);
                        }
                        else {
                            consentimientoToUpdate = CaseHelper.createConsentimiento(email, caso, Label.channelEmail );
                        }
                        if(consentimientoToUpdate != null){
                            consentimientoToUpdate.Lead__c = caso.Lead__c;
                        	consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        	mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate); 
                        }
                       
                    }
                	if(!String.isBlank(caso.SuppliedPhone)){
                        Consentimientos__c consentimientoToUpdate;
                        String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                        if(mapConsentimientoByValue.containsKey(caso.SuppliedPhone)){
                            consentimientoToUpdate = mapConsentimientoByValue.get(caso.SuppliedPhone);
                            consentimientoToUpdate = CaseHelper.AssigmentConsentimientos(consentimientoToUpdate,caso,tipo);
                     	}
                        else {
                            consentimientoToUpdate = CaseHelper.createConsentimiento(caso.SuppliedPhone, caso, tipo);
                        }
                        if(consentimientoToUpdate != null){
                            consentimientoToUpdate.Lead__c = caso.Lead__c;
                        	consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        	mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                        }
                        
                    }
                	if(!mapConsentimietosByValueToUpsert.isEmpty()){
                     	mapConsentimientovalueByAOrLToUpsert.put(caso.Lead__c,mapConsentimietosByValueToUpsert);
                 	}
             }
            	else if(!String.isBlank(caso.Lead__c)){
                    //Son nuevos
                    Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.Lead__c)?mapConsentimientovalueByAOrLToUpsert.get(caso.Lead__c): new Map<String,Consentimientos__c>();
                    if(!String.isBlank(caso.SuppliedEmail)){
                        String email = caso.SuppliedEmail.toLowerCase();
                        Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimiento(email, caso, Label.channelEmail );
                        consentimientoToUpdate.Lead__c = caso.Lead__c;
                        consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate);
                    }
                	if(!String.isBlank(caso.SuppliedPhone)){
                        String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                        Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimiento(caso.SuppliedPhone, caso, tipo);
                        consentimientoToUpdate.Lead__c = caso.Lead__c;
                        consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                    }
                	if(!mapConsentimietosByValueToUpsert.isEmpty()){
                     	mapConsentimientovalueByAOrLToUpsert.put(caso.Lead__c,mapConsentimietosByValueToUpsert);
                 	}
            }
            
            	//Consentimientos Account genérico
            	system.debug('mapContactByAccountId:'+ mapContactByAccountId);
            	system.debug('mapConsentimientovalueByAccountId:' +mapConsentimientovalueByAccountId);
            	if(!String.isBlank(caso.AccountId) && mapContactByAccountId.containsKey(caso.AccountId) && mapConsentimientovalueByAccountId.containsKey(caso.AccountId)){
                    //buscar o crear consentimientos para cuentas
                    Contact contacto = mapContactByAccountId.get(caso.AccountId);
                    if(contacto.Account.IsPersonAccount){
                        Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.AccountId)?mapConsentimientovalueByAOrLToUpsert.get(caso.AccountId): new Map<String,Consentimientos__c>();
                        Map<String,Consentimientos__c> mapConsentimientoByValue = mapConsentimientovalueByAccountId.get(caso.AccountId);
                        if(!String.isBlank(caso.SuppliedEmail)){
                            String email = caso.SuppliedEmail.toLowerCase();
                            Consentimientos__c consentimientoToUpdate;
                            if(mapConsentimientoByValue.containsKey(email)){
                                consentimientoToUpdate = mapConsentimientoByValue.get(email);
                                consentimientoToUpdate = CaseHelper.AssigmentConsentimientos(consentimientoToUpdate,caso,Label.channelEmail);
                            }
                            else {
                                consentimientoToUpdate = CaseHelper.createConsentimiento(email, caso, Label.channelEmail );
                            }
                            if(consentimientoToUpdate != null){
                                consentimientoToUpdate.Contact__c = contacto.Id ;
                                consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                                consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                                mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate);
                            }
                            
                        }
                        if(!String.isBlank(caso.SuppliedPhone)){
                            Consentimientos__c consentimientoToUpdate;
                            String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                            if(mapConsentimientoByValue.containsKey(caso.SuppliedPhone)){
                                consentimientoToUpdate = mapConsentimientoByValue.get(caso.SuppliedPhone);
                                consentimientoToUpdate = CaseHelper.AssigmentConsentimientos(consentimientoToUpdate,caso,tipo);
                            }
                            else {
                                consentimientoToUpdate = CaseHelper.createConsentimiento(caso.SuppliedPhone, caso, tipo);
                            }
                            if(consentimientoToUpdate != null){
                                consentimientoToUpdate.Contact__c = contacto.Id;
                                consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                                consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                                mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                            }
                            
                        }
                        if(!mapConsentimietosByValueToUpsert.isEmpty()){
                            mapConsentimientovalueByAOrLToUpsert.put(caso.AccountId,mapConsentimietosByValueToUpsert);
                        }
                        
                    }
            	}
            	else if(!String.isBlank(caso.AccountId) && mapContactByAccountId.containsKey(caso.AccountId)){
                    //Son nuevos
                    Contact contacto = mapContactByAccountId.get(caso.AccountId);
                    if(contacto.Account.IsPersonAccount){
                        Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.AccountId)?mapConsentimientovalueByAOrLToUpsert.get(caso.AccountId): new Map<String,Consentimientos__c>();
                        //Map<String,Consentimientos__c> mapConsentimientoByValue = new Map<String,Consentimientos__c>();
                        if(!String.isBlank(caso.SuppliedEmail)){
                            String email = caso.SuppliedEmail.toLowerCase();
                            Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimiento(email, caso, Label.channelEmail );
                            consentimientoToUpdate.Contact__c = contacto.Id;
                            consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                            consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                            mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate);
                        }
                        if(!String.isBlank(caso.SuppliedPhone)){
                            String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                            Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimiento(caso.SuppliedPhone, caso, tipo);
                            consentimientoToUpdate.Contact__c = contacto.Id;
                            consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                            consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                            mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                        }
                        if(!mapConsentimietosByValueToUpsert.isEmpty()){
                            mapConsentimientovalueByAOrLToUpsert.put(caso.AccountId,mapConsentimietosByValueToUpsert);
                        }
                    }
                        
            	}
            	system.debug('consentimiento to send Mulesoft: '+consentimientoSend);
            
            }
			
            //CampaignMember
            if(!String.isBlank(caso.Campana__c) ){
                Map<String,CampaignMember> mapCOrLToCMB = mapCOrLToCMByCampaignId.containsKey(caso.Campana__c)? mapCOrLToCMByCampaignId.get(caso.Campana__c): new Map<String,CampaignMember>();
                if(!String.isBlank(caso.AccountId) && mapContactByAccountId.containsKey(caso.AccountId)){
                    Contact contacto = mapContactByAccountId.get(caso.AccountId);
                    if(!mapCOrLToCMB.containsKey(contacto.Id)){
                        Map<String,CampaignMember> mapCampaignMemberToInsert = mapCampaignMemberByCOrLByCampaignIdToInsert.containsKey(caso.Campana__c)?mapCampaignMemberByCOrLByCampaignIdToInsert.get(caso.Campana__c): new Map<String,CampaignMember>();
                        if(!mapCampaignMemberToInsert.containsKey(contacto.Id)){
                        	CampaignMember cMember = new CampaignMember();
                    		cMember.CampaignId = caso.Campana__c;
                    		cMember.ContactId = contacto.Id;
                    		cMember.Status = Label.StatustResponded;
                    		mapCampaignMemberToInsert.put(cMember.ContactId, cMember);
                            mapCampaignMemberByCOrLByCampaignIdToInsert.put(caso.Campana__c,mapCampaignMemberToInsert);
						}
                    }
                }
                if(!String.isBlank(caso.Lead__c) && !mapCOrLToCMB.containsKey(caso.Lead__c)){
                    Map<String,CampaignMember> mapCampaignMemberToInsert = mapCampaignMemberByCOrLByCampaignIdToInsert.containsKey(caso.Campana__c)?mapCampaignMemberByCOrLByCampaignIdToInsert.get(caso.Campana__c): new Map<String,CampaignMember>();
                        if(!mapCampaignMemberToInsert.containsKey(caso.Lead__c)){
                        	CampaignMember cMember = new CampaignMember();
                    		cMember.CampaignId = caso.Campana__c;
                    		cMember.LeadId = caso.Lead__c;
                    		cMember.Status = Label.StatustResponded;
                    		mapCampaignMemberToInsert.put(cMember.LeadId,cMember);
                            mapCampaignMemberByCOrLByCampaignIdToInsert.put(caso.Campana__c,mapCampaignMemberToInsert);
                            
                        }
                }
            }
            
        }
        
    }
    
    public void afterUpdate(sObject old, sObject so) {
        Case caso = (Case) so;
        Case oldCaso = (Case) old;
        Boolean consentimientoSend = system.isBatch() || system.isScheduled() || system.isFuture() ?false:true;
        String RTDeveloperName = rtMapById.get(caso.RecordTypeId).getDeveloperName();
        //Gestion Lead
        if (Label.RtCaseGestionLead.equalsIgnoreCase(RTDeveloperName) || Label.RtCaseGestionLeadVO.equalsIgnoreCase(RTDeveloperName) ) {
            
            //Consentimientos Account
            if(!String.isBlank(caso.AccountId) && oldCaso.AccountId != caso.AccountId && mapContactByAccountId.containsKey(caso.AccountId) && mapConsentimientovalueByAccountId.containsKey(caso.AccountId)){
                //buscar o crear consentimientos para cuentas
                Contact contacto = mapContactByAccountId.get(caso.AccountId);
                if(contacto.Account.IsPersonAccount){
					Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.AccountId)?mapConsentimientovalueByAOrLToUpsert.get(caso.AccountId): new Map<String,Consentimientos__c>();
                    Map<String,Consentimientos__c> mapConsentimientoByValue = mapConsentimientovalueByAccountId.get(caso.AccountId);
                	if(!String.isBlank(caso.SuppliedEmail)){
                        String email = caso.SuppliedEmail.toLowerCase();
                        Consentimientos__c consentimientoToUpdate;
                        if(mapConsentimientoByValue.containsKey(email)){
                            consentimientoToUpdate = CaseHelper.AssigmentConsentimientos(mapConsentimientoByValue.get(email),caso,Label.channelEmail);
                        }
                        else {
                            consentimientoToUpdate = CaseHelper.createConsentimiento(email, caso, Label.channelEmail );
                        }
                        if(consentimientoToUpdate !=null){
                        	consentimientoToUpdate.Contact__c = contacto.Id ;
                        	consentimientoToUpdate.Fecha_de_captura__c =caso.CreatedDate;
                        	consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                        	mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate);
                        }
                    }
                	if(!String.isBlank(caso.SuppliedPhone)){
                        Consentimientos__c consentimientoToUpdate;
                        String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                        if(mapConsentimientoByValue.containsKey(caso.SuppliedPhone)){
                            consentimientoToUpdate = CaseHelper.AssigmentConsentimientos(mapConsentimientoByValue.get(caso.SuppliedPhone),caso,tipo);
                        }
                        else {
                            consentimientoToUpdate = CaseHelper.createConsentimiento(caso.SuppliedPhone, caso, tipo);
                        }
                        if(consentimientoToUpdate != null){
                            consentimientoToUpdate.Contact__c = contacto.Id;
                        	consentimientoToUpdate.Fecha_de_captura__c =caso.CreatedDate;
                        	consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                        	mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                        }
                        
                    }
                    if(!mapConsentimietosByValueToUpsert.isEmpty()){
                     	mapConsentimientovalueByAOrLToUpsert.put(caso.AccountId,mapConsentimietosByValueToUpsert);
                 	}
                    
              	}
            }
            else if(!String.isBlank(caso.AccountId)&& oldCaso.AccountId != caso.AccountId  && mapContactByAccountId.containsKey(caso.AccountId)){
                //Son nuevos
                Contact contacto = mapContactByAccountId.get(caso.AccountId);
                if(contacto.Account.IsPersonAccount){
                    Map<String,Consentimientos__c> mapConsentimietosByValueToUpsert = mapConsentimientovalueByAOrLToUpsert.containsKey(caso.AccountId)?mapConsentimientovalueByAOrLToUpsert.get(caso.AccountId): new Map<String,Consentimientos__c>();
                    //Map<String,Consentimientos__c> mapConsentimientoByValue = new Map<String,Consentimientos__c>();
                	if(!String.isBlank(caso.SuppliedEmail)){
                		String email = caso.SuppliedEmail.toLowerCase();
                    	Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimiento(email, caso, Label.channelEmail );
                    	consentimientoToUpdate.Contact__c = contacto.Id;
                        consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                        mapConsentimietosByValueToUpsert.put(email,consentimientoToUpdate);
                    }
                	if(!String.isBlank(caso.SuppliedPhone)){
                        String tipo = DataValidations.isMobile(caso.SuppliedPhone)? Label.channelMobile : Label.channelPhone;
                        Consentimientos__c consentimientoToUpdate = CaseHelper.createConsentimiento(caso.SuppliedPhone, caso, tipo);
                        consentimientoToUpdate.Contact__c = contacto.Id;
                        consentimientoToUpdate.Fecha_de_captura__c =Datetime.now();
                        consentimientoToUpdate.EnviarAmulesoft__c =consentimientoSend;
                        mapConsentimietosByValueToUpsert.put(caso.SuppliedPhone,consentimientoToUpdate);
                    }
                	if(!mapConsentimietosByValueToUpsert.isEmpty()){
                     	mapConsentimientovalueByAOrLToUpsert.put(caso.AccountId,mapConsentimietosByValueToUpsert);
                 	}
                }
                	
            }
            system.debug('consentimiento to send Mulesoft: '+consentimientoSend);
            
            //CampaignMember
            if(!String.isBlank(caso.Campana__c) ){
                Map<String,CampaignMember> mapCOrLToCMB = mapCOrLToCMByCampaignId.containsKey(caso.Campana__c)? mapCOrLToCMByCampaignId.get(caso.Campana__c): new Map<String,CampaignMember>();
                if(!String.isBlank(caso.AccountId) && mapContactByAccountId.containsKey(caso.AccountId)){
                    Contact contacto = mapContactByAccountId.get(caso.AccountId);
                    if(!mapCOrLToCMB.containsKey(contacto.Id)){
                        Map<String,CampaignMember> mapCampaignMemberToInsert = mapCampaignMemberByCOrLByCampaignIdToInsert.containsKey(caso.Campana__c)?mapCampaignMemberByCOrLByCampaignIdToInsert.get(caso.Campana__c): new Map<String,CampaignMember>();
                        if(!mapCampaignMemberToInsert.containsKey(contacto.Id)){
                        	CampaignMember cMember = new CampaignMember();
                    		cMember.CampaignId = caso.Campana__c;
                    		cMember.ContactId = contacto.Id;
                    		cMember.Status = Label.StatustResponded;
                    		mapCampaignMemberToInsert.put(cMember.ContactId, cMember);
                            mapCampaignMemberByCOrLByCampaignIdToInsert.put(caso.Campana__c,mapCampaignMemberToInsert);
						}
                    }
                }
            }
            
        }
               
    }
    public void afterDelete(sObject so) {}
    
    public void andFinally() {
        
        if(!mapConsentimientovalueByAOrLToUpsert.isEmpty()){
            List<Consentimientos__c> listToUpsert = new List<Consentimientos__c>();
            for(String stringId :mapConsentimientovalueByAOrLToUpsert.keySet()){
                Map<String,Consentimientos__c> mapConsentimientoByValue = mapConsentimientovalueByAOrLToUpsert.get(stringId);
                listToUpsert.addAll(mapConsentimientoByValue.values());
            }
            upsert listToUpsert;
            
        }
        system.debug('mapCampaignMemberByCOrLByCampaignIdToInsert:'+ mapCampaignMemberByCOrLByCampaignIdToInsert);
                
        if(!mapCampaignMemberByCOrLByCampaignIdToInsert.isEmpty()){
            List<CampaignMember> listCampaignMemberToInsert = new List<CampaignMember>();
            for(String campaignId :mapCampaignMemberByCOrLByCampaignIdToInsert.keySet()){
                Map<String,CampaignMember> mapCampaignMemberToInsert = mapCampaignMemberByCOrLByCampaignIdToInsert.get(campaignId);
            	system.debug('mapCampaignMemberToInsert:'+ mapCampaignMemberToInsert);
                
                listCampaignMemberToInsert.addAll(mapCampaignMemberToInsert.values());
            }
            Upsert listCampaignMemberToInsert;
        }
        
        if (!listSendMulesoft.isEmpty()) {
            system.debug('listSendMulesoft: ' + listSendMulesoft);
            String JSONCases = JSON.serialize(listSendMulesoft);
            String JSONgLead = JSON.serialize(gLead);
            ExternalServiceController.createExternalLeadOrAccountMulesoft(JSONCases, JSONgLead);
            //enviar caso a Mulesoft;
        }
        if (!listSendEmail.isEmpty()) {
            system.debug('listSendEmail: ' + listSendEmail);
            String JSONCases = JSON.serialize(listSendEmail);
            String JSONgLead = JSON.serialize(gLead);
            ExternalServiceController.sendExternalLeadOrAccountEmail(JSONCases, JSONgLead);
            //enviar caso a Mulesoft;
        }
        
        if (!listSendEmailVO.isEmpty()) {
            system.debug('listSendEmailVO: ' + listSendEmailVO);
            String JSONCases = JSON.serialize(listSendEmailVO);
            String JSONgLead = JSON.serialize(gLead);
            ExternalServiceController.sendExternalLeadOrAccountVO(JSONCases, JSONgLead);
            //enviar caso a Mulesoft;
        }
    }
}