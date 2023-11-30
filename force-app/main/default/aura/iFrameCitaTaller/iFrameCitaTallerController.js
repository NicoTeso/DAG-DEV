({
    doInit: function(cmp) {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);
        const taller = urlParams.get('url');
        var url;

        switch(taller){
            case 'vwcanarias':
                url = $A.get("$Label.c.url_vwcanarias");
                break;
            case 'vwcomerciales':
                url = $A.get("$Label.c.url_vwcomerciales");
                break;
            case 'skoda':
                url = $A.get("$Label.c.url_skoda");
                break;
            case 'audi':
                url = $A.get("$Label.c.url_audi");
                break;
            case 'ducati':
                url = $A.get("$Label.c.url_ducati");
                break;
            case 'honda':
                url = $A.get("$Label.c.url_honda");
                break;
            case 'hondamotos':
                url = $A.get("$Label.c.url_hondamotos");
                break;
            case 'hyundai':
                url = $A.get("$Label.c.url_hyundai");
                break;
            case 'citroen':
                url = $A.get("$Label.c.url_citroen");
                break;
        }
        
        cmp.set("v.setMeOnInit", url);
    }
})