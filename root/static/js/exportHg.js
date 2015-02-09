  Ext.onReady(function() {

function check_term_identifier(target){
    var conn = new Ext.data.Connection();

    conn.request({
          url: base_url+'/hg/hg_word_identifier'
         ,method: 'POST'
         ,params: {"term": target.innerHTML}
         ,success: function(response,options) {
                        var data = Ext.decode(response.responseText);
                        identifier_type = data.json_data.word_identifier_type;
                        hg_window_display(target,identifier_type);
                }
         ,failure: function(f,a) {

                        Ext.Msg.alert('Status', 'No response from server');
                }
         ,listeners: {
                 'requestcomplete':{
                            fn: function(conn,res,opt){
                                  alert('DONESKI!!!!');
                                  },
                            scope: this
                            }
                 }
   });
   Ext.Ajax.on("requestcmplete", function(conn,response,options){alert("DONE!!");});
  // return identifier_type;
}

    
Ext.select('.hg3').highlight("0000ff", { attr: 'color', duration: 5});

	Ext.QuickTips.init()
    Ext.select('body').on('click', function(e, t) {
        var t = Ext.get(t);
        if(t.hasClass('hg3')){
            var target = e.getTarget();

            identifier_type_id = check_term_identifier(target);
        }
  });//eo on('click'
}); // eo function onReady
  
function queryChemSpider(smiles) {
    var searchURL = base_url+'/hg/jChemPaintToChemSpider';
    var spiderSearchPanel = new Ext.ux.ManagedIFrame.Panel({
                        autoLoad:{
                                  url      : searchURL
                                ,params         : {smiles :smiles}}
                ,title          : 'SMILE String Search'
                ,defaults       : {border:false, activeTab:0}
                ,hideMode       : 'nosize'
                ,constrain      : true
                ,closable       : true
    });
    
    tabP.add(spiderSearchPanel);

}


function hg_window_display(target,identifier_type){
        var movieURL      = base_url+'/hg/chemEdMovie?term='+target.innerHTML;
        var chemspiderURL = base_url+'/hg/chemSpider?term='+target.innerHTML;
        var jceURL        = base_url+'http://www.jce.divched.org/JCESoft/jcesoftSubscriber/CCA/SCRIPTS/SEARCH.html?'+target.innerHTML;
        var jchemURL      = base_url+'/hg/jchempaint?term='+target.innerHTML;
        var jmolURL       = base_url+'/hg/jmol?term='+target.innerHTML;
        var defURL        = base_url+'/hg/defTran?term='+target.innerHTML;
  
    var defpanel = ({
        	defaultSrc	: defURL
        	,title		: 'Definition'
                ,xtype          : 'iframepanel'
                ,layout         : 'fit'
    });
    
    var spiderpanel = new Ext.ux.ManagedIFrame.Panel({
        	defaultSrc	: chemspiderURL
        	,title		: 'ChemSpider Results'
                ,defaults	: {border:false, activeTab:0}
		,hideMode	: 'nosize'
		,constrain	: true
    });
    var moviepanel = new Ext.ux.ManagedIFrame.Panel({
        	defaultSrc	: movieURL
        	,title		: 'ChemEd DL Video'
                ,defaults	: {border:false, activeTab:0}
		,hideMode	: 'nosize'
		,constrain	: true
    });
    var jmolpanel = new Ext.ux.ManagedIFrame.Panel({
        	defaultSrc	: jmolURL
        	,title		: '3D Structure Model'
                ,defaults	: {border:false, activeTab:0}
		,hideMode	: 'nosize'
		,constrain	: true
    });

    var jchempaintpanel = new Ext.Panel({
        	autoLoad	: jchemURL
        	,title		: '2D Structure Model'
                ,defaults	: {border:false, activeTab:0}
		,hideMode	: 'nosize'
		,constrain	: true
    });

    var jceMoviepanel = new Ext.ux.ManagedIFrame.Panel({
        	defaultSrc	: jceURL
        	,title		: 'MOVIES'
                ,defaults	: {border:false, activeTab:0}
		,hideMode	: 'nosize'
		,constrain	: true
		,autoScroll	: true
    });
    
    var tab_items = new Array();
    tab_items[0] = defpanel;
    if(identifier_type == 1){
                tab_items[1] = spiderpanel;
                tab_items[2] = jmolpanel;
                tab_items[3] = jchempaintpanel;
    }

    tabP = new Ext.TabPanel({
             title              : 'HyperGlossary'
            ,enableTabScroll    : true
            ,activeTab          : 0
            ,items              : tab_items
    });


            win = new Ext.Window({
                title           : 'Information Overlay For: '+target.innerHTML,
                layout          : 'fit',
                constrain       : true,
   		width           : 600,
   		height          : 500,
                closable        : true,
                border          : true,
		items           : [tabP]
            });
        

  win.show(this); 
}
