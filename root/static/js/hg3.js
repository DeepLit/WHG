var myURL, myWait;
var count; 
var tabP;
var identifier_type;
var sets = getCount();
count = 1;

function myStart( wait, url ) { myWait = wait; myURL = url+"?sets="+sets; myTimer(); }
function myTimer() { window.setTimeout('doNext()', myWait); }
function doNext()  { getUpdate(); if (count < sets ) { myTimer();} }
function getUpdate() { 
	count = count + 1;
	var xhr = createXHR(); 
  
	xhr.onreadystatechange  = function() { 
		if (xhr.readyState  == 4) {
			if (xhr.status  == 200) {
				document.getElementById("hgDiv").innerHTML = xhr.responseText;
			} else {
				document.getElementById("hgDiv").innerHTML = "Error code " + xhr.status;
			}
		}
	}; 

	xhr.open("POST", myURL, true); 
	xhr.send(null); 
    

} 

function getCount() {
	count_xhr  = createXHR();
        var sets;
        var wordCount;
	
	count_xhr.open("GET", base_url+'/hg/getCount', true); 
	count_xhr.send(null); 
	count_xhr.onreadystatechange  = function() { 
		if (count_xhr.readyState  == 4) {
			if (count_xhr.status  == 200) {
				wordCount = parseInt(count_xhr.responseText);
                                
                                if(wordCount > 1000){ sets = parseInt(wordCount / 1000);}
                                else{ sets = 1}

			} else {
				document.getElementById("hgDiv").innerHTML = "Error code " + count_xhr.status;
			}
		}
                               // alert('number of words = ' + wordCount + ' SETS = ' + sets);
	}; 


}

function createXHR() 
{

    var request = false;
        try {
            request = new ActiveXObject('Msxml2.XMLHTTP');
        }
        catch (err2) {
            try {
                request = new ActiveXObject('Microsoft.XMLHTTP');
            }
            catch (err3) {
		try {
			request = new XMLHttpRequest();
		}
		catch (err1) 
		{
			request = false;
		}
            }
        }
    return request;
}

	     
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
        var uniprotURL    = base_url+'/hg/uniprotJmol?term='+target.innerHTML;
        var chemeddl      = 'http://www.chemeddl.org/resources/models360/modelsJmol.php'

    var defpanel = ({
        	defaultSrc	: defURL
                ,id             : 'definition'
        	,title		: 'Definition'
                ,xtype          : 'iframepanel'
                ,layout         : 'fit'
                ,tbar           : [
                                    {
                                     xtype  : 'button'
                                    ,text   : 'Back'
                                    ,handler : function(btn){
                                        Ext.getCmp('definition').getFrameWindow().back();
                                        }
                                   }
                                  ]
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
    //var jchempaintpanel = new Ext.ux.ManagedIFrame.Panel({
        	autoLoad	: {url:jchemURL
                ,scripts:true}
                //defaultSrc       : jchemURL
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

    var proteinpanel = new Ext.ux.ManagedIFrame.Panel({
                defaultSrc      : uniprotURL
                ,title          : '3D Protein Model'
                ,defaults       : {border:false, activeTab:0}
                ,hideMode       : 'nosize'
                ,constrain      : true
    });

    
    var tab_items = new Array();
    tab_items[0] = defpanel;
    if(identifier_type == 1){
                tab_items[1] = spiderpanel;
                tab_items[2] = jmolpanel;
                tab_items[3] = jchempaintpanel;
    }
    
    if(identifier_type == 2){tab_items.push(proteinpanel);}
    
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
