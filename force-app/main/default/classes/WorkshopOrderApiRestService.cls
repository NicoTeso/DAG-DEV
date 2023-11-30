@RestResource(urlMapping='/workshopOrderApi/*')
global class WorkshopOrderApiRestService {
    
    @HttpPost
    global static ResponseApi upsertworkshopOrder() {
        ResponseApi response = new ResponseApi();
        System.debug('JSON Input: ' + RestContext.request.requestBody.toString());
        
        WorkshopOrderApiRestModel req = (WorkshopOrderApiRestModel) JSON.deserialize(RestContext.request.requestBody.toString(), WorkshopOrderApiRestModel.class);
        
        if (req != null && req.eventType != null) {
            if (req.eventType.equalsIgnoreCase(Label.eventWorkShopOrderVehicleDelivered)) {
				response = WorkshopOrderApiRestController.createworkshopOrder(req);
        	}
        }
        else {
			response.Status = Label.errorStatus_Error;
			response.Message = Label.responseMessage_Error;
        }
        
    	return response;
    }
    
}