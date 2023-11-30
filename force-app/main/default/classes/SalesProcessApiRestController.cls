public class SalesProcessApiRestController {
    public static ResponseApi createProcessSales(SalesProcessApiRestModel req) {
        ResponseApi response = new ResponseApi();
        
        try {
            //buscar la oportunidad
            if (String.isBlank(req.payload.salesProcessId)) {
                throw new CustomException(Label.errorMessage_salesProcessId);
            }
            String centroIdExterno = req.payload.companyCode + '-' + req.payload.centerCode;
            Opportunity opp = OpportunityGateway.getOppByIdVentaDMS(req.payload.salesProcessId);
            Centro__c centro = CentroGateway.getCenterByIdCentroSima(centroIdExterno);
            Salesman__c vendedor = !String.isBlank(req.payload.salesmanEmail) ? SalesmanGateway.getSalesmanByEmail(req.payload.salesmanEmail.toLowerCase()):null;
            //creo el vendedor  si no existe 
            if (vendedor == null && !String.isBlank(req.payload.salesmanEmail) ) {
                vendedor = new Salesman__c();
                vendedor.Name = req.payload.salesmanEmail.toLowerCase();
                vendedor.Email__c = req.payload.salesmanEmail.toLowerCase();
                insert vendedor;
            }
            
            if (centro == null) {
                throw new CustomException(Label.errorMessage_centerNotFound);
            }
            
            String externalId = req.payload.customerId + '/' + req.payload.companyCode;
            Cliente_Concesionario__c cConcesionario = ClienteConcesionarioGateway.getClienteConcesionarioByIdExternal(externalId);
            
            if (cConcesionario == null) {
                throw new CustomException(Label.errorMessage_clientNotFound);
            }
            
            if (opp == null) {
                opp = new Opportunity();
                opp.ID_Oportunidad_DMS__c = req.payload.salesProcessId;
                opp.Centro__c = centro.Id;
                opp.AccountId = cConcesionario.Cliente__c;
                opp.Concesionario__c = cConcesionario.Concesionario__c;
                Date fecha = !String.isBlank(req.payload.creationDate) ? Date.valueOf(req.payload.creationDate.replace('T', ' ')) : Date.today();
                opp.CloseDate = fecha.addMonths(1);
                //opp.Name = req.payload.salesProcessId;
                opp.Name =centro != null ?centro.Concesionario__r.Nombre_Comercial__c+'/'+centro.Name:req.payload.salesProcessId;
                opp.StageName = 'Qualification';
            }
            
            opp.Vendedor__c = vendedor != null?vendedor.Id:null;
            opp.Fecha_de_creacion__c = !String.isBlank(req.payload.creationDate) ? Datetime.valueOf(req.payload.creationDate.replace('T', ' ')) : Date.today();
            opp.Motivo__c = req.payload.motiveCode; 
            opp.Type = req.payload.salesType;  // Valor 1, 6, 13, calcular promedio; e.o.c. el sumatorio, para calcular el Amount
            opp.Origen__c = req.payload.sourceCode;
            if(opp.CampaignId == null){
                List<Case> listCasos = CaseGateway.getCasebySalesProcessExtId(req.payload.salesProcessId);
                if(!listCasos.isEmpty()){
                    opp.CampaignId = listCasos[0].campana__c;
                }
            }
            
            upsert opp;
            
            response.Message = Label.responseMessage_Success;
            response.Status = Label.errorStatus_Success;
        } catch(Exception e) {
            response.ErrorCode = '500';
            response.Message = e.getMessage();
            response.Status = Label.errorStatus_Error;
            
            if (e.getMessage().equalsIgnoreCase(Label.errorMessage_salesProcessId)) {   
                response.ErrorCode = '501'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_centerNotFound)) {
                response.ErrorCode = '502'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_clientNotFound)) {
                response.ErrorCode = '503'; 
            }

            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.payload.salesProcessId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'SalesProcessApiRestController.createProcessSales';
            
            insert exc;
            
        }
        
        return response;
    }
    
    public static ResponseApi upsertProcessSales(SalesProcessApiRestModel req) {
        ResponseApi response = new ResponseApi();
        
        try {
            if (String.isBlank(req.payload.salesProcessId)) {
                throw new CustomException(Label.errorMessage_salesProcessId);
            }
            
            Opportunity opp = OpportunityGateway.getOppByIdVentaDMS(req.payload.salesProcessId);
            
            if (opp == null) {
                throw new CustomException(Label.errorMessage_opportunityNotFound);
            }

            Salesman__c vendedor = !String.isBlank(req.payload.salesmanEmail) ? SalesmanGateway.getSalesmanByEmail(req.payload.salesmanEmail.toLowerCase()):null;
            //creo el vendedor  si no existe 
            if (vendedor == null && !String.isBlank(req.payload.salesmanEmail) ) {
                vendedor = new Salesman__c();
                vendedor.Name = req.payload.salesmanEmail.toLowerCase();
                vendedor.Email__c = req.payload.salesmanEmail.toLowerCase();
                insert vendedor;
            }
            opp.Vendedor__c = vendedor != null?vendedor.Id:null;
           
            opp.Fecha_de_entrega__c = !String.isBlank(req.payload.deliveryDate) ? Datetime.valueOf(req.payload.deliveryDate.replace('T', ' ')) : Date.today();
            opp.Dias_de_vencimiento__c = req.payload.expirationDays;
            opp.StageName = 'Proposal';
            Datetime closeDate = opp.Fecha_de_entrega__c != null && opp.Dias_de_vencimiento__c != null
                ? opp.Fecha_de_entrega__c.addDays(opp.Dias_de_vencimiento__c.intValue()) : opp.Fecha_de_entrega__c;            
            opp.CloseDate = Date.newInstance(closeDate.year(), closeDate.month(), closeDate.day());
            if(opp.CampaignId == null){
                List<Case> listCasos = CaseGateway.getCasebySalesProcessExtId(req.payload.salesProcessId);
                if(!listCasos.isEmpty()){
                    opp.CampaignId = listCasos[0].campana__c;
                }
            }
            opp.AdvertisingCommunications__c = true;
            opp.EndDateAdvertising__c = null;

            upsert opp;
            
            // Borrar ofertas anteriores
            List<Detalle_Oferta__c> listDetalleOferta = DetalleOfertaGateway.getDOfertaByOppId(opp.Id);
            if (listDetalleOferta != null && !listDetalleOferta.isEmpty()) {
                delete listDetalleOferta;
            }
            
            //Insertar ofertas nuevas
            List<Detalle_Oferta__c> listDetalleOfertaToInsert = new List<Detalle_Oferta__c>();
            Double amount = 0;
            
            System.debug('===>req.payload.offers' + req.payload.offers);

            for (SalesProcessApiRestModel.Offer offer : req.payload.offers) {
                String services = '';
                Integer i = 1;
                Detalle_Oferta__c oferta = createDetalleOferta(offer); 
                oferta.Opportunity__c = opp.Id;
                amount += offer.economicSummary.total;
                listDetalleOfertaToInsert.add(oferta);
            }
            
            if (!listDetalleOfertaToInsert.isEmpty()) {
                insert listDetalleOfertaToInsert;
            }
            
            opp.Amount = amount;
            
            if (opp.Type == '1' || opp.Type == '6' || opp.Type == '13') {
                if (req.payload.offers.size() != 0) {
	                opp.Amount = amount / req.payload.offers.size();
                }
            }
            
            System.debug('===>opp.Amount ' + opp.Amount);
            
            update opp;
            
            response.Message = Label.responseMessage_Success;
            response.Status = Label.errorStatus_Success;
            //response.ErrorCode = '200';
        } catch(Exception e) {
            response.ErrorCode = '500';
            response.Message = e.getMessage();
            response.Status = Label.errorStatus_Error;
            system.debug('linea:'+ e.getLineNumber());
            
            if (e.getMessage().equalsIgnoreCase(Label.errorMessage_salesProcessId)) {   
                response.ErrorCode = '501'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_opportunityNotFound)) {
                response.ErrorCode = '504';
            }

            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.payload.salesProcessId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'SalesProcessApiRestController.upsertProcessSales';
            
            insert exc;

        }
        
        return response;
    }
    
    public static ResponseApi failureProcessSales(SalesProcessApiRestModel req) {
        ResponseApi response = new ResponseApi();
        //fracaso 
        try {
            if (String.isBlank(req.payload.salesProcessId)) {
                throw new CustomException(Label.errorMessage_salesProcessId);
            }
            
            Opportunity opp = OpportunityGateway.getOppByIdVentaDMS(req.payload.salesProcessId);
            if (opp == null) {
                throw new CustomException('No existe la oportunidad');
            }
            
            Salesman__c vendedor = !String.isBlank(req.payload.salesmanEmail) ? SalesmanGateway.getSalesmanByEmail(req.payload.salesmanEmail.toLowerCase()):null;
            //creo el vendedor  si no existe 
            if (vendedor == null && !String.isBlank(req.payload.salesmanEmail) ) {
                vendedor = new Salesman__c();
                vendedor.Name = req.payload.salesmanEmail.toLowerCase();
                vendedor.Email__c = req.payload.salesmanEmail.toLowerCase();
                insert vendedor;
            }
            opp.Vendedor__c = vendedor != null?vendedor.Id:null;
           
            opp.Fecha_de_Fracaso__c = !String.isBlank(req.payload.rejectionDate) ? Datetime.valueOf(req.payload.rejectionDate.replace('T', ' ')) : null;
            opp.Loss_Reason__c = req.payload.rejectionReasonCode;
            opp.StageName = 'Closed Lost';
            
             if(opp.CampaignId == null){
                List<Case> listCasos = CaseGateway.getCasebySalesProcessExtId(req.payload.salesProcessId);
                if(!listCasos.isEmpty()){
                    opp.CampaignId = listCasos[0].campana__c;
                }
            }

            upsert opp;
            response.Message = Label.responseMessage_Success;
            response.Status = Label.errorStatus_Success;
            //response.ErrorCode = '200';
        } catch(Exception e) {
            response.ErrorCode = '500';
            response.Message = e.getMessage();
            response.Status = Label.errorStatus_Error;
            system.debug('linea:'+ e.getLineNumber());
            
            if (e.getMessage().equalsIgnoreCase(Label.errorMessage_salesProcessId)) {   
                response.ErrorCode = '501'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_opportunityNotFound)) {
                response.ErrorCode = '504';
            }

            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.payload.salesProcessId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'SalesProcessApiRestController.failureProcessSales';
            
            insert exc;
            
        }
        
        return response;
    }
    
    public static ResponseApi successProcessSales(SalesProcessApiRestModel req) {
        ResponseApi response = new ResponseApi();
        //exito actualizar fecha de exito succesDate, stageName -> closed Won 
        try {
            if (String.isBlank(req.payload.salesProcessId)) {
                throw new CustomException(Label.errorMessage_salesProcessId);
            }
            
            Opportunity opp = OpportunityGateway.getOppByIdVentaDMS(req.payload.salesProcessId);
            if (opp == null) {
                throw new CustomException('No existe la oportunidad');
            }
            
            Salesman__c vendedor = !String.isBlank(req.payload.salesmanEmail) ? SalesmanGateway.getSalesmanByEmail(req.payload.salesmanEmail.toLowerCase()):null;
            //creo el vendedor  si no existe 
            if (vendedor == null && !String.isBlank(req.payload.salesmanEmail) ) {
                vendedor = new Salesman__c();
                vendedor.Name = req.payload.salesmanEmail.toLowerCase();
                vendedor.Email__c = req.payload.salesmanEmail.toLowerCase();
                insert vendedor;
            }
            opp.Vendedor__c = vendedor != null?vendedor.Id:null;
            
            opp.Fecha_de_exito__c = !String.isBlank(req.payload.successDate) ? Datetime.valueOf(req.payload.successDate.replace('T', ' ')) : null;
            opp.StageName = opp.Fecha_de_completado__c== null?'Negotiation':opp.StageName;
            
            if(opp.CampaignId == null){
                List<Case> listCasos = CaseGateway.getCasebySalesProcessExtId(req.payload.salesProcessId);
                if(!listCasos.isEmpty()){
                    opp.CampaignId = listCasos[0].campana__c;
                }
            }
            
            // Borrar ofertas anteriores
            List<Detalle_Oferta__c> listDetalleOferta =  DetalleOfertaGateway.getDOfertaByOppId(opp.Id);
            
            if (listDetalleOferta != null && !listDetalleOferta.isEmpty()) {
                delete listDetalleOferta;
            }
            
            //Insertar ofertas nuevas
            List<Detalle_Oferta__c> listDetalleOfertaToInsert = new List<Detalle_Oferta__c>();
            Double amount = 0;
            String MarcaOferta = '';
            
            for (SalesProcessApiRestModel.Offer offer : req.payload.offers) {
                Integer i = 1;
                Detalle_Oferta__c oferta = createDetalleOferta(offer); 
                oferta.Opportunity__c = opp.Id;
                amount += offer.economicSummary.total;
                MarcaOferta = offer.vehicle.brandCode; 
                listDetalleOfertaToInsert.add(oferta);
            }

            System.debug('MarcaOferta: '+MarcaOferta);
            if (opp.DateBringFriend__c == null && !String.isBlank(MarcaOferta) && 
                Label.BrandBringFriend.contains(MarcaOferta.toUpperCase()) && opp.Campaign.Name != 'HY_AMIGO' ){
                Map<String, Consentimientos__c> mapConsents = ConsentimientosGateway.getConsentimientosValueByAccountId(opp.AccountId);
                    
                for (Consentimientos__c consen : mapConsents.values()) {
                     if (consen.Medio_de_contacto__c == 'Email' && 
                        (consen.AfterSales__c == 'Allow' || consen.ProductSale__c == 'Allow')) {
                         opp.DateBringFriend__c = Datetime.now(); 
                     }
                }    
            }    

            opp.Amount = amount;
            upsert opp;

            if (!listDetalleOfertaToInsert.isEmpty()) {
                insert listDetalleOfertaToInsert;
            }

            response.Message = Label.responseMessage_Success;
            response.Status = Label.errorStatus_Success;
            //response.ErrorCode = '200';
        } catch(Exception e) {
            response.ErrorCode = '500';
            response.Message = e.getMessage();
            response.Status = Label.errorStatus_Error;
            system.debug('linea:'+ e.getLineNumber());
            
            if (e.getMessage().equalsIgnoreCase(Label.errorMessage_salesProcessId)) {   
                response.ErrorCode = '501'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_opportunityNotFound)) {
                response.ErrorCode = '504';
            }

            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.payload.salesProcessId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'SalesProcessApiRestController.successProcessSales';
            
            insert exc;
            
        }
        
        return response;
    }
    
    public static ResponseApi completedProcessSales(SalesProcessApiRestModel req) {
        ResponseApi response = new ResponseApi();
        
        try {
            if (String.isBlank(req.payload.salesProcessId)) {
                throw new CustomException(Label.errorMessage_salesProcessId);
            }
            
            Opportunity opp = OpportunityGateway.getOppByIdVentaDMS(req.payload.salesProcessId);
            if (opp == null) {
                throw new CustomException('No existe la oportunidad');
            }
            
            Salesman__c vendedor = !String.isBlank(req.payload.salesmanEmail) ? SalesmanGateway.getSalesmanByEmail(req.payload.salesmanEmail.toLowerCase()):null;
            //creo el vendedor  si no existe 
            if (vendedor == null && !String.isBlank(req.payload.salesmanEmail) ) {
                vendedor = new Salesman__c();
                vendedor.Name = req.payload.salesmanEmail.toLowerCase();
                vendedor.Email__c = req.payload.salesmanEmail.toLowerCase();
                insert vendedor;
            }
            opp.Vendedor__c = vendedor != null?vendedor.Id:null;
            
            opp.Fecha_de_completado__c = !String.isBlank(req.payload.saleCompletedDate) ? Datetime.valueOf(req.payload.saleCompletedDate.replace('T', ' ')) : null;
            opp.StageName = !opp.StageName.equalsIgnoreCase('Closed Won')?'Completed':opp.StageName;
            
             if(opp.CampaignId == null){
                List<Case> listCasos = CaseGateway.getCasebySalesProcessExtId(req.payload.salesProcessId);
                if(!listCasos.isEmpty()){
                    opp.CampaignId = listCasos[0].campana__c;
                }
            }
                        
            // Borrar ofertas anteriores
            List<Detalle_Oferta__c> listDetalleOferta =  DetalleOfertaGateway.getDOfertaByOppId(opp.Id);
            
            if (listDetalleOferta != null && !listDetalleOferta.isEmpty()) {
                delete listDetalleOferta;
            }
            
            //Insertar ofertas nuevas
            List<Detalle_Oferta__c> listDetalleOfertaToInsert = new List<Detalle_Oferta__c>();
            Double amount = 0;
            String MarcaOferta = '';
            
            for (SalesProcessApiRestModel.Offer offer : req.payload.offers) {
                Integer i = 1;
                Detalle_Oferta__c oferta = createDetalleOferta(offer); 
                oferta.Opportunity__c = opp.Id;
                amount += offer.economicSummary.total;
                MarcaOferta = offer.vehicle.brandCode; 
                listDetalleOfertaToInsert.add(oferta);
            }

            System.debug('MarcaOferta: '+MarcaOferta);
            if (opp.DateBringFriend__c == null && !String.isBlank(MarcaOferta) && 
                Label.BrandBringFriend.contains(MarcaOferta.toUpperCase()) && opp.Campaign.Name != 'HY_AMIGO' ){
                Map<String, Consentimientos__c> mapConsents = ConsentimientosGateway.getConsentimientosValueByAccountId(opp.AccountId);
                    
                for (Consentimientos__c consen : mapConsents.values()) {
                     if (consen.Medio_de_contacto__c == 'Email' && 
                        (consen.AfterSales__c == 'Allow' || consen.ProductSale__c == 'Allow')) {
                         opp.DateBringFriend__c = Datetime.now(); 
                     }
                }    
            }    

            opp.Amount = amount;
            upsert opp;
            if (!listDetalleOfertaToInsert.isEmpty()) {
                insert listDetalleOfertaToInsert;
            }
            
            response.Message = Label.responseMessage_Success;
            response.Status = Label.errorStatus_Success;
            //response.ErrorCode = '200';
        } catch(Exception e) {
            response.ErrorCode = '500';
            response.Message = e.getMessage();
            response.Status = Label.errorStatus_Error;
            system.debug('linea:'+ e.getLineNumber());
            
            if (e.getMessage().equalsIgnoreCase(Label.errorMessage_salesProcessId)) {   
                response.ErrorCode = '501'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_opportunityNotFound)) {
                response.ErrorCode = '504';
            }
            
            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.payload.salesProcessId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'SalesProcessApiRestController.completedProcessSales';
            
            insert exc;
            
        }
        
        return response;
    }
     
    public static ResponseApi vehicleDeliveredProcessSales(SalesProcessApiRestModel req) {
        ResponseApi response = new ResponseApi();
        
        try {
            if (String.isBlank(req.payload.salesProcessId)) {
                throw new CustomException(Label.errorMessage_salesProcessId);
            }
            if (String.isBlank(req.payload.vin)){
                    throw new CustomException('Error no VIN');
            }
            
            String vin = req.payload.vin.toUpperCase();
            
            Opportunity opp = OpportunityGateway.getOppByIdVentaDMS(req.payload.salesProcessId);
            if (opp == null) {
                throw new CustomException(Label.errorMessage_opportunityNotFound);
            }
            
            Map<String,Detalle_Oferta__c> mapDetalleOfertaByOpp = DetalleOfertaGateway.getDOfertaVinByOppId(opp.Id);
            Detalle_Oferta__c dOferta =  mapDetalleOfertaByOpp.containsKey(vin)? mapDetalleOfertaByOpp.get(vin):null;
            String externalId = req.payload.salesProcessId + '/'+ vin;
            Detalle_venta__c dSale = DetalleVentaGateway.getDetalleVentaByExternalId(externalId);
            Boolean AgenteConTaller = false;
            if (dSale == null) {
                dSale = new Detalle_Venta__c();
                dSale.Comprador__c = opp.AccountId;
                dSale.External_Id__c = externalId;
                dSale.Opportunity__c = opp.Id;
                dSale.Modalidad__c = dOferta != null ? dOferta.Modalidad__c:null;
                String centroIdExterno = req.payload.companyCode + '-' + req.payload.centerCode;
                Centro__c center = CentroGateway.getCenterByIdCentroSima(centroIdExterno);
                if (center == null) {
                    response.ErrorCode = '501';
                    response.Status = Label.errorStatus_Error;
                    response.Message = Label.responseMessage_Error + ' No existe el centro ; ';
                    return response;
                }
                dSale.Centro__c = center.Id;
                System.debug('CENTER: ' + center);
                dSale.Concesionario__c = center.Concesionario__c;
                Salesman__c vendedor = !String.isBlank(req.payload.salesmanEmail) ? SalesmanGateway.getSalesmanByEmail(req.payload.salesmanEmail.toLowerCase()) : null;
                //creo el vendedor  si no existe 
                if (vendedor == null && !String.isBlank(req.payload.salesmanEmail)) {
                    vendedor = new Salesman__c();
                    vendedor.Name = req.payload.salesmanEmail.toLowerCase();
                    vendedor.Email__c = req.payload.salesmanEmail.toLowerCase();
                    insert vendedor;
                }
                dSale.Vendedor__c = vendedor != null ? vendedor.Id : null;
                dSale.Name = center.Concesionario__r.Nombre_Comercial__c +'/'+center.Id_Centro_Sima__c +'/'+req.payload.brand.toUpperCase() +'/'+ vin;
                
            }
            if(req.payload.intermediary != null && dSale.Intermediario__c == null){
                SalesProcessApiRestModel.Intermediary intermediario = req.payload.intermediary ;
                Concesionario__c concesionario = ConcesionarioGateway.getConcessionaireByCIF(intermediario.taxIdentification.numberTax);
                if (concesionario != null) {
                    dSale.Intermediario__c = concesionario.Id;
                    AgenteConTaller = concesionario.Agente_con_taller__c;
                }
            }
            
            dSale.Fecha_de_entrega__c =!String.isBlank(req.payload.deliveryDate) ? Datetime.valueOf(req.payload.deliveryDate.replace('T', ' ')) : null;
           
            Vehiculo__c vehicle = VehiculoGateway.getVehicleByVin(vin);
            String idExterno = req.payload.customerOwnerId + '/' + req.payload.companyCode;
            Cliente_Concesionario__c cConcesionario = ClienteConcesionarioGateway.getClienteConcesionarioByIdExternal(idExterno);
            if (cConcesionario == null) {
                throw new CustomException(Label.errorMessage_ownerNotFound);
            }
            Account cliente = AccountGateway.getAccountById(cConcesionario.Cliente__c);
            dSale.Propietario__c = cConcesionario.Cliente__c;
            if (vehicle != null) {
                vehicle.Propietario__c =  cConcesionario.Cliente__c;
                vehicle.Comprador__c = dSale.Comprador__c;
                if (dSale.Intermediario__c != null && AgenteConTaller){
                    vehicle.Concesionario__c = dSale.Intermediario__c;
                }
                else {
                    vehicle.Concesionario__c = dSale.Concesionario__c;
                    vehicle.Centro__c = dSale.Centro__c;
                }
                vehicle.Name = req.payload.registrationPlate;
                Double kms = req.payload.kms;
    
                if (kms != null && vehicle.kms__c < kms) {
                    vehicle.kms__c = kms;
                }
                        
                vehicle.Fecha_desde__c = !String.isBlank(req.payload.deliveryDate) ? Datetime.valueOf(req.payload.deliveryDate.replace('T', ' ')) : null;
                vehicle.Fecha_inicio_garantia__c = !String.isBlank(req.payload.warrantyStartDate) ? Datetime.valueOf(req.payload.warrantyStartDate.replace('T', ' ')) : null;
                vehicle.Fecha_fin_garantia__c = !String.isBlank(req.payload.warrantyEndDate) ? Datetime.valueOf(req.payload.warrantyEndDate.replace('T', ' ')) : null;
                
                Datetime inicioExGarantia = !String.isBlank(req.payload.warrantyExtensionStartDate) ? Datetime.valueOf(req.payload.warrantyExtensionStartDate.replace('T', ' ')) : null;
                if (vehicle.Fecha_fin_garantia__c != null && inicioExGarantia != null && inicioExGarantia >= vehicle.Fecha_fin_garantia__c) {
                    vehicle.Fecha_inicio_extension_garantia__c = inicioExGarantia;
                }
                Datetime finExGarantia = !String.isBlank(req.payload.warrantyExtensionEndDate) ? Datetime.valueOf(req.payload.warrantyExtensionEndDate.replace('T', ' ')) : null;
                if (inicioExGarantia != null && finExGarantia != null && inicioExGarantia <= finExGarantia) {
                    vehicle.Fecha_fin_extension_garantia__c = finExGarantia;
                }
                
                
                vehicle.Fecha_inicio_garantia_VO__c = !String.isBlank(req.payload.usedVehicleWarrantyStartDate) ? Datetime.valueOf(req.payload.UsedVehicleWarrantyStartDate.replace('T', ' ')) : null;
            	vehicle.Fecha_fin_garantia_VO__c = !String.isBlank(req.payload.usedVehicleWarrantyEndDate) ? Datetime.valueOf(req.payload.UsedVehicleWarrantyEndDate.replace('T', ' ')) : null;
				vehicle.Clasificacion__c = req.payload.technicalVehicleClassification;
                vehicle.Caja_de_cambios__c = req.payload.gearBox;
				
                vehicle.Fecha_primera_matriculacion__c = !String.isBlank(req.payload.registrationPlateDate) ? Datetime.valueOf(req.payload.registrationPlateDate.replace('T', ' ')) : null;

                if(dOferta != null){
                    vehicle.Accesories__c = dOferta.Accessories__c;
                    vehicle.equipments__c = dOferta.Equipment__c;
                    vehicle.Services__c = dOferta.Services__c;
                    vehicle.Codigo_de_color__c     = dOferta.Codigo_de_color__c;
                    vehicle.colorDescription__c    = dOferta.colorDescription__c;
                    vehicle.Codigo_de_Interior__c  = dOferta.Codigo_de_Interior__c;
                    vehicle.interiorDescription__c = dOferta.interiorDescription__c;

                }

                vehicle.RecalcularTarget__c = false;
                if (!String.isBlank(req.payload.brand) && Label.BrandTarget.contains(req.payload.brand.toUpperCase()) ){
                    vehicle.RecalcularTarget__c = true;
                }

                if (!String.isBlank(req.payload.brand) && req.payload.brand.equalsIgnoreCase('HYUNDAI')) {
                    vehicle.Fecha_cumpleanos__c =  vehicle.Fecha_inicio_garantia__c != null ? vehicle.Fecha_inicio_garantia__c.date().addYears(1) : null;
                	vehicle.Numero_de_cumpleanos__c = 1;
                }
                
                if (opp.Type != null){
                    vehicle.Tipo_de_venta__c = opp.Type;
                }
                
            }
            else {
                vehicle = new Vehiculo__c();
                vehicle.Propietario__c = cConcesionario.Cliente__c;
                vehicle.Comprador__c = dSale.Comprador__c;
                if (dSale.Intermediario__c != null && AgenteConTaller){
                    vehicle.Concesionario__c = dSale.Intermediario__c;
                } else {
                    vehicle.Concesionario__c = dSale.Concesionario__c;
                    vehicle.Centro__c = dSale.Centro__c;
                }
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
                vehicle.Combustible__c = req.payload.fuel;
                vehicle.Transmision__c = req.payload.transmission;
                vehicle.Letra_Motor__c = req.payload.engineLetter;
                vehicle.Numero_de_Motor__c = req.payload.engineNumber;
                vehicle.Codigo_Motor__c = req.payload.engineCode;
                vehicle.kms__c = req.payload.kms;
                vehicle.Fecha_primera_matriculacion__c = !String.isBlank(req.payload.registrationPlateDate) ? Datetime.valueOf(req.payload.registrationPlateDate.replace('T', ' ')) : null;
                vehicle.Fecha_desde__c = !String.isBlank(req.payload.deliveryDate) ? Datetime.valueOf(req.payload.deliveryDate.replace('T', ' ')) : null;
                vehicle.Fecha_inicio_garantia__c = !String.isBlank(req.payload.warrantyStartDate) ? Datetime.valueOf(req.payload.warrantyStartDate.replace('T', ' ')) : null;
                vehicle.Fecha_fin_garantia__c = !String.isBlank(req.payload.warrantyEndDate) ? Datetime.valueOf(req.payload.warrantyEndDate.replace('T', ' ')) : null;
                
                Datetime inicioExGarantia = !String.isBlank(req.payload.warrantyExtensionStartDate) ? Datetime.valueOf(req.payload.warrantyExtensionStartDate.replace('T', ' ')) : null;
                if (vehicle.Fecha_fin_garantia__c != null && inicioExGarantia != null && inicioExGarantia >= vehicle.Fecha_fin_garantia__c) {
                    vehicle.Fecha_inicio_extension_garantia__c = inicioExGarantia;
                }
                Datetime finExGarantia = !String.isBlank(req.payload.warrantyExtensionEndDate) ? Datetime.valueOf(req.payload.warrantyExtensionEndDate.replace('T', ' ')):null;
                if (inicioExGarantia != null && finExGarantia != null && inicioExGarantia <= finExGarantia) {
                    vehicle.Fecha_fin_extension_garantia__c = finExGarantia;
                }
                //fechas used
                vehicle.Fecha_inicio_garantia_VO__c = !String.isBlank(req.payload.usedVehicleWarrantyStartDate) ? Datetime.valueOf(req.payload.UsedVehicleWarrantyStartDate.replace('T', ' ')) : null;
            	vehicle.Fecha_fin_garantia_VO__c = !String.isBlank(req.payload.usedVehicleWarrantyEndDate) ? Datetime.valueOf(req.payload.UsedVehicleWarrantyEndDate.replace('T', ' ')) : null;
				vehicle.Clasificacion__c = req.payload.technicalVehicleClassification;
                vehicle.Caja_de_cambios__c = req.payload.gearBox;
				//gearBox
                
                
                        
                if(dOferta != null){
                    vehicle.Accesories__c = dOferta.Accessories__c;
                    vehicle.equipments__c = dOferta.Equipment__c;
                    vehicle.Services__c = dOferta.Services__c;
                    vehicle.Codigo_de_color__c     = dOferta.Codigo_de_color__c;
                    vehicle.colorDescription__c    = dOferta.colorDescription__c;
                    vehicle.Codigo_de_Interior__c  = dOferta.Codigo_de_Interior__c;
                    vehicle.interiorDescription__c = dOferta.interiorDescription__c;

                }

                vehicle.RecalcularTarget__c = false;
                if (!String.isBlank(req.payload.brand) && Label.BrandTarget.contains(req.payload.brand.toUpperCase()) ){
                    vehicle.RecalcularTarget__c = true;
                }
                
                if (!String.isBlank(req.payload.brand) && req.payload.brand.equalsIgnoreCase('HYUNDAI')) {
                    vehicle.Fecha_cumpleanos__c =  vehicle.Fecha_inicio_garantia__c != null ? vehicle.Fecha_inicio_garantia__c.date().addYears(1) : null;
                	vehicle.Numero_de_cumpleanos__c = 1;
                }

                if (opp.Type != null){
                    vehicle.Tipo_de_venta__c = opp.Type;
                }

            }
            upsert vehicle;
            
            dSale.Vehiculo__c = vehicle.Id;
            upsert dSale;
            
            if (opp.DateBringFriend__c == null && !String.isBlank(vehicle.MarcaString__c) && Label.BrandBringFriend.contains(vehicle.MarcaString__c.toUpperCase()) ){
                Map<String, Consentimientos__c> mapConsents = ConsentimientosGateway.getConsentimientosValueByAccountId(opp.AccountId);
                    
                for (Consentimientos__c consen : mapConsents.values()) {
                     if (consen.Medio_de_contacto__c == 'Email' && 
                        (consen.AfterSales__c == 'Allow' || consen.ProductSale__c == 'Allow')) {
                         opp.DateBringFriend__c = Datetime.now(); 
                     }
                }    
            }    

            opp.StageName = 'Closed Won';
            opp.AdvertisingCommunications__c = false;

            System.debug('req.payload.salesProcessId:'+req.payload.salesProcessId);
            List<Case> listCasos = CaseGateway.getCasebySalesProcessExtId(req.payload.salesProcessId);
            System.debug('listCasos: '+listCasos);
            
            if(opp.CampaignId == null){
                if(!listCasos.isEmpty()){
                    opp.CampaignId = listCasos[0].campana__c;
                }
            }
            
            update opp;
             
           	cliente.Importe_VN__c = cliente.Importe_VN__c== null?0:cliente.Importe_VN__c;
            cliente.Importe_VN__c +=dOferta != null &&  dOferta.Total__c != null?dOferta.Total__c:0;
            cliente.Fecha_primera_compra_VN__c = cliente.Fecha_primera_compra_VN__c ==null?dSale.Fecha_de_entrega__c: cliente.Fecha_primera_compra_VN__c;
            cliente.Fecha_ultima_compra_VN__c = dSale.Fecha_de_entrega__c;
            cliente.Cliente_VN__c = true;
            update cliente;

            if (date.today() >= date.parse(label.startDateGPRD)){

            Concesionario__c infoConce = ConcesionarioGateway.getConcessionaireById(dSale.Concesionario__c);
            if (cliente.IsPersonAccount == true  && infoConce.Es_propio__c){
                //Interés Legítimo
                List<Consentimientos__c> lisInteresLegitimo = ConsentimientosGateway.getConsentimientosInteresLegitimoByContactId(cliente.PersonContactId);
                
                Consentimientos__c conInteresLegitimo;
                for (Consentimientos__c consen : lisInteresLegitimo) {
                     if (consen.Concesionario__c == dSale.Concesionario__c && 
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
                    conInteresLegitimo.Contact__c = cliente.PersonContactId;
                    conInteresLegitimo.Concesionario__c = dSale.Concesionario__c;
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
                Consentimientos__c conFichaUnica = ConsentimientosGateway.getConsentimientosFichaUnicaByContactId(cliente.PersonContactId);
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
                    conFichaUnica.Contact__c = cliente.PersonContactId;
                    conFichaUnica.Concesionario__c = Label.concesionarioFichaUnica;
                    conFichaUnica.communicationType__c = Label.comunicacionInicial;
                    conFichaUnica.expectedDommunicationDate__c = Datetime.now();
                    conFichaUnica.EnviarAmulesoft__c = false;
                }
                conFichaUnica.legitimateInterest__c = conInteresLegitimo.Id;
                upsert conFichaUnica;
            }
            
            }    
            
            response.Message = Label.responseMessage_Success;
            response.Status = Label.errorStatus_Success;
            
             // Encuesta
            system.debug('encuesta');
            Encuesta__c encuesta = EncuestaGateway.getEncuestaByDetalleVenta(dSale.Id);
            if(encuesta == null && !String.isBlank(vehicle.MarcaString__c) && Label.BrandSurvey.contains(vehicle.MarcaString__c.toUpperCase()) ){
                if(dOferta != null){
                    if (dOferta.Modalidad__c.equalsIgnoreCase('NewVehicle')) {
                        system.debug('inicia el Manage Survey');
                        ManageSurvey.manage(dSale.Id);
                    }
                }
                else {
                   String surveyRT ='';
                  if (vehicle.MarcaString__c.equalsIgnoreCase('VOLKSWAGEN') || vehicle.MarcaString__c.equalsIgnoreCase('AUDI')) {
            		surveyRT = 'CEM';
      			  }
        		  else if (vehicle.MarcaString__c.equalsIgnoreCase('SKODA')) {
            		surveyRT = 'Externa';
       			 }
        		 else {
            		surveyRT = 'Telefonica';
            	}
                 encuesta = new Encuesta__c();
                 encuesta.Brand__c = vehicle.MarcaString__c;
                 encuesta.Detalle_venta__c = dSale.Id;
                 encuesta.Cliente__c = vehicle.Propietario__c;
                 encuesta.Resultado__c = 'No se ha podido confirmar la modalidad';
                 encuesta.ModeloString__c = vehicle.modelDescription__c;
                 encuesta.Tipo_Encuesta__c = 'SIMA';
                 encuesta.RecordTypeId = EncuestaGateway.getRecordTypeIdByDeveloperName(surveyRT);
                 encuesta.vin__c = vehicle.VIN__c;
                 encuesta.Fecha_documento__c = dSale.Fecha_de_entrega__c;
                 encuesta.Tipo_de_Operacion__c = 'Venta';
                 insert encuesta;
                }
                
            }
            
            if(!listCasos.isEmpty()){
                
               for(Case CasoRecomendado : listCasos){
                   System.debug('CasoRecomendado: '+CasoRecomendado);
                   System.debug('CasoRecomendado.RecommendBy__c: '+CasoRecomendado.RecommendBy__c);
                   if (CasoRecomendado.RecommendBy__c != null){
                       Detalle_venta__c DetalleVentaOri = DetalleVentaGateway.getDetalleVentaByOpportunityId(CasoRecomendado.RecommendBy__c);
                       System.debug('DetalleVentaOri: '+DetalleVentaOri);   
                       if (DetalleVentaOri != null){
                           Vehiculo__c vehicle1 = VehiculoGateway.getVehicleById(DetalleVentaOri.Vehiculo__c);
                           System.debug('vehicle1: '+vehicle1);
                           if (vehicle1 != null){
                               if (vehicle1.Fecha_comunicacion_regalo__c == null){
                                   vehicle1.Fecha_fin_regalo__c = Date.today().addYears(1);
                                   Datetime dt = Datetime.now().addDays(2);
                                   String dayOfWeek = dt.format('EEEE');
                                   if (dayOfWeek.equalsIgnoreCase('Saturday')) {
                                       dt=dt.addDays(2);
                                   } else if (dayOfWeek.equalsIgnoreCase('Sunday')) {
                                       dt=dt.addDays(1);
                                   }
                                   vehicle1.Fecha_comunicacion_regalo__c = dt;
                                   vehicle1.Amigo_Regalo__c = cliente.Name;
                                   update vehicle1;
                               }
                               break;
                           } 
                       }    
                   }
                   if (CasoRecomendado.RecommendByPT__c != null){
                       Pase_de_taller__c PaseTallerOri = PaseTallerGateway.getPaseTallerById(CasoRecomendado.RecommendByPT__c);
                       System.debug('PaseTallerOri: '+PaseTallerOri);   
                       if (PaseTallerOri != null){
                           Vehiculo__c vehicle1 = VehiculoGateway.getVehicleById(PaseTallerOri.Vehiculo__c);
                           System.debug('vehicle1: '+vehicle1);
                           if (vehicle1 != null){
                               if (vehicle1.Fecha_comunicacion_regalo__c == null){
                                   vehicle1.Fecha_fin_regalo__c = Date.today().addYears(1);
                                   Datetime dt = Datetime.now().addDays(2);
                                   String dayOfWeek = dt.format('EEEE');
                                   if (dayOfWeek.equalsIgnoreCase('Saturday')) {
                                       dt=dt.addDays(2);
                                   } else if (dayOfWeek.equalsIgnoreCase('Sunday')) {
                                       dt=dt.addDays(1);
                                   }
                                   vehicle1.Fecha_comunicacion_regalo__c = dt;
                                   vehicle1.Amigo_Regalo__c = cliente.Name;
                                   update vehicle1;
                               }
                               break;
                           } 
                       }    
                   }
               } 
            }
           
        } catch(Exception e) {
            response.ErrorCode = '500';
            response.Message = e.getMessage();
            response.Status = Label.errorStatus_Error;
            System.debug('Linea ' + e.getLineNumber() + ': ' + response.Message);
            
            if (e.getMessage().equalsIgnoreCase(Label.errorMessage_salesProcessId)) {   
                response.ErrorCode = '501'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_opportunityNotFound)) {
                response.ErrorCode = '504';
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_ownerNotFound)) {
                response.ErrorCode = '505';
            }
            /*else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_brandNotFound)) {
                response.ErrorCode = '506';
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_modelNotFound)) {
                response.ErrorCode = '507';
            }*/

            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.payload.salesProcessId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'SalesProcessApiRestController.vehicleDeliveredProcessSales';
            
            insert exc;

        }
        
        return response;
    }
    
    public static ResponseApi cancelCompletedProcessSales(SalesProcessApiRestModel req){
        ResponseApi response = new ResponseApi();
        
        try {
            if (String.isBlank(req.payload.salesProcessId)) {
                throw new CustomException(Label.errorMessage_salesProcessId);
            }
            
            Opportunity opp = OpportunityGateway.getOppByIdVentaDMS(req.payload.salesProcessId);
            if (opp == null) {
                throw new CustomException('No existe la oportunidad');
            }
            
            String vin = req.payload.vin.toUpperCase();

            String externalId= req.payload.salesProcessId+'/'+vin;
            Detalle_venta__c dSale = DetalleVentaGateway.getDetalleVentaByExternalId(externalId);
            if (dSale == null) {
            	throw new CustomException('No existe la venta');
            }
            Map<String,Detalle_Oferta__c> mapDetalleOfertaByOpp = DetalleOfertaGateway.getDOfertaVinByOppId(opp.Id);
            Detalle_Oferta__c dOferta =  mapDetalleOfertaByOpp.containsKey(vin)? mapDetalleOfertaByOpp.get(vin):null;
            
            Account cliente = AccountGateway.getAccountById(dSale.Propietario__c);
            if(cliente != null){
                cliente.Importe_VN__c -=dOferta != null && dOferta.Total__c!= null && cliente.Importe_VN__c>=dOferta.Total__c?dOferta.Total__c:0;
                if(cliente.Importe_VN__c == 0){
                    cliente.Fecha_ultima_compra_VN__c = null;
                    cliente.Fecha_primera_compra_VN__c = null;
                    cliente.Cliente_VN__c = false;   
                }
            	upsert cliente;
            }

            Encuesta__c encuesta = EncuestaGateway.getEncuestaByDetalleVenta(dSale.Id);
            if(encuesta != null && (!encuesta.Respondido__c || encuesta.Fecha_respuesta_encuesta__c > Date.today())){
                delete encuesta;
            }
            
            Vehiculo__c vehiculo = VehiculoGateway.getVehicleByVin(vin);
            if(vehiculo != null){
                vehiculo.Propietario__c = null;
                vehiculo.Comprador__c = null;
                vehiculo.Fecha_desde__c = null;
                    
                update vehiculo;
            }
            
            delete dSale;
            opp.StageName= opp.Fecha_de_completado__c != null?'Completed':'Negotiation';
            upsert opp;

            System.debug('req.payload.salesProcessId:'+req.payload.salesProcessId);
            List<Case> listCasos = CaseGateway.getCasebySalesProcessExtId(req.payload.salesProcessId);
            System.debug('listCasos: '+listCasos);

            if(!listCasos.isEmpty()){
                
               for(Case CasoRecomendado : listCasos){
                   System.debug('CasoRecomendado: '+CasoRecomendado);
                   System.debug('CasoRecomendado.RecommendBy__c: '+CasoRecomendado.RecommendBy__c);
                   if (CasoRecomendado.RecommendBy__c != null){
                       Detalle_venta__c DetalleVentaOri = DetalleVentaGateway.getDetalleVentaByOpportunityId(CasoRecomendado.RecommendBy__c);
                       System.debug('DetalleVentaOri: '+DetalleVentaOri);   
                       if (DetalleVentaOri != null){
                           Vehiculo__c vehicle1 = VehiculoGateway.getVehicleById(DetalleVentaOri.Vehiculo__c);
                           System.debug('vehicle1: '+vehicle1);
                           if (vehicle1 != null){
                               if (vehicle1.Fecha_comunicacion_regalo__c != null){
                                   vehicle1.Fecha_fin_regalo__c = null;
                                   vehicle1.Fecha_comunicacion_regalo__c = null;
                                   update vehicle1;
                               }
                               break;
                           } 
                       }    
                   }
               } 
            }

            
            
            
            response.Message = Label.responseMessage_Success;
            response.Status = Label.errorStatus_Success;
            //response.ErrorCode = '200';
        } catch(Exception e) {
            response.ErrorCode = '500';
            response.Message = e.getMessage();
            response.Status = Label.errorStatus_Error;
            system.debug('linea:'+ e.getLineNumber());
            
            if (e.getMessage().equalsIgnoreCase(Label.errorMessage_salesProcessId)) {   
                response.ErrorCode = '501'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_opportunityNotFound)) {
                response.ErrorCode = '504';
            }

            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.payload.salesProcessId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'SalesProcessApiRestController.cancelCompletedProcessSales';
            
            insert exc;
            
        }
        
        return response;
    }
    
    public static ResponseApi cancelProcessSalesCancelled(SalesProcessApiRestModel req){
         ResponseApi response = new ResponseApi();
        
        try {
            if (String.isBlank(req.payload.salesProcessId)) {
                throw new CustomException(Label.errorMessage_salesProcessId);
            }
            
            Opportunity opp = OpportunityGateway.getOppByIdVentaDMS(req.payload.salesProcessId);
            if (opp == null) {
                throw new CustomException('No existe la oportunidad');
            }
            
             Salesman__c vendedor = !String.isBlank(req.payload.salesmanEmail) ? SalesmanGateway.getSalesmanByEmail(req.payload.salesmanEmail.toLowerCase()):null;
            //creo el vendedor  si no existe 
            if (vendedor == null && !String.isBlank(req.payload.salesmanEmail) ) {
                vendedor = new Salesman__c();
                vendedor.Name = req.payload.salesmanEmail.toLowerCase();
                vendedor.Email__c = req.payload.salesmanEmail.toLowerCase();
                insert vendedor;
            }
            opp.Vendedor__c = vendedor != null?vendedor.Id:null;
           
            opp.Fecha_de_Fracaso__c = !String.isBlank(req.payload.cancellationDate) ? Datetime.valueOf(req.payload.cancellationDate.replace('T', ' ')) : null;
            opp.Loss_Reason__c = req.payload.cancellationReasonCode;
            opp.StageName = 'Closed Lost';
            
             if(opp.CampaignId == null){
                List<Case> listCasos = CaseGateway.getCasebySalesProcessExtId(req.payload.salesProcessId);
                if(!listCasos.isEmpty()){
                    opp.CampaignId = listCasos[0].campana__c;
                }
            }

            upsert opp;
            response.Message = Label.responseMessage_Success;
            response.Status = Label.errorStatus_Success;
            //response.ErrorCode = '200';
        } catch(Exception e) {
            response.ErrorCode = '500';
            response.Message = e.getMessage();
            response.Status = Label.errorStatus_Error;
            system.debug('linea:'+ e.getLineNumber());
            
            if (e.getMessage().equalsIgnoreCase(Label.errorMessage_salesProcessId)) {   
                response.ErrorCode = '501'; 
            }
            else if (e.getMessage().equalsIgnoreCase(Label.errorMessage_opportunityNotFound)) {
                response.ErrorCode = '504';
            }

            Exception__c exc = new Exception__c ();
            exc.idObjetos__c = req.payload.salesProcessId;
            exc.Exception__c = e.getCause() + '// '+ e.getMessage();
            exc.Linea__c = e.getLineNumber();
            exc.JSON_Entrada__c = JSON.serialize(req);
            exc.Clase_Metodo__c = 'SalesProcessApiRestController.cancelCompletedProcessSales';
            
            insert exc;
            
        }
        
        return response;
    }

    /*
    private static TestDrive__c createTestDrive(SalesProcessApiRestModel.TestDrive testD, String idOpp){
        TestDrive__c testDrive= new TestDrive__c();
        testDrive.testDriveId__c = testD.testDriveId;
        testDrive.Opportunity__c = idOpp;
        testDrive.DeliveryDate__c = !String.isBlank(testD.deliveryDate) ? Datetime.valueOf(testD.deliveryDate) : null; 
        testDrive.CreationDateExt__c = !String.isBlank(testD.creationDate) ? Datetime.valueOf(testD.creationDate) : null; 
        testDrive.EndingDate__c = !String.isBlank(testD.endingDate) ? Datetime.valueOf(testD.endingDate) : null; 
        testDrive.ScheduledDate__c = !String.isBlank(testD.scheduledDate) ? Datetime.valueOf(testD.scheduledDate) : null; 
        testDrive.Vin__c = !String.isBlank(testD.vin) ? testD.vin : null; 
        return testDrive;
    }
    */
    private static Detalle_Oferta__c createDetalleOferta (SalesProcessApiRestModel.Offer offer) {
        Detalle_Oferta__c oferta = new Detalle_Oferta__c();
        oferta.Name = offer.vehicle.brandCode+ '/' + offer.vehicle.modelGroup;
        if (offer.vehicle.vin !=null) {
            oferta.vin__c = offer.vehicle.vin.toUpperCase();
        }
        oferta.Modalidad__c = offer.vehicle.modality;
        oferta.Marca__c = offer.vehicle.brandCode;
        oferta.Codigo_de_modelo__c = offer.vehicle.modelCode;
        oferta.Ano_modelo__c = offer.vehicle.modelYear;
        oferta.extendedModelVersionKey__c = offer.vehicle.extendedModelVersionKey;
        oferta.modelGroup__c = offer.vehicle.modelGroup;
        oferta.modelDescription__c = offer.vehicle.modelDescription;
        oferta.modelGroupCode__c = offer.vehicle.modelGroupCode;
        oferta.fuelCode__c = offer.vehicle.fuelCode;
        oferta.power__c = offer.vehicle.power;
        oferta.engineCapacity__c = offer.vehicle.engineCapacity;
        oferta.Codigo_de_color__c = offer.vehicle.colorCode;
        oferta.colorDescription__c = offer.vehicle.colorDescription;
        oferta.Codigo_de_Interior__c = offer.vehicle.interiorCode;
        oferta.interiorDescription__c = offer.vehicle.interiorDescription;
        oferta.Equipment__c = '';
        
        if (offer.vehicle.equipments != null) {
            for (Integer i = 0; i < offer.vehicle.equipments.size(); i++) {
                if (i + 1 == offer.vehicle.equipments.size()) {
                    oferta.Equipment__c += offer.vehicle.equipments[i].code + ' - ' + offer.vehicle.equipments[i].description;
                }
                else {
                   oferta.Equipment__c += offer.vehicle.equipments[i].code + ' - ' + offer.vehicle.equipments[i].description + '\n'; 
                }
            }
        }
        
        oferta.Accessories__c = '';
        
        if (offer.vehicle.accessories != null) {
            for (Integer i = 0; i < offer.vehicle.accessories.size(); i++) {
                if (i + 1 == offer.vehicle.accessories.size()) {
                    oferta.Accessories__c += offer.vehicle.accessories[i].code + ' - ' + offer.vehicle.accessories[i].description;
                }
                else {
                   oferta.Accessories__c += offer.vehicle.accessories[i].code + ' - ' + offer.vehicle.accessories[i].description + '\n '; 
                }
            }
        }
        
        oferta.Services__c = '';
        
        if (offer.vehicle.services != null) {
            for (Integer i = 0; i < offer.vehicle.services.size(); i++) {
                Integer index = i + 1;
                
                if (index == offer.vehicle.services.size()) {
                    oferta.Services__c += 'Servicio ' + index + ': ' + offer.vehicle.services[i].description + '\n';
                    
                    if (!offer.vehicle.services[i].serviceDetails.isEmpty()) {
                        //oferta.Services__c += '';
                        
                        for (SalesProcessApiRestModel.DetailCode detail : offer.vehicle.services[i].serviceDetails) {
                            oferta.Services__c += detail.description + '\n';
                        }
                        
                        oferta.Services__c += '\n';
                    }
                }
                else {
                    oferta.Services__c += 'Servicio ' + index + ': ' + offer.vehicle.services[i].description + '\n';
                    
                    if (!offer.vehicle.services[i].serviceDetails.isEmpty()) {
                        //oferta.Services__c += '';
                        
                        for (SalesProcessApiRestModel.DetailCode detail : offer.vehicle.services[i].serviceDetails) {
                            oferta.Services__c += detail.description + '\n';
                        }
                        
                        oferta.Services__c += '\n';
                    }
                    
                    oferta.Services__c +=  '\n ';
                }
            }
        }
        
        oferta.currencyType__c = offer.economicSummary.currencyType;
        oferta.Precio__c = offer.economicSummary.price;
        oferta.Descuento__c = offer.economicSummary.discount;
        oferta.Total__c = offer.economicSummary.total;
        oferta.Financings__c = '';
        
        if(offer.financings != null){
            for (Integer i = 0; i < offer.financings.size(); i++) {
                oferta.Financings__c += 'Financiación ' + i + ': ' + offer.financings[i].tariffCode
                    + ' ' + offer.financings[i].tariffDescription + '/' + offer.financings[i].amount
                    + ' '+ offer.financings[i].currencyType + '\n';
            }
        }
        //oferta.Descripcion_servicio__c
        //oferta.Tipo_de_datalle__c
        //oferta.Tipo_de_servicio__c
        
        return oferta;
    }
}