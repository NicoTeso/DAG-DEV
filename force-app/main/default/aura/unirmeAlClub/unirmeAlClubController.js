({
    handleClick : function(cmp, event) {
        var urlString = window.location.href;
        var baseURL = urlString.substring(0, urlString.indexOf("/s"));
        var URL = baseURL + '/s/alta-fidelity-card';
        var action = cmp.get("c.updatePermissions"); 
        $A.enqueueAction(action);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":  URL
        });
        urlEvent.fire();
    }
    
})