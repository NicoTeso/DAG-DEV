public class WorkshopOrderApiRestController {
     public static ResponseApi createworkshopOrder(WorkshopOrderApiRestModel req) {
        ResponseApi response = new ResponseApi();
        
        try {
            Pase_de_taller__c paseTaller = new Pase_de_taller__c();
            if(String.isBlank(req.payload.workshopOrderId)){
            	throw new CustomException(Label.errorMessage_workshopOrderIdEmpty);
        	}
            paseTaller.workshopOrderId__c = req.payload.workshopOrderId;
            paseTaller.workshopCode__c = req.payload.workshopCode;
            
            String centroIdExterno = req.payload.companyCode + '-' + req.payload.centerCode;
            Centro__c centro = CentroGateway.getCenterByIdCentroSima(centroIdExterno);
            if (centro == null) {
                throw new CustomException(Label.errorMessage_centerNotFound);
            }
            paseTaller.Centro__c = centro.id;
            paseTaller.Concesionario__c = centro.Concesionario__c;
            
            Salesman__c serviceAdviser = !String.isBlank(req.payload.serviceAdviserEmail) ? SalesmanGateway.getSalesmanByEmail(req.payload.serviceAdviserEmail.toLowerCase()):null;
            if (serviceAdviser == null && !String.isBlank(req.payload.serviceAdviserEmail) ) {
                serviceAdviser = new Salesman__c();
                serviceAdviser.Name = req.payload.serviceAdviserEmail.toLowerCase();
                serviceAdviser.Email__c = req.payload.serviceAdviserEmail.toLowerCase();
                insert serviceAdviser;
            }
            paseTaller.serviceAdviser__c = serviceAdviser != null?serviceAdviser.Id:null;
            
            List<String> externalId = new List<String>();
            String externalIdCustomer;
            String externalIdDepositary;
            String externalIdOwner;
            if (req.payload.customerId != null) {
                externalIdCustomer = req.payload.customerId + '/' + req.payload.companyCode;
                externalId.add(externalIdCustomer);
            }
            if (req.payload.customerDepositaryId != null) {
                externalIdDepositary = req.payload.customerDepositaryId + '/' + req.payload.companyCode;
                externalId.add(externalIdDepositary);
            }
            if (req.payload.customerOwnerId != null) {
                externalIdOwner = req.payload.customerOwnerId + '/' + req.payload.companyCode;
                externalId.add(externalIdOwner);
            }
            Map<String,Cliente_Concesionario__c> mapCConcesionario = ClienteConcesionarioGateway.getClienteConcesionarioByIdExternal(externalId);
            if(mapCConcesionario.containsKey(externalIdCustomer)){
                Cliente_Concesionario__c cConcesionario = mapCConcesionario.get(externalIdCustomer);
            	paseTaller.customer__c = cConcesionario.Cliente__c;
            }
            else if (externalIdCustomer != null) {
                   throw new CustomException(Label.errorMessage_clientNotFound);
            }
            if(mapCConcesionario.containsKey(externalIdDepositary)){
                Cliente_Concesionario__c cConcesionario = mapCConcesionario.get(externalIdDepositary);
            	paseTaller.customerDepositary__c = cConcesionario.Cliente__c;
            }
            else if (externalIdDepositary != null) {
            	throw new CustomException(Label.errorMessage_depositoryNotFound);
            }
            if(mapCConcesionario.containsKey(externalIdOwner)){
                Cliente_Concesionario__c cConcesionario = mapCConcesionario.get(externalIdOwner);
            	paseTaller.customerOwner__c = cConcesionario.Cliente__c;
            } else if (externalIdOwner != null) {
    			throw new CustomException(Label.errorMessage_ownerNotFound);
            }

            if(String.isBlank(req.PayLoad.vin)){
            	throw new CustomException(Label.errorMessage_VinEmpty);
        	}
            String vin = req.payLoad.vin.toUpperCase();
            Vehiculo__c vehicle = VehiculoGateway.getVehicleByVin(vin);
            if(vehicle !=null){
                if (vehicle.Fecha_primera_matriculacion__c == null){
                    vehicle.Fecha_primera_matriculacion__c = !String.isBlank(req.payload.registrationPlateDate) ? Datetime.valueOf(req.payload.registrationPlateDate.replace('T', ' ')) : null;
                    vehicle.Name = req.payload.registrationPlate;
                }    

                if (vehicle.kms__c < req.payload.mileage){
                    vehicle.kms__c = req.payload.mileage;
                    vehicle.Fecha_actualizacion_Kms__c = !String.isBlank(req.payload.deliveryDate) ? Datetime.valueOf(req.payload.deliveryDate.replace('T',' ')) : Datetime.now();

                    if (vehicle.Fecha_primera_matriculacion__c != null){
                        vehicle.Dias_actualizacion_kms__c = vehicle.Fecha_primera_matriculacion__c.date().daysBetween(vehicle.Fecha_actualizacion_kms__c.date()); 
                        vehicle.kms_diarios__c = vehicle.kms__c != 0 && vehicle.Dias_actualizacion_kms__c != 0 ? vehicle.kms__c.divide(vehicle.Dias_actualizacion_kms__c, 0, System.RoundingMode.UP) : 0;                      
                    } 
                }

                if (externalIdOwner != null && vehicle.Propietario__c != mapCConcesionario.get(externalIdOwner).Cliente__c){
                    vehicle.Propietario__c = mapCConcesionario.get(externalIdOwner).Cliente__c;
                    vehicle.Fecha_desde__c = !String.isBlank(req.payload.deliveryDate) ? Datetime.valueOf(req.payload.deliveryDate.replace('T', ' ')) : Datetime.now();
                }

                vehicle.Depositario__c = mapCConcesionario.get(externalIdDepositary).Cliente__c;

                vehicle.Concesionario_Taller__c = centro.Concesionario__c;
                vehicle.Centro_Taller__c = centro.Id; 
                
            }
            else {
                vehicle = new Vehiculo__c();
                if (externalIdOwner != null) {
                    vehicle.Propietario__c = mapCConcesionario.get(externalIdOwner).Cliente__c;
                    vehicle.Depositario__c = mapCConcesionario.get(externalIdDepositary).Cliente__c;
                    vehicle.Comprador__c = mapCConcesionario.get(externalIdOwner).Cliente__c;
                } else {
                    vehicle.Propietario__c = mapCConcesionario.get(externalIdDepositary).Cliente__c;
                    vehicle.Depositario__c = mapCConcesionario.get(externalIdDepositary).Cliente__c;
                }

                vehicle.Concesionario_Taller__c = centro.Concesionario__c;
                vehicle.Centro_Taller__c = centro.Id; 
                vehicle.Name = req.payload.registrationPlate;
                vehicle.VIN__c = vin;
                vehicle.MarcaString__c = !String.isBlank(req.payload.brand) ? req.payload.brand.toUpperCase() : null;
                vehicle.ModeloString__c = !String.isBlank(req.payload.model)? req.payload.model.toUpperCase() : null;
                vehicle.Codigo_de_modelo__c = !String.isBlank(req.payload.modelCode) ? req.payload.modelCode:null;
                vehicle.Version__c = req.payload.version;
                vehicle.modelDescription__c = req.payload.engine;
                vehicle.Ano_Modelo__c = req.payload.modelYear;
                vehicle.Potencia__c = req.payload.power;
                vehicle.Cilindrada__c = req.payload.enginecapacity;
                vehicle.Combustible__c = req.payload.fuelCode;
                vehicle.Transmision__c = req.payload.transmission;
                vehicle.Letra_Motor__c = req.payload.engineLetter;
                vehicle.Numero_de_Motor__c = req.payload.engineNumber;
                vehicle.Codigo_Motor__c = req.payload.engineCode;
                vehicle.kms__c = req.payload.mileage;
                vehicle.Fecha_actualizacion_Kms__c = !String.isBlank(req.payload.deliveryDate) ? Datetime.valueOf(req.payload.deliveryDate.replace('T',' ')) : Datetime.now();
                vehicle.Fecha_primera_matriculacion__c = !String.isBlank(req.payload.registrationPlateDate) ? Datetime.valueOf(req.payload.registrationPlateDate.replace('T', ' ')) : null;

                if (vehicle.Fecha_primera_matriculacion__c != null){
                    vehicle.Dias_actualizacion_kms__c = vehicle.Fecha_primera_matriculacion__c.date().daysBetween(vehicle.Fecha_actualizacion_kms__c.date()); 
                    vehicle.kms_diarios__c = vehicle.kms__c != 0 && vehicle.Dias_actualizacion_kms__c != 0 ? vehicle.kms__c.divide(vehicle.Dias_actualizacion_kms__c, 0, System.RoundingMode.UP) : 0;                      
                } 
               
                vehicle.Fecha_desde__c = !String.isBlank(req.payload.deliveryDate) ? Datetime.valueOf(req.payload.deliveryDate.replace('T', ' ')) : Datetime.now();
                vehicle.Fecha_inicio_garantia__c = !String.isBlank(req.payload.warrantyStartDate) ? Datetime.valueOf(req.payload.warrantyStartDate.replace('T', ' ')) : null;
                vehicle.Fecha_fin_garantia__c = !String.isBlank(req.payload.warrantyEndDate) ? Datetime.valueOf(req.payload.warrantyEndDate.replace('T', ' ')) : null;
                
            }

            vehicle.RecalcularTarget__c = false;
            if (!String.isBlank(vehicle.MarcaString__c) && Label.BrandTarget.contains(vehicle.MarcaString__c.toUpperCase()) ){
                vehicle.RecalcularTarget__c = true;
            }
            
            Datetime inicioExGarantia = !String.isBlank(req.payload.warrantyExtensionStartDate) ? Datetime.valueOf(req.payload.warrantyExtensionStartDate.replace('T', ' ')) : null;
            if (vehicle.Fecha_fin_garantia__c != null && inicioExGarantia != null && inicioExGarantia >= vehicle.Fecha_fin_garantia__c) {
                vehicle.Fecha_inicio_extension_garantia__c = inicioExGarantia;
            }
            Datetime finExGarantia = !String.isBlank(req.payload.warrantyExtensionEndDate) ? Datetime.valueOf(req.payload.warrantyExtensionEndDate.replace('T', ' ')):null;
            if (inicioExGarantia != null && finExGarantia != null && inicioExGarantia <= finExGarantia) {
                vehicle.Fecha_fin_extension_garantia__c = finExGarantia;
            }

            vehicle.Fecha_inicio_garantia_VO__c = !String.isBlank(req.payload.UsedVehicleWarrantyStartDate) ? Datetime.valueOf(req.payload.UsedVehicleWarrantyStartDate.replace('T', ' ')) : null;
            vehicle.Fecha_fin_garantia_VO__c = !String.isBlank(req.payload.UsedVehicleWarrantyEndDate) ? Datetime.valueOf(req.payload.UsedVehicleWarrantyEndDate.replace('T', ' ')) : null;
			vehicle.Clasificacion__c = req.payload.technicalVehicleClassification;
            vehicle.Caja_de_cambios__c = req.payload.gearBox;
				
            upsert vehicle;
            
            paseTaller.kms__c = vehicle.kms__c;
            paseTaller.Vehiculo__c = vehicle.Id;
            
            paseTaller.creationDate__c = !String.isBlank(req.payload.creationDate) ? Datetime.valueOf(req.payload.creationDate.replace('T',' ')) : Datetime.now();
            paseTaller.receptionDate__c = !String.isBlank(req.payload.receptionDate) ? Datetime.valueOf(req.payload.receptionDate.replace('T',' ')) : Datetime.now();
            paseTaller.deliveryDate__c = !String.isBlank(req.payload.deliveryDate) ? Datetime.valueOf(req.payload.deliveryDate.replace('T',' ')) : Datetime.now();
            
            if(req.payload.economicSummary != null){
                paseTaller.currencyType__c = req.payload.economicSummary.currencyType;
            	paseTaller.customerAmount__c = req.payLoad.economicSummary.customerAmount;
            	paseTaller.deferenceAmount__c = req.payLoad.economicSummary.deferenceAmount;
            	paseTaller.insuranceAmount__c = req.payLoad.economicSummary.insuranceAmount;
            	paseTaller.internalAmount__c = req.payLoad.economicSummary.internalAmount;
                paseTaller.warrantyAmount__c = req.payLoad.economicSummary.warrantyAmount;
                paseTaller.campaignAmount__c = req.payLoad.economicSummary.campaignAmount;
            }
            String fecha = String.valueOf(paseTaller.deliveryDate__c.day()) +'-'+ String.valueOf(paseTaller.deliveryDate__c.month()) +'-'+ String.valueOf(paseTaller.deliveryDate__c.year());
            paseTaller.Name = centro.Concesionario__r.Nombre_Comercial__c +'/'+centro.Id_Centro_Sima__c +'/'+req.payload.brand.toUpperCase() +'/'+ vin + '/'+fecha;

            if (!String.isBlank(vehicle.MarcaString__c) && Label.BrandBringFriend.contains(vehicle.MarcaString__c.toUpperCase()) &&
                vehicle.Fecha_comunicacion_regalo__c == null && centro.Marcas_VN__c != null && centro.Marcas_VN__c.contains(vehicle.MarcaString__c.toUpperCase())){

                List<WorkshopOrderApiRestModel.Service> services = req.payload.services;
                Boolean esManteniniento = false;    

                for(WorkshopOrderApiRestModel.Service service : services){
                    if (service.serviceType != null && !String.isBlank(service.serviceType)
                        && Label.BringFriendServiceType.contains(service.serviceType.toUpperCase()) ) {
                        esManteniniento = true;
                        break;
                    }

                    for(Integer i = 0; i<service.partGroups.size(); i++){
                        if (service.partGroups[i].code != null && Label.BringFriendPartGroups.contains(service.partGroups[i].code)) {
	                        esManteniniento = true;
    	                    break;
                        }
                    }
                }
                
                if (esManteniniento == true){
                    Map<String, Consentimientos__c> mapConsents = ConsentimientosGateway.getConsentimientosValueByAccountId(paseTaller.customerDepositary__c);
                        
                    for (Consentimientos__c consen : mapConsents.values()) {
                         if (consen.Medio_de_contacto__c == 'Email' && 
                            (consen.AfterSales__c == 'Allow' || consen.ProductSale__c == 'Allow')) {
                             paseTaller.DateBringFriend__c = Datetime.now(); 
                         }
                    }    
                }    
            }    

            insert paseTaller;
            
            //Servicios 
            createServices(req.payload.services, paseTaller.Id, vehicle.MarcaString__c);
            
            response.Message = Label.responseMessage_Success;
            response.Status = Label.errorStatus_Success;

            //Actualizamos importe de postventa del cliente
            if (vehicle.Propietario__c != null) {
                Account cliente = AccountGateway.getAccountById(vehicle.Propietario__c);
             	cliente.Importe_Postventa__c = cliente.Importe_Postventa__c== null?0:cliente.Importe_Postventa__c;
                cliente.Importe_Postventa__c += paseTaller.customerAmount__c  != null?paseTaller.customerAmount__c:0;
                cliente.Importe_Postventa__c += paseTaller.insuranceAmount__c != null?paseTaller.insuranceAmount__c:0;
                cliente.Fecha_primera_compra_Postventa__c = cliente.Fecha_primera_compra_Postventa__c ==null?paseTaller.deliveryDate__c: cliente.Fecha_primera_compra_Postventa__c;
                cliente.Fecha_ultima_compra_Postventa__c = paseTaller.deliveryDate__c;
                cliente.Cliente_Postventa__c = true;
                update cliente;
            }           
 
            if (date.today() >= date.parse(label.startDateGPRD)){

            Account depositario = AccountGateway.getAccountById(paseTaller.customerDepositary__c);
            Concesionario__c infoConce = ConcesionarioGateway.getConcessionaireById(paseTaller.Concesionario__c);
            if (depositario.IsPersonAccount == true && paseTaller.customerAmount__c  != null && paseTaller.customerAmount__c != 0 &&
                infoConce.Es_propio__c){
                //Interés Legítimo
                List<Consentimientos__c> lisInteresLegitimo = ConsentimientosGateway.getConsentimientosInteresLegitimoByContactId(depositario.PersonContactId);
                
                Consentimientos__c conInteresLegitimo;
                for (Consentimientos__c consen : lisInteresLegitimo) {
                     if (consen.Concesionario__c == paseTaller.Concesionario__c && 
                         consen.Marca__c == vehicle.MarcaString__c) {
                         conInteresLegitimo = consen;
                         break;
                     }
                }
                
                if (conInteresLegitimo != null){
                    conInteresLegitimo.EnviarAmulesoft__c = false;
                    conInteresLegitimo.ProductSale__c = Label.ConsentimientoAllow;
                    conInteresLegitimo.AfterSales__c = Label.ConsentimientoAllow;
                    conInteresLegitimo.Call__c = true;
                    conInteresLegitimo.SMS__c = true;
                    conInteresLegitimo.Email__c = true;
                    conInteresLegitimo.WhatsApp__c = true;
                } else{
                    conInteresLegitimo = new Consentimientos__c();
                    Map<String, Schema.RecordTypeInfo> rtMapByDName = Schema.SObjectType.Consentimientos__c.getRecordTypeInfosByDeveloperName();
                    conInteresLegitimo.RecordTypeId = rtMapByDName.get('Interes_Legitimo_MKT_CCS').getRecordTypeId();        
                    conInteresLegitimo.Contact__c = depositario.PersonContactId;
                    conInteresLegitimo.Concesionario__c = paseTaller.Concesionario__c;
                    conInteresLegitimo.Marca__c = vehicle.MarcaString__c;
                    conInteresLegitimo.EnviarAmulesoft__c = false;
                    conInteresLegitimo.ProductSale__c = Label.ConsentimientoAllow;
                    conInteresLegitimo.AfterSales__c = Label.ConsentimientoAllow;
                    conInteresLegitimo.Call__c = true;
                    conInteresLegitimo.SMS__c = true;
                    conInteresLegitimo.Email__c = true;
                    conInteresLegitimo.WhatsApp__c = true;
                }
                upsert conInteresLegitimo;
                system.debug('conInteresLegitimo.id: '+conInteresLegitimo.Id);

                //Ficha única
                Consentimientos__c conFichaUnica = ConsentimientosGateway.getConsentimientosFichaUnicaByContactId(depositario.PersonContactId);
                if (conFichaUnica != null){
                    conFichaUnica.expectedDommunicationDate__c = Datetime.now();
                    conFichaUnica.EnviarAmulesoft__c = false;
                    if (conFichaUnica.oppositionDate__c != null){
                        conFichaUnica.communicationType__c = Label.comunicacionNoEnFU;
                        conFichaUnica.oppositionDate__c = null;
                        conFichaUnica.realCommunicationDate__c = null;
                        conFichaUnica.entryDate__c = null;
                    } else{
                        if (conFichaUnica.realCommunicationDate__c == null){
                            conFichaUnica.communicationType__c = Label.comunicacionInicial;
                        } else {
                            conFichaUnica.communicationType__c = Label.comunicacionYaEnFU;
                        }
                    }
                } else{
                    conFichaUnica = new Consentimientos__c();
                    Map<String, Schema.RecordTypeInfo> rtMapByDName = Schema.SObjectType.Consentimientos__c.getRecordTypeInfosByDeveloperName();
                    conFichaUnica.RecordTypeId = rtMapByDName.get('Ficha_unica').getRecordTypeId();        
                    conFichaUnica.Contact__c = depositario.PersonContactId;
                    conFichaUnica.Concesionario__c = Label.concesionarioFichaUnica;
                    conFichaUnica.communicationType__c = Label.comunicacionInicial;
                    conFichaUnica.expectedDommunicationDate__c = Datetime.now();
                    conFichaUnica.EnviarAmulesoft__c = false;
                }
                upsert conFichaUnica;
            }
            
            }
            
            //Encuesta
            system.debug('encuesta');
            Encuesta__c encuesta = EncuestaGateway.getEncuestaByPaseTaller(paseTaller.Id);
            if(encuesta == null && !String.isBlank(vehicle.MarcaString__c) && Label.BrandSurvey.contains(vehicle.MarcaString__c.toUpperCase()) ){
                system.debug('inicia el Manage Survey');
                ManageSurvey.manage(paseTaller.Id);
            }
            
        }catch(Exception e){
            response.ErrorCode = '500';
            response.Message = e.getMessage();
            response.Status = Label.errorStatus_Error;
            System.debug('Linea ' + e.getLineNumber() + ': ' + response.Message);
            if (e.getMessage().equalsIgnoreCase(Label.errorMessage_workshopOrderIdEmpty)) {   
                response.ErrorCode = '501'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_centerNotFound)) {
                response.ErrorCode = '502';
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_VinEmpty)) {
                response.ErrorCode = '503';
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_clientNotFound)) {
                response.ErrorCode = '504';
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_depositoryNotFound)) {
                response.ErrorCode = '505';
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_ownerNotFound)) {
                response.ErrorCode = '506';
            }
 
            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.payload.workshopOrderId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'WorkshopOrderApiRestController.createworkshopOrder';
            
            insert exc;
        }
        return response;
    }
    
    private static void createServices(List<WorkshopOrderApiRestModel.Service> services, Id paseTallerId, string brandVehicle){
    	List<Servicio__c> servicios = new List<Servicio__c>(); 
        map<string,Servicio_Target__c> mapServicioTargets = new map<string,Servicio_Target__c>();
        for(WorkshopOrderApiRestModel.Service service : services){
            Servicio__c servicio = new Servicio__c();
            servicio.Pase_de_taller__c = paseTallerId;
            servicio.serviceType__c = service.serviceType;
            servicio.serviceTypeCode__c = service.serviceTypeCode;
            if (service.serviceType != null && !String.isBlank(service.serviceType)) {
                servicio.Name = service.serviceType;
            } else {
                servicio.Name = 'Visita taller';
            }
            servicio.serviceOrigin__c = service.serviceOrigin;
            servicio.serviceOriginCode__c = service.serviceOriginCode;
            servicio.partGroups__c ='';
            servicio.PartGroupCode__c ='';
            for(Integer i = 0; i<service.partGroups.size(); i++){
                //Mirar en un if quienes se crean servicioTarget según código, por el momento todas

                if (!mapServicioTargets.containsKey(service.partGroups[i].code)) {
                    Servicio_Target__c serviceTarget = new Servicio_Target__c();
                    serviceTarget.Codigo_Grupo__c = service.partGroups[i].code;
                    system.debug('brandVehicle: '+brandVehicle);
                    switch on brandVehicle {
                        when 'CITROËN'{
                                       switch on service.partGroups[i].code {
                                           when '00150'{serviceTarget.Name = 'Filtro de aceite';
                                                        service.partGroups[i].description = 'Filtro de aceite';}
                                           when '00500'{serviceTarget.Name = 'Líquido de frenos';
                                                        service.partGroups[i].description = 'Líquido de frenos';}
                                           when '00154'{serviceTarget.Name = 'Filtro de Aire';
                                                        service.partGroups[i].description = 'Filtro de Aire';}
                                           when '00116'{serviceTarget.Name = 'Correa V';
                                                        service.partGroups[i].description = 'Correa V';}
                                           when '00278'{serviceTarget.Name = 'Bujía';
                                                        service.partGroups[i].description = 'Bujía';}
                                           when '00156'{serviceTarget.Name = 'Filtro de A/C';
                                                        service.partGroups[i].description = 'Filtro de A/C';}
                                           when else {serviceTarget.Name = service.partGroups[i].description;}
                                       }
                                      }    
                        when else {serviceTarget.Name = service.partGroups[i].description;}
                    }    
                    serviceTarget.Pase_de_taller__c = paseTallerId;
                    serviceTarget.Es_target__c = false;
                    switch on brandVehicle {
                        when 'VOLKSWAGEN'{serviceTarget.Es_target__c = Label.TargetVOLKSWAGEN.contains(service.partGroups[i].code)?true:false;}
                        when 'VW COMERCIALES'{serviceTarget.Es_target__c = Label.TargetVWCOMERCIALES.contains(service.partGroups[i].code)?true:false;} 
                        when 'AUDI'{serviceTarget.Es_target__c = Label.TargetAUDI.contains(service.partGroups[i].code)?true:false;} 
                        when 'SKODA'{serviceTarget.Es_target__c = Label.TargetSKODA.contains(service.partGroups[i].code)?true:false;} 
                        when 'HYUNDAI'{serviceTarget.Es_target__c = Label.TargetHYUNDAI.contains(service.partGroups[i].code)?true:false;} 
                        when 'CITROËN'{serviceTarget.Es_target__c = Label.TargetCITROEN.contains(service.partGroups[i].code)?true:false;} 
                        when 'HONDA'{serviceTarget.Es_target__c = Label.TargetHONDA.contains(service.partGroups[i].code)?true:false;} 
                        when 'HONDA MOTOS'{serviceTarget.Es_target__c = Label.TargetHONDAMOTOS.contains(service.partGroups[i].code)?true:false;} 
                        when 'DUCATI'{serviceTarget.Es_target__c = Label.TargetDUCATI.contains(service.partGroups[i].code)?true:false;}
                        when else {serviceTarget.Es_target__c = false;}
                    }      
                    mapServicioTargets.put(service.partGroups[i].code,serviceTarget);
                } 
                
                servicio.partGroups__c += i+1<service.partGroups.size()?service.partGroups[i].code +': ' + service.partGroups[i].description+';\n':
                                                                        service.partGroups[i].code +': ' + service.partGroups[i].description;
                servicio.PartGroupCode__c += i+1<service.partGroups.size()?service.partGroups[i].code+',':service.partGroups[i].code;
            }
            servicios.add(servicio);
        }
        insert servicios;
        insert mapServicioTargets.values();
    }
}