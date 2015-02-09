Ext.onReady(function() {

count = 1;

Ext.QuickTips.init();
Ext.ns('Ext.ux.form');
Ext.ux.form.XCheckbox = Ext.extend(Ext.form.Checkbox, {
     offCls:'xcheckbox-off'
    ,onCls:'xcheckbox-on'
    ,disabledClass:'xcheckbox-disabled'
    ,submitOffValue:'false'
    ,submitOnValue:'true'
    ,checked:false

    ,onRender:function(ct) {
        // call parent
        Ext.ux.form.XCheckbox.superclass.onRender.apply(this, arguments);

        // save tabIndex remove & re-create this.el
        var tabIndex = this.el.dom.tabIndex;
        var id = this.el.dom.id;
        this.el.remove();
        this.el = ct.createChild({tag:'input', type:'hidden', name:this.name, id:id});

        // update value of hidden field
        this.updateHidden();

        // adjust wrap class and create link with bg image to click on
        this.wrap.replaceClass('x-form-check-wrap', 'xcheckbox-wrap');
        this.cbEl = this.wrap.createChild({tag:'a', href:'#', cls:this.checked ? this.onCls : this.offCls});

        // reposition boxLabel if any
        var boxLabel = this.wrap.down('label');
        if(boxLabel) {
            this.wrap.appendChild(boxLabel);
        }

        // support tooltip
        if(this.tooltip) {
            this.cbEl.set({qtip:this.tooltip});
        }

        // install event handlers
        this.wrap.on({click:{scope:this, fn:this.onClick, delegate:'a'}});
        this.wrap.on({keyup:{scope:this, fn:this.onClick, delegate:'a'}});

        // restore tabIndex
        this.cbEl.dom.tabIndex = tabIndex;
    } // eo function onRender

    ,onClick:function(e) {
        if(this.disabled || this.readOnly) {
            return;
        }
        if(!e.isNavKeyPress()) {
            this.setValue(!this.checked);
        }
    } // eo function onClick

    ,onDisable:function() {
        this.cbEl.addClass(this.disabledClass);
        this.el.dom.disabled = true;
    } // eo function onDisable

    ,onEnable:function() {
        this.cbEl.removeClass(this.disabledClass);
        this.el.dom.disabled = false;
    } // eo function onEnable

    ,setValue:function(val) {
        if('string' == typeof val) {
            this.checked = val === this.submitOnValue;
        }
        else {
            this.checked = !(!val);
        }

        if(this.rendered && this.cbEl) {
            this.updateHidden();
            this.cbEl.removeClass([this.offCls, this.onCls]);
            this.cbEl.addClass(this.checked ? this.onCls : this.offCls);
        }
        this.fireEvent('check', this, this.checked);

    } // eo function setValue

    ,updateHidden:function() {
        this.el.dom.value = this.checked ? this.submitOnValue : this.submitOffValue;
    } // eo function updateHidden

    ,getValue:function() {
        return this.checked;
    } // eo function getValue

}); // eo extend

// register xtype
Ext.reg('xcheckbox', Ext.ux.form.XCheckbox);

// eo file 

 var params;
 var definition;
 var word_id;
 var cat_word_id;
 var word;
 var word_type_id;
 var category_id;
 var formWin;
 var editor;
 var editForm;
 var formURL;
 var formInsert;
 var glossformWin;
 var current_category_id;


/*Get user roles*/
var roleFields = Ext.data.Record.create([
        { name: 'role_id',    type: 'int' },
        { name: 'role',       type: 'string' }
    ]);

var roleStore = new Ext.data.JsonStore({
        url:        base_url+'/contentmgt/getRoles',
        root:       'json_data',
        fields:     roleFields
    });

/*Initialize Possible User Roles*/
var is_user_admin = 0;
var can_create_glos = 0;
var can_edit_def = 0;
var can_add_words = 0;
var is_superuser = 0;
var is_content_admin = 0;

/*Load current user's roles*/
roleStore.load( {callback: function(){
              roleStore.each(function(record){
              //alert(record.data['role']+' : '+record.data['role_id']);
			switch (record.data['role_id']){
			case 1:
                                is_user_admin = 1;
				break;
			case 2:
                                can_create_glos = 1;
				break;
			case 3:
                                can_edit_def = 1;
				break;
			case 4:
                                can_add_words = 1;
				break;
			case 8:
                                is_superuser = 1;
				break;
			case 9:
                                is_content_admin = 1;
				break;
			
			}//end switch

          	});//end each */             
initButtons();
}

});

/*builds the combobox that is placed in the toolbar of the grid*/
var categories = Ext.data.Record.create([
        { name: 'id',    type: 'int' },
	{ name: 'editable',  type: 'int' },
	{ name: 'active',  type: 'int' },
        { name: 'category',  type: 'string' }
    ]);

var catStore = new Ext.data.JsonStore({
        url:        base_url+'/contentmgt/getCategory',
        root:       'json_cats',
        fields:     categories
    });

var cCombo = new Ext.form.ComboBox({
    store		: catStore,
    fieldLabel		: 'Categories',
    displayField	: 'category',
    valueField		: 'id',
    tpl                 : new Ext.XTemplate(
                         '<tpl for=".">',
                                '<tpl if="active==1">',
                                        '<div class="x-combo-list-item" style="color: blue;">{category}</div>',
                                '</tpl>',
                                '<tpl if="active==0 && this.isAdmin()==1">',
                                        '<div class="x-combo-list-item" style="color: red;">{category}</div>',
                                '</tpl>',
                         '</tpl>',
                         {
                                isAdmin: function() {
                                        return can_create_glos;
                                        }
                         }
                         ),
    id			: 'category',
    mode		: 'local',
    typeAhead		: false,
    triggerAction	: 'all',
    emptyText		: 'Select a glossary...',
    forceSelection	: true,
    selectOnFocus	: true
});

var Languages = Ext.data.Record.create([
        { name: 'id',    mapping:'id', type: 'int' },
        { name: 'language',  mapping:'language', type: 'string' }
    ]);

var langStore = new Ext.data.JsonStore({
        url		: base_url+'/contentmgt/getLanguage',
        root		: 'json_lang',
        idProperty:'id',
        fields		: Languages
    });

/*Builds the batch upload form*/

var fileUpload = new Ext.form.TextField({
	fieldLabel	: 'File',
        name		: 'file',
        id		: 'file',
        allowBlank	: false,
	inputType	: 'file',
	width		: 200
});

var uploadButton = new Ext.Button({
    text:'Upload File',
    handler: function(){
                fileform.getForm().submit({
                            waitMsg: 'Uploading and Processing...',
                            success: function(fp, o){
                                msg('Success', 'Processed file "'+o.result.file+'" on the server');
                            }
                        })
			}
});

function batchload(current_category_id){
var fileform = new Ext.FormPanel({
    url			: base_url+'/contentmgt/fileUpload',
    method		: 'POST',
    fileUpload		: true,
    autoHeight          : true,
   // width		: 250,
    bodyStyle		: 'padding: 5px',
    labelAlign		: 'top',
    bodyStyle           : 'padding: 10px 10px 0 10px;',
    labelWidth          : 50,
    defaults            : {
                                anchor        : '95%',
                                allowBlank    : false,
                                msgTarget     : 'side'
                          },
    items		: [
                {
                        xtype           : 'fileuploadfield',
                        id              : 'file',
                        emptyText       : 'Select an XML glossary file',
                        fieldLabel      : 'Glossary File',
                        name            : 'file'
                }
                ,
    		{
	 		xtype		: 'hidden',
         		name		: 'category_id',
         		id		: 'category_id',
                        value           : current_category_id
    		}],
    buttons		: [{
    text:'Upload File',
    handler: function(){
                fileform.getForm().submit({
                            waitMsg: 'Uploading and Processing...',
                            success: function(fp, o){
                            batchWin.close();
                            //alert(o.result);
                            //    Ext.Msg.alert('Success', 'Processed file "'+o.result.file+'" on the server');
                            }
                        })
			}
                         }],
});


  var  batchWin = new Ext.Window({
                title		: 'Batch Definition Upload',
		width		: 400,
		height		: 150,
		layout		: "fit",
		closeAction	: "close",
                plain           : true,
		items		: [fileform]
 });

batchWin.show(this);
}

//--------------------------------------------------------------------------------------------------------------------------
//media upload

function mediaUpload(){

        var expImage = /^.*.(jpg|JPG|jpeg|JPEG|png|PNG|gif|GIF)$/;
        var expVideo = /^.*.(avi|AVI|dcr|DCR|mov|MOV|swf|SWF|ram|RAM|rm|RM)$/;

function validateFileExtension(filename, expression){
        return expression.test(filename);
}

var mediaTypes = Ext.data.Record.create([
        { name: 'media_type_id', mapping: 'media_type_id',   type: 'int' },
        { name: 'media_type', mapping: 'media_type',  type: 'string' }
    ]);

var mediaStore = new Ext.data.JsonStore({
        url		: base_url+'/contentmgt/getMediaType',
        root		: 'json_fields',
        idProperty      : 'media_type_id',
        fields		: mediaTypes
    });
                var fileupload = ({
                        xtype           : 'fileuploadfield',
                        id              : 'file',
                        emptyText       : 'Select a media file',
                        fieldLabel      : 'Media File',
                        name            : 'file'
                });
                var fileurl = ({
                        xtype           : 'textfield',
                        id              : 'url',
                        emptyText       : 'URL',
                        fieldLabel      : 'Media URL',
                        name            : 'url'
                });

        mediaStore.load();
        mediaStore.on('load', function(mediaStore){
                Ext.getCmp('mediatype').setValue(mediaStore.getAt(0).get('media_type_id'));
                });

var mediaform = new Ext.FormPanel({
    url			: base_url+'/contentmgt/mediaUpload',
    method		: 'POST',
    fileUpload		: true,
    autoHeight          : true,
    bodyStyle		: 'padding: 5px',
    labelAlign		: 'top',
    bodyStyle           : 'padding: 10px 10px 0 10px;',
    labelWidth          : 50,
    defaults            : {
                                anchor        : '95%',
                                allowBlank    : false,
                                msgTarget     : 'side'
                          },
    items		: [{
                xtype         : 'fieldset',
                id            : 'sourceset',
                title         : 'Browse to file or Enter URL',
                collapsible   : false,
                autoHeight    : true,
                defaults      : {
                                  anchor        : '93%',
                                  allowBlank    : false,
                                  msgTarget     : 'side'
                                },
                items         : [
      {
        xtype      : 'radiogroup',
        id         : 'filesource',
        fieldLabel : 'File Source',
        vertical   : false,
        items      : [
                      {boxLabel: 'Load File', id: 'radiofile', name: 'source', inputValue : 'fileupload', handler: function(){if(Ext.getCmp('radiofile').getValue()){Ext.getCmp('sourceset').remove(Ext.getCmp('url'));Ext.getCmp('sourceset').add(fileupload);mediaform.doLayout();}}},
                      {boxLabel: 'Input URL', id: 'radiourl', name: 'source', inputValue : 'url',checked: true,  handler: function(){if(Ext.getCmp('radiourl').getValue()){Ext.getCmp('sourceset').remove(Ext.getCmp('file'));Ext.getCmp('sourceset').add(fileurl);mediaform.doLayout();}}}
                     ],
      },{

    	store		: mediaStore,
        name            : 'mediatype',
        id              : 'mediatype',
    	fieldLabel	: 'Media Type',
    	displayField	: 'media_type',
    	valueField	: 'media_type_id',
        hiddenName      : 'media_type',
    	xtype		: 'combo',
    	mode		: 'local',
    	typeAhead	: true,
    	triggerAction	: 'all',
    	emptyText	: 'Select a media type...',
    	forceSelection	: true,
    	selectOnFocus	: true,
	width		: 25 
       },
      fileurl

                ]},
                {
                        xtype           : 'textfield',
                        id              : 'medianame',
                        emptyText       : 'Give a name',
                        fieldLabel      : 'Media Name',
                        name            : 'medianame'
                },
                {
                        xtype           : 'textarea',
                        id              : 'description',
                        fieldLabel      : 'Description',
                        emptyText       : 'Enter a description of the file',
                        name            : 'description',
                        height          : 125
                },
                {
		        xtype		: 'hidden',
                   	name		: 'category_id',
                   	id		: 'category_id',
                    	value		: cCombo.getValue()
                },
                {
                        xtype           : 'textarea',
                        id              : 'keywords',
                        emptyText       : 'Please add some keywords to describe this file',
                        fieldLabel      : 'Keywords',
                        name            : 'keywords'
                }
    		],
    buttons		: [{
    text:'Upload',
    handler: function(){
         var theForm = mediaform.getForm();
         var expression;
         var filename;
         var url = Ext.getCmp('url');
         if (!theForm.isValid()) {
            Ext.MessageBox.alert('Change Picture',
              'Please fill out all fields');
            return;
         }
//alert(Ext.getCmp('file').value);
         if(Ext.getCmp('mediatype').getValue() == 1){expression = expImage;}
         if(Ext.getCmp('mediatype').getValue() == 2){expression = expVideo;}
         if(Ext.getCmp('file').value){filename = Ext.getDom('file').value;}
         if(url){filename = Ext.getDom('url').value;}


         if (!validateFileExtension(filename, expression)) {
            Ext.MessageBox.alert('Change Picture',
              'Only JPG or PNG, please.');
            return;
         }
                mediaform.getForm().submit({
                            waitMsg: 'Uploading and Processing...',
                            success: function(fp, o){
                                mediaUploadWin.close();
                            }
                        })//end submit
			}//end of handler function
                         }],
});


  var  mediaUploadWin = new Ext.Window({
                title		: 'Media Content Upload',
		width		: 400,
		height		: 570,
		layout		: "fit",
		closeAction	: "close",
                plain           : true,
		items		: [mediaform]
 });

mediaUploadWin.show(this);

}

//--------------------------------------------------------------------------------------------------------------------------

/*Load the categories from the database into the select.  When a category is selected the grid is populated with the terms*/
	catStore.load();
	cCombo.on('select', function(){ 
				gridStore.load({params:{cat:cCombo.getValue()}});
                                current_category_id = cCombo.getValue();
                                initButtons();
		                var detailP = Ext.getCmp('detail-panel');
		                detailP.load({url:base_url+'/contentmgt/message', params:{message : 'Choose a term to see addional content'}});

				/*Enable the deletion of the glossary and addition of term once a glossary is selected*/
				if(catStore.getById(cCombo.getValue()).get('editable') == 1){
                                      if(can_create_glos == 1){
                                          adminSubMenu.items.get('deleteGlossary').enable();
                                          adminSubMenu.items.get('editGlossary').enable();
					  adminSubMenu.items.get('setActive').enable();
                                      }
                                      if(can_add_words ==  1){
                                          glossMenu.items.get('addTerm').enable();
                                          glossMenu.items.get('uploadmedia').enable();
                                      }
                                      if(is_content_admin == 1){
                                          adminSubMenu.items.get('dumpGlossary').enable();
					  adminSubMenu.items.get('batchTerm').enable();
                                      }
				}
				else{
					adminSubMenu.items.get('deleteGlossary').disable();
					adminSubMenu.items.get('editGlossary').disable();
					glossMenu.items.get('addTerm').disable();
					glossMenu.items.get('uploadmedia').disable();
					adminSubMenu.items.get('batchTerm').disable();
	         			glossMenu.items.get('editTerm').disable();
		 			glossMenu.items.get('deleteTerm').disable();
					adminSubMenu.items.get('setActive').disable();
				}
				if(catStore.getById(cCombo.getValue()).get('active') == 1){
					adminSubMenu.items.get('setActive').setText('Make Glossary Inactive');
                                }
				if(catStore.getById(cCombo.getValue()).get('active') == 0){
					adminSubMenu.items.get('setActive').setText('Make Glossary Active');
                                }
		});

	
        var gridStore  = new Ext.ux.grid.livegrid.Store({
            autoLoad 	: true,
            url      	: base_url+'/contentmgt/getWord',
            bufferSize 	: 100,
            reader     	: new Ext.ux.grid.livegrid.JsonReader({
                root            : 'json_words',
                versionProperty : 'json_version',
                totalProperty   : 'json_totalCount',
                id              : 'id'
              }, [ 
	              { name: 'cat_word_id',    type: 'int' },
	              { name: 'word_id',    type: 'int' },
		      { name: 'word',  type: 'string' },
	              { name: 'word_type_id',    type: 'int' },
	              { name: 'word_type',    type: 'string' }
            ]),
            sortInfo   : {field: 'word', direction: 'ASC'}
        });

   var infoStore = new Ext.data.Store({
        proxy: new Ext.data.HttpProxy({
            url		: base_url+'/contentmgt/definition',
            method	: 'POST'
        }),
        baseParams:  { cat:cCombo.getValue() },
        reader: new Ext.data.JsonReader({
            root: 'json_info'},
                [{ name: 'word', type: 'string'},
                 { name: 'word_id', type: 'int'},
                 { name: 'cat_word_id', type: 'int'},
                 { name: 'category_id', type: 'int'},
                 { name: 'definition', type: 'string'},
	         { name: 'word_type_id',    type: 'int' },
	         { name: 'word_type',    type: 'string' }
                        ])
    });

    var myView = new Ext.ux.grid.livegrid.GridView({
        nearLimit : 100,
        loadMask  : {
            		msg :  'Buffering. Please wait...'
        	    }
    });

            var testButton =  {
                        text		: 'Edit',
			tooltip		: 'Edit definition of term'

		};
		
        var testTool = new Ext.ux.grid.livegrid.Toolbar({
            view        	: myView,
            displayInfo 	: true,
	    prependButtons	: false,
        });
		
/*Template to view additional information abou the selected term*/
var tpl = new Ext.XTemplate(
	'<table width="90%">',
	'<tr><td><h2>Additional SECRET Information</h2></td></tr>',
	'<tpl for=".">',	
	'<div class="thumb-wrap" id="{word}">',
        '<tr><td><p><b>Term:</b> {word}</p></td></tr>',
        '<tr><td><p><b>Category ID:</b> {category_id}</p></div></td></tr>',
        '<tr><td><p><b>Term ID:</b> {word_id}</p></td></tr>',
        '<tr><td><p>{definition}</td></tr></p></div>',
	'</tpl>',
	'</table>',
	'<div class="x-clear"></div>' 
);


/*Builds the details panel*/
/*var detailPanel = new Ext.Panel({
    id		: 'detail-panel',
    frame	: true,
    height	: 400,
    width       : 200,
    collapsible	: false,
    region	: 'center',
    title	: 'Complete Record',
    autoScroll	: true,
});*/
    var detailPanel = ({
        frame	        : true,
        id		: 'detail-panel',
        //xtype           : 'iframepanel',
        //flex            : 2,
        title	        : 'Complete Record',
        collapsible     : false,
        //layout          : 'fit',
        region          : 'center',
        autoScroll	: true
    });


/*Builds the grid that shows the terms from the selected category*/
    var livegrid = new Ext.ux.grid.livegrid.GridPanel({
        enableDragDrop : false,
        cm             : new Ext.grid.ColumnModel([
            			new Ext.grid.RowNumberer({header : '#' }),
            			{header: "Word",   align : 'left',   width: 250, sortable: true, dataIndex: 'word'},
            			{header: "Word Type",   align : 'left',   width: 120, sortable: false, dataIndex: 'word_type'}
        		 ]),
        loadMask       : {
            			msg : 'Loading...'
        		 },
        title          : 'Terms in Glossary',
	id	       : 'livegrid',
        //height 	       : 400,
        margins: '5 0 0 0',
        cmargins: '5 5 0 0',
        region         : 'west',
        width          : 370,
        floatable      : false,
        
	store	       : gridStore,
        selModel       : new Ext.ux.grid.livegrid.RowSelectionModel({singelSelect: true}),
	viewConfig     : {forceFit: true},
	//split	       : true,
	//region	       : 'west',
        view           : myView,
 	tbar	       : [
			   cCombo,'->'/*,
		{
		 xtype		: 'textfield',
		 name		: 'searchfield',
		 emptyText	: 'Enter Search Term'
		}*/
            		],
	
        bbar           : testTool/*,
	plugins:[new Ext.ux.grid.Search({
		iconCls:false,
		minChar:2,
		autoFocus:true,
		position: 'top'
		})],*/
    });


var adminSubMenu = new Ext.menu.Menu({
                 id             : 'adminSubMenu',
		 items		: [{text	: 'Add Glossary',
		 		    id		: 'addGlossary',
				    handler	: function(){ftStore.load();
                                                             var formtype = 'add';
                                                             formGloss(formtype); 
                                                  }

				   },
		 		   {text	: 'Edit Glossary',
		 		    id		: 'editGlossary',
                                    handler     : function(){
                                                                  ftStore.load();
                                                                  var formtype = 'edit';
                                                                  formGloss(formtype);
                                                  }
				   },
		 		   {text	: 'Delete Glossary',
		 		    id		: 'deleteGlossary',
				    handler	: function(){deleteGlossary();},
				   },
                                   '-',
                                  {
                                   xtype         : 'button',
                                   id            : 'setActive',
                                   name          : 'setActive',
                                   text          : 'Set Glossary Inactive',
                                   //enableToggle  : true,
                                   handler : function(){toggleActive();}
                                },
                                   '-',
		 		   {text	: 'DUMP Glossary',
		 		    id		: 'dumpGlossary',
                                    handler     : function(){
                                                                  dumpGloss();
                                                  }
				   },
				   {text	: 'Batch Term Upload',
				    id		: 'batchTerm',
				    handler	: function(){batchload(current_category_id);}},
                 
                 ]
});


/*Function to delete glossary*/
function deleteGlossary() {
    var conn = new Ext.data.Connection();

    conn.request({
    	  url: base_url+'/contentmgt/deleteGlossary'
         ,method: 'POST'
         ,params: {"category_id": cCombo.getValue()}
    	 ,success: function(f,a) {
										
			Ext.Msg.alert('Status', 'Glossary has been deleted');
                        catStore.load();
                        gridStore.removeAll();
    		}
    	 ,failure: function(f,a) {
										
       			Ext.Msg.alert('Status', 'ERROR deleting glossary');
    		}
   });

}


/*Function to change glossary status*/
function toggleActive(btn) {
    var conn = new Ext.data.Connection();

    conn.request({
    	  url: base_url+'/contentmgt/toggleActive'
         ,method: 'POST'
         ,params: {"category_id": cCombo.getValue()}
    	 ,success: function(f,a) {
										
			Ext.Msg.alert('Status', 'Glossary status has changed');
                        catStore.load();
    		}
    	 ,failure: function(f,a) {
										
       			Ext.Msg.alert('Status', 'ERROR saving data');
    		}
   });

}


var glossMenu = new Ext.menu.Menu({
	       	
		 id		: 'glossMenu',
                 items          : [
				   {text 	: 'Add Term',
		 		    id		: 'addTerm',
				    handler	: function(){formInsert();
				    			     formURL = base_url+'/contentmgt/addTerm';}
				   },
				   {text 	: 'Edit Term',
		 		    id		: 'editTerm',
				    handler	: function(){
    								formURL = base_url+'/contentmgt/updateTerm';
				    				infoStore.load({
				    					params: params,
				                                    	callback: function(){ 
                                                                          word_id = infoStore.getAt(0).data.word_id;
                                                                          word = infoStore.getAt(0).data.word;
                                                                          word_type_id = infoStore.getAt(0).data.word_type_id;
                                                                          var word_type = infoStore.getAt(0).data.word_type;
                                                                          cat_word_id = infoStore.getAt(0).data.cat_word_id;
                                                                          formEdit(word_id,word,word_type_id,word_type,cat_word_id);
											}});
					}
				   },
				   {text 	: 'Delete Term',
		 		    id		: 'deleteTerm',
				    handler	: function(){
				    				infoStore.load({
				    					params: params,
				                                    	callback: function(){ 
                                                                                       cat_word_id = infoStore.getAt(0).data.cat_word_id;
                                                                                       word_id = infoStore.getAt(0).data.word_id;
                                                                                       word = infoStore.getAt(0).data.word;
                                                                                       deleteTerm(cat_word_id,word,word_id);
										}});
					}
				   },
				   {text 	: 'Upload Media',
		 		    id		: 'uploadmedia',
				    handler	: function(){
                                                        mediaUpload();
				    			     }
				   },
                                    {
                                      text : 'Admin Tools',
                                      menu : adminSubMenu}]
			 
});

/*Function to delete a term*/
function deleteTerm(cat_word_id,word,word_id) {
    var conn = new Ext.data.Connection();

    conn.request({
    	 url: base_url+'/contentmgt/deleteTerm'
         ,method: 'POST'
         ,params: {"cat_word_id": cat_word_id, "word": word, "category_id": cCombo.getValue(), "word_id": word_id}
    	 ,success: function(f,a) {
										
			Ext.Msg.alert('Status', 'Changes saved successfully.');
                        gridStore.load({params:{cat:cCombo.getValue()}});
    		}
    	 ,failure: function(f,a) {
										
       			Ext.Msg.alert('Status', 'ERROR saving data');
    		}
   });

}


/*Function to dump entire glossary*/
function dumpGloss() {
  var defURL   = base_url+'/contentmgt/dumpGloss';
  
    var dumppanel = Ext.create ({
                autoLoad: {
                       url	         : defURL
                      ,method            : 'POST'
                      ,params            : {"category": cCombo.getRawValue(), "category_id": cCombo.getValue()}
                      ,submitAsTarget    : true
                 }
                ,loadMask       : 'Building html dump of glossary....' 
                ,title		: 'Glossary Dump'
                ,xtype          : 'iframepanel'
                ,layout         : 'fit'
		,autoScroll	: true
    });

            win = new Ext.Window({
                title: 'Popup Window',
                layout:'fit',
   		width:600,
   		height:500,
                closable: true,
                border:true,
		items:[dumppanel]
            });
        

  win.show(this); 
}
var tb = Ext.getCmp('livegrid').getTopToolbar();
tb.add({
	text		: 'Glossary Actions',
	id		: 'glossActions',
	tooltip		: {text:'Glossary and term management functions',title:'Glossary Actions'},
	menu		: glossMenu
	});

function initButtons(){		
    if(can_create_glos == 1){adminSubMenu.items.get('addGlossary').enable();}else{adminSubMenu.items.get('addGlossary').disable();}
    glossMenu.items.get('editTerm').disable();
    glossMenu.items.get('addTerm').disable();
    glossMenu.items.get('deleteTerm').disable();
    glossMenu.items.get('uploadmedia').disable();
    adminSubMenu.items.get('batchTerm').disable();
    adminSubMenu.items.get('deleteGlossary').disable();
    adminSubMenu.items.get('editGlossary').disable();
    adminSubMenu.items.get('dumpGlossary').disable();
    adminSubMenu.items.get('setActive').disable();
};

/*Builds the panel that houses the grid and detail(additional information) panel*/
	var ct = new Ext.Panel({
		renderTo	: 'content_1',
		frame		: true,
		title		: 'Term Management Window',
		height		: 510,
		layout		: 'border',
                defaults: {
                        collapsible: true,
                        split: true,
                        animFloat: false,
                        autoHide: false,
                        useSplitTips: true,
                        bodyStyle: 'padding:15px'
            },
               items:[
			livegrid, detailPanel
              ]
	});

/*When a row is selected this function gets additional infromation from the server and populates the detail panel*/	
	livegrid.getSelectionModel().on('rowselect', function(selModel, rowIdx, r) {
		var detailP = Ext.getCmp('detail-panel');
		params = { cat_word_id: r.data['cat_word_id'], word_id: r.data['word_id'], word: r.data['word'],cat:cCombo.getValue()};
		detailP.load({url:base_url+'/contentmgt/recordView', params:params});
		if(catStore.getById(cCombo.getValue()).get('editable') == 1){
	         	glossMenu.items.get('editTerm').enable();
		 	glossMenu.items.get('deleteTerm').enable();
		}
		else{
	         	glossMenu.items.get('editTerm').disable();
		 	glossMenu.items.get('deleteTerm').disable();
		}
});
	editor = 
		{
				id: 'myeditor',
				xtype: "tinymce",
				tinymceSettings: {
					theme : "advanced",
					plugins: "safari,pagebreak,style,layer,table,advhr,advimage,advlink,emotions,iespell,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,noneditable,visualchars,nonbreaking,xhtmlxtras,template,fullscreen",
					theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect,fontsizeselect",
					theme_advanced_buttons2 : "cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,help,code,|,insertdate,inserttime,preview,|,forecolor,backcolor",
					theme_advanced_buttons3 : "tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,emotions,iespell,media,advhr,|,print,|,ltr,rtl,|,fullscreen",
					theme_advanced_buttons4 : "insertlayer,moveforward,movebackward,absolute,|,styleprops,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template,pagebreak",
					theme_advanced_toolbar_location : "top",
					theme_advanced_toolbar_align : "left",
					theme_advanced_statusbar_location : "bottom",
					theme_advanced_resizing : false,
					extended_valid_elements : "a[name|href|target|title|onclick],img[class|src|border=0|alt|title|hspace|vspace|width|height|align|onmouseover|onmouseout|name],hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style]",
					template_external_list_url : "example_template_list.js",
                                        external_image_list_url : base_url+'/static/js/image_list_'+cCombo.getValue()+'.js',
                                        media_external_list_url : base_url+'/static/js/video_list_'+cCombo.getValue()+'.js',
                                        entity_encoding : 'raw'

				},
		};					
  var editorURL;


var lCombo = new Ext.form.ComboBox({
    store		: langStore,
    fieldLabel		: 'Languages',
    displayField	: 'language',
    valueField		: 'id',
    id			: 'language',
    mode		: 'local',
    typeAhead		: true,
    triggerAction	: 'all',
    emptyText		: 'Select a language...',
    forceSelection	: true,
    selectOnFocus	: true
});

var fileJmolUpload = new Ext.form.TextField({
	fieldLabel	: 'Jmol File',
        name		: 'jfile',
        id		: 'jfile',
        allowBlank	: true,
	inputType	: 'file',
	width		: 200
});

editForm = new Ext.FormPanel({
        labelAlign	: 'top',
        title		: 'Term information',
	id		: 'editForm',
	fileUpload	: true,
    	enctype		: 'multipart/form-data',
        bodyStyle	: 'padding:5px',
	border		: false,
	layout		: 'fit',
        width		: 800,
        items: [{
            xtype	: 'tabpanel',
	deferredRender	: false,
            plain	: true,
            activeTab	: 0,
            height	: 435,
            defaults	: {bodyStyle:'padding:10px'},
            items	: [{
                	    title 		: 'Term Details',
	    		    layout		: 'column',
            		    defaults		: {bodyStyle:'padding:10px 10px 10px 10px'},

                items: [{
			
				layout		: 'form',
				xtype		: 'fieldset',
				columnWidth  	: .5,
				anchor 		: '-20',
                		title 		: 'Term Basic Information',
				autoHeight	: true,
				items: [{
                    			fieldLabel	: 'word',
					xtype		: 'textfield',
		    			id		: 'word',
                    			name		: 'word',
                    			allowBlank	: false,
                			},{
                    			fieldLabel	: 'Synonym',
					xtype		: 'textarea',
		    			height		: 200,
		    			width		: 200,
                   			name		: 'synonym',
                    			id		: definition
                			},{
					xtype		: 'hidden',
                   			name		: 'word_id',
                    			id		: word_id
                			},{
					xtype		: 'hidden',
                   			name		: 'category_id',
                    			id		: category_id
                			},lCombo
                		]
            		},{
					layout		: 'form',
	    				xtype 		: 'fieldset',
					checkboxToggle	: false,
					columnWidth  	: .5,
					anchor 		: '-20',
                			title		: 'Structure Information',
					collapsible	: true,
					autoHeight	: true,
					collapsed	: true,
		
                		items: [fileJmolUpload
					,{
                    			fieldLabel	: 'Smile String',
					xtype		: 'textfield',
                    			name		: 'smile',
                    			id		: 'smile'
					
                		}]
            				},{
					layout		: 'form',
	    				xtype 		: 'fieldset',
					columnWidth  	: .5,
					anchor 		: '-20',
					checkboxToggle	: false,
					collapsed	: true,
                			title		: 'Multimedia Information',
					collapsible	: true,
					autoHeight	: true,
                			items: [{
                   			 	fieldLabel	: 'Images',
						xtype		: 'textfield',
                    				name		: 'ifile',
                    			 	id		: 'ifile',
						},{
                    				fieldLabel	: 'Video',
						xtype		: 'textfield',
                    				name		: 'vfile',
                    				id		: 'vfile'
                			}],
				}]
            },{
                cls		:'x-plain',
                title		:'Definition',
                layout		:'fit',
                items: [editor
                ]
            }]
        }],
    buttons: [ {text		: "Cancel",
    		handler 	: function(){ formWin.close();}}, 
    	       {text		: "Save",
	        formBind	: true,
	        scope		: this,
		errorReader	: new Ext.data.JsonReader({
            				root: 'json_response'},
                			[{ name: 'success', type: 'bool'},
                 			 { name: 'message', type: 'string'}
                        		]),

	        handler		: function(){ 
						editForm.getForm().submit({
    										url		: formURL,
    										method		: 'POST',
    										success: function(f,a) {
													//var response = resp.responseText;
										
													Ext.Msg.alert('Status', 'Changes saved successfully.');
													formWin.close();
    										},
    										failure: function(f,a) {
													//var response = resp.responseText;
										
       													alert('ERROR saving data');
    										},
								
										//waitTitle	: 'Status',
										//waitMsg		: 'Saving Data'
									  })
					 }
	       }, 
	       {text		:'LOAD',
	        handler 	: function(){Ext.getCmp('language').setValue(25);editForm.getForm().load({
                                            		url: base_url+'/contentmgt/def',
					                params:  params,
						        })
						 }
	      }
	     ]

    });





	formWin = new Ext.Window({
		title		: "Edit",
		width		: 800,
		height		: 500,
		minWidth	: 100,
		minHeight	: 100,
		layout		: "fit",
		modal		: false,
		resizable	: true,
		maximizable	: true,
		closeAction	: "close",
		hideMode	: "offsets",
		constrainHeader	: true,
		items: [editForm
		]
	});


 var radios = new Ext.form.RadioGroup({  
    		fieldLabel	: 'Is this glossary editable',  
                id              : 'editradio',
     		columns		: 2, //display the radiobuttons in two columns  
      		items		: [  
           				{boxLabel: 'YES', name: 'editable', inputValue: '1'},  
           				{boxLabel: 'NO', name: 'editable', inputValue: '0'}  
      				]  
 });   

var fieldTypes = Ext.data.Record.create([
        { name: 'field_type_id', mapping: 'field_type_id',   type: 'int' },
        { name: 'field_type', mapping: 'field_type',  type: 'string' }
    ]);

var ftStore = new Ext.data.JsonStore({
        url		: base_url+'/contentmgt/getFieldType',
        root		: 'json_fields',
        idProperty      : 'field_type_id',
        fields		: fieldTypes
    });

 //creating a glossary form  

function formGloss(formtype) {
 
var count=0;
var fg = new Ext.ux.ColorField({fieldLabel: 'Foreground Color', id: 'fgcolor', value: '#000000', msgTarget: 'qtip'});
var bg = new Ext.ux.ColorField({fieldLabel: 'Background Color', id: 'bgcolor', value: '#FFFFFF', msgTarget: 'qtip'});

        /*JSON Store that gets the citation information for the glossary*/		
        var citation = Ext.data.Record.create([
              { name: 'citation_id', type: 'int' },
              { name: 'citation',    type: 'string' },
              { name: 'image_icon',  type: 'string' },
              { name: 'bgcolor',     type: 'string' },
              { name: 'fgcolor',     type: 'string' }
          ]);

        var citationStore = new Ext.data.JsonStore({
              url         : base_url+'/contentmgt/getCitation',
              baseParams  : {category_id : cCombo.getValue()},
              root        : 'json_citation',
              fields      : citation
          });


        /*JSON Store that gets the fields for a particular glossary*/		
        var Fields = Ext.data.Record.create([
              { name: 'field_label_id',  type: 'int' },
              { name: 'field_label',     type: 'string' },
              { name: 'field_type_id',      type: 'int' },
              { name: 'required',        type: 'string' },
              { name: 'editable',        type: 'string' }
          ]);

        var fieldStore = new Ext.data.JsonStore({
              url         : base_url+'/contentmgt/getDefFields',
              baseParams  : {category_id      : cCombo.getValue()},
              root        : 'json_fields',
              fields      : Fields
          });

var cite = {
                xtype         : 'fieldset',
                title         : 'Citation',
                collapsible   : true,
                autoHeight    : true,
                defaults      : {width : 230},
                items         : [{
                                  xtype            : 'htmleditor',
                                  fieldLabel       : 'Citation',
                                  name             : 'citation',
                                  id               : 'citation',
                                  width            : 580,
                                  enableSourceEdit : true,
                                  enableLinks      : true,
                                  enableFontSize   : true,
                                  enableColors     : false,
                                  enableAlignments : false,
                                  enableLists      : false,
                                  allowBlank       : true,
                                  },
                                  bg,fg]
};

var  glossForm = new Ext.form.FormPanel({
                id              : 'glossformid',
     		bodyStyle	: 'padding: 10px', //adding padding for the components of the form  
		items		: [{
                    			fieldLabel	: 'Glossary Name',
					xtype		: 'textfield',
		    			id		: 'glossname',
                    			name		: 'glossname',
                    			allowBlank	: false,
                                        width           : 400
                			},{
					xtype		: 'hidden',
					name		: 'category_id'
                                        },
				        cite,
				     {
				     	dynamic		: true,
					maxOccurs	: 5,
					xtype		: 'fieldset',
					title		: 'Defintion Fields',
					id		: 'fieldSetLabel',
					nameSpace	: 'defField',
					autoHeight	: true,
					width		: 350,
					listerners	: {
								'maxoccurs'	: {fn: function(fieldset) {
											Ext.Msg.alert('maxoccurs', 'Maximum number of fields reached');
											}
										  }
							  },
					items		: [
							  {
							  	fieldLabel 	: 'Field Label',
								xtype		: 'textfield',
								name		: 'fieldLabel',
								width		: 150
							 },{
							 
    								store		: ftStore,
                                                                name            : 'field_type',
    								fieldLabel	: 'Field Type',
    								displayField	: 'field_type',
    								valueField	: 'field_type_id',
                                                                hiddenName      : 'field_type',
    								xtype		: 'combo',
    								mode		: 'local',
    								typeAhead	: true,
    								triggerAction	: 'all',
    								emptyText	: 'Select a field type...',
    								forceSelection	: true,
    								selectOnFocus	: true,
								width		: 150
							    },{
							  	fieldLabel 	: 'Required',
								xtype		: 'xcheckbox',
								name		: 'required'
								},{
							  	fieldLabel 	: 'Non-Editable',
								xtype		: 'xcheckbox',
								name		: 'editable'
								},{
								xtype		: 'hidden',
								name		: 'field_label_id'
							    }
							 
					        	 ]}
					
					
           
     			          ],
 });  

  // end of file
 var url;
 var title;

 if(formtype == 'edit'){url = base_url+'/contentmgt/updateGloss';title = 'Edit ' +catStore.getById(cCombo.getValue()).get('category')+ ' Glossary';}
 if(formtype == 'add'){url = base_url+'/contentmgt/saveGloss'; title = 'New Glossary';}

//if(!glossformWin){
        glossformWin = formWindow(url,glossForm,title);
//}

if(formtype == 'add'){
        Ext.getCmp('glossformid').getForm().setValues({
             citation: '',
             glossname: '',
        })
        Ext.getCmp('fieldSetLabel').clones(0);
        Ext.getCmp('glossformid').setTitle('New JUNK');
}

if(formtype == 'edit'){

        Ext.getCmp('glossformid').setTitle('Old JUNK');
        fieldStore.load();

       fieldStore.on('load',function(){
              citationStore.load();
       });

var fieldData = [];
        citationStore.on('load',function(){		
               var citationRecord =  citationStore.getAt(0);
                Ext.getCmp('glossformid').getForm().setValues({
                        citation: citationRecord.get('citation'),
                        glossname: catStore.getById(cCombo.getValue()).get('category'),
                        editradio: '1',
                        bgcolor: citationRecord.get('bgcolor'),
                        fgcolor: citationRecord.get('fgcolor'),
                        category_id: cCombo.getValue()
                })

		fieldStore.each(function(record){
                    fieldData[count] = '{"fieldLabel":"' + record.data['field_label']+'"'+','+'"field_type":"' +record.data['field_type_id']+'","required":"' + record.data['required']+'","editable":"' + record.data['editable']+'","field_label_id":"' + record.data['field_label_id']+'"}';
                    count=count+1;
                 });

        Ext.getCmp('fieldSetLabel').clones(count);
        var test = Ext.getCmp('glossformid');
        var test2 = Ext.getCmp('fieldSetLabel');
        glossForm.populate(Ext.decode('['+fieldData+']'),'defField','fieldset');
                    
        test.doLayout();
         });
}
          glossformWin.show(this);
        
}


function formWindow(url,glossForm,title){ 

    var	glossformWin = new Ext.Window({
		width		: 800,
		height		: 400,
		minWidth	: 500,
		minHeight	: 300,
                id              : 'glossformwin',
    		autoScroll	: true,
		modal		: false,
		resizable	: true,
		maximizable	: true,
		closeAction	: "close",
		hideMode	: "offsets",
		constrainHeader	: true,
		items: [glossForm
		],
    		buttons		: [{text:'Save',
	        handler		: function(){ 
						glossForm.getForm().submit({
    										url		: url,
    										method		: 'POST',
    										success: function(f,a) {
													//var response = resp.responseText;
										
													Ext.Msg.alert('Status', 'Changes saved successfully.');
													catStore.load();
													glossformWin.close();
                                                                                                        gridStore.load({params:{cat:cCombo.getValue()}});
    										},
    										failure: function(f,a) {
													//var response = resp.responseText;
										
       													alert('ERROR saving data');
    										},
								
										//waitTitle	: 'Status',
										//waitMsg		: 'Saving Data'
									  })
					 }
			           },
				   {text		: 'Cancel',
    				    handler 		: function(){ glossformWin.close();} 
							  }
				   ] //buttons of the form    
	});

        Ext.getCmp('glossformwin').setTitle(title);
   return glossformWin;
}


function formInsert() {

    // private variables
   var htmlLabel;

   /*TinyMCE editor code.  This is call everytime a text field is required*/
   var editor =
                 {
                                fieldLabel: htmlLabel,
                                xtype: "tinymce",
                                tinymceSettings: {
                                        theme : "advanced",
                                        plugins: "safari,pagebreak,style,layer,table,advhr,advimage,advlink,emotions,iespell,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,noneditable,visualchars,nonbreaking,xhtmlxtras,template,fullscreen",
                                        theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect,fontsizeselect",
                                        theme_advanced_buttons2 : "cut,copy,paste,pasteword,|,bullist,numlist,|,undo,redo,|,link,unlink,anchor,image,media,|,preview,code,help,html,|,forecolor,backcolor,fullscreen",
                                        theme_advanced_toolbar_align : "top",
                                        theme_advanced_toolbar_location : "top",
                                        theme_advanced_statusbar_location : "bottom",
                                        theme_advanced_resizing : true,
                                        theme_advanced_source_editor_wrap : false,
                                        //theme_advanced_source_editor_width : 600,
                                        extended_valid_elements : "a[name|href|target|title|onclick],img[class|src|border=0|alt|title|hspace|vspace|width|height|align|onmouseover|onmouseout|name],hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style],iframe[src|width|height|name|align]",
                                        template_external_list_url : "example_template_list.js",
                                        external_image_list_url : base_url+'/static/js/image_list_'+cCombo.getValue()+'.js',
                                        media_external_list_url : base_url+'/static/js/video_list_'+cCombo.getValue()+'.js',
                                        entity_encoding : 'raw'
                                },
                                //value:
                };
        /*JSON Store that gets the word types*/		
        var wordTypes = Ext.data.Record.create([
              { name: 'word_type_id',  type: 'int' },
              { name: 'word_type',        type: 'string' }
          ]);

        var wordTypeStore = new Ext.data.JsonStore({
              url         : base_url+'/contentmgt/getWordTypes',
              root        : 'json_fields',
              fields      : wordTypes
          });


        /*JSON Store that gets the fields for a particular glossary*/		
        var Fields = Ext.data.Record.create([
              { name: 'field_label_id',  type: 'int' },
              { name: 'field_label',     type: 'string' },
              { name: 'field_type_id',   type: 'int' },
              { name: 'required',        type: 'int' }
          ]);

        var fieldStore = new Ext.data.JsonStore({
              url         : base_url+'/contentmgt/getDefFields',
              baseParams  : {category_id      : cCombo.getValue()},
              root        : 'json_fields',
              fields      : Fields
          });

    var defForm = new Ext.FormPanel({
                         id             : "insert_form",
                         frame          : true,
    			 labelWidth	: 75,
                         autoScroll     : true
     			});
	
       defForm.add({
               fieldLabel	: 'Term',
               name		: 'term',
               id		: 'word',
               xtype		: 'textfield',
               allowBlank       : false,
               vtype            : 'shit'
               //vtype            : 'shit'
       });

      /*Build the combo boxes for word types and languages*/
       defForm.add({
               fieldLabel	: 'Word Type',
               displayField	: 'word_type',
               valueField	: 'word_type_id',
               hiddenName       : 'word_type_id',
               id               : 'wordTypeCombo',
               mode		: 'local',
               xtype		: 'combo',
               typeAhead	: true,
               triggerAction	: 'all',
               emptyText	: 'Select a word type...',
               forceSelection	: true,
               selectOnFocus	: true,
               store            : wordTypeStore
       });

       defForm.add({
               fieldLabel	: 'Language',
               displayField	: 'language',
               valueField	: 'id',
               hiddenName       : 'language',
               id               : 'addLangCombo',
               mode		: 'local',
               xtype		: 'combo',
               typeAhead	: true,
               triggerAction	: 'all',
               emptyText	: 'Select a language...',
               forceSelection	: true,
               selectOnFocus	: true,
               store            : langStore
       });

        fieldStore.load(); 
        wordTypeStore.load({
		callback: function(){
			        Ext.getCmp('wordTypeCombo').setValue(1);
			  }
        }); 

        var wtCombo = Ext.getCmp("wordTypeCombo");
       

        /*JSON Store that gets the possible identifiers for a particular word
        ** type*/		
        var identifiers = Ext.data.Record.create([
              { name: 'word_type_identifier_id',  type: 'int' },
              { name: 'word_type_identifier',     type: 'string' }
          ]);

        var identStore = new Ext.data.JsonStore({
              url         : base_url+'/contentmgt/getIdentifierTypes',
              baseParams  : {word_type_id      : wtCombo.getValue()},
              root        : 'json_fields',
              fields      : identifiers
          });


        /*When a word type is select a text fields are added to the form to
        ** input the identifier*/
        wtCombo.on('select',function(){
               identStore.load();

        identStore.on('load',function(){		
		identStore.each(function(record){
               defForm.add({
                      fieldLabel	: record.data['word_type_identifier'],
                      name		: record.data['word_type_identifier'],
                      xtype		: 'textfield',
    		      width	        : 300
                });
                defForm.doLayout();

          	});//end each              
	  })//end of on load funtion
        });

        langStore.load({
		callback: function(){
			        Ext.getCmp('addLangCombo').setValue(25);
			  }
	});

        /* Build form based on glossary fields*/
        fieldStore.on('load',function(){		
	fieldStore.each(function(record){
        //alert(record.data['field_type_id']);
			switch (record.data['field_type_id']){
			case 1:
                                editor.fieldLabel = record.data['field_label'];
                                editor.width = '95%';
                                    editor.height = '100%';
				defForm.add(editor);
				break;
			case 2:
				defForm.add({
					fieldLabel	: record.data['field_label'],
					name		: record.data['field_label'],
					xtype		: 'textfield'
				});
				break;
			case 3:
                               // alert("Say WHAT!!!");
				defForm.add({
					fieldLabel	: record.data['field_label'],
					name		: record.data['field_label'],
                                        height          : 200,
					xtype		: 'textarea'
				});
				
				break;
			
			}//end switch

          	});//end each              
	  })//end of on load funtion

	var defInsertFormWin = new Ext.Window({
		title		: 'Add Term to Glossary',
                frame           : true,
		width		: 700,
		height		: 400,
		minWidth	: 100,
		minHeight	: 100,
                layout		: "fit",
    		autoScroll	: true,
		modal		: false,
		resizable	: true,
		maximizable	: true,
		closeAction	: "close",
		hideMode	: "offsets",
		constrainHeader	: true,
		items: [defForm
		],

    buttons: [ {text		: "Cancel",
    		handler 	: function(){ defInsertFormWin.close();}}, 
    	       {text		: "Save",
	        formBind	: true,
	        scope		: this,
		errorReader	: new Ext.data.JsonReader({
            				root: 'json_response'},
                			[{ name: 'success', type: 'bool'},
                 			 { name: 'message', type: 'string'}
                        		]),

	        handler		: function(){ 
                                                tinyMCE.triggerSave();
						defForm.getForm().submit({
    										//url		: 'http://bioinformatics.ualr.edu/TEST/contentmgt/saveContent',
    										url		: formURL,
    										method		: 'POST',
                                                                                params           : {category_id      : cCombo.getValue()},
    										success: function(f,a) {
													//var response = resp.responseText;
										
													Ext.Msg.alert('Status', 'Changes saved successfully.');
													defInsertFormWin.close();
                                                                                                        gridStore.load({params:{cat:cCombo.getValue()}});
    										},
    										failure: function(f,a) {
													//var response = resp.responseText;
										
       													alert('ERROR saving data');
    										},
								
										//waitTitle	: 'Status',
										//waitMsg		: 'Saving Data'
									  })
					 }
	       }] 
	});
	  defInsertFormWin.show(this);
};


function formEdit(word_id,word,word_type_id,word_type,cat_word_id) {

    // private variables
   var htmlLabel;
   var currentWordTypeId;
   var identField;
   var editor =
                 {
                                fieldLabel: htmlLabel,
                                xtype: "tinymce",
                                tinymceSettings: {
                                        theme : "advanced",
                                        plugins: "safari,pagebreak,style,layer,table,advhr,advimage,advlink,emotions,iespell,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,noneditable,visualchars,nonbreaking,xhtmlxtras,template,fullscreen",
                                        theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontselect,fontsizeselect",
                                        theme_advanced_buttons2 : "cut,copy,paste,pasteword,|,bullist,numlist,|,undo,redo,|,link,unlink,anchor,image,media,|,preview,code,help,html,|,forecolor,backcolor,fullscreen",
                                        theme_advanced_toolbar_align : "top",
                                        theme_advanced_toolbar_location : "top",
                                        theme_advanced_statusbar_location : "bottom",
                                        theme_advanced_resizing : true,
                                        theme_advanced_source_editor_wrap : false,
                                        //theme_advanced_source_editor_width : 600,
                                        extended_valid_elements : "a[name|href|target|title|onclick],img[class|src|border=0|alt|title|hspace|vspace|width|height|align|onmouseover|onmouseout|name],hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style],iframe[src|width|height|name|align]",
                                        template_external_list_url : "example_template_list.js",
                                        external_image_list_url : base_url+'/static/js/image_list_'+cCombo.getValue()+'.js',
                                        media_external_list_url : base_url+'/static/js/video_list_'+cCombo.getValue()+'.js',
                                        entity_encoding : 'raw'
                                },
                                //value:
                };
   /*var editor =
                 {
                                fieldLabel: htmlLabel,
                                xtype: "tinymce",
                                tinymceSettings: {
                                        theme : "advanced",
                                        plugins: "safari,pagebreak,style,layer,table,advhr,advimage,advlink,emotions,iespell,insertdatetime,preview,media,searchreplace,print,contextmenu,paste,directionality,noneditable,visualchars,nonbreaking,xhtmlxtras,template,fullscreen",
                                        theme_advanced_buttons1 : "bold,italic,underline,strikethrough,|,justifyleft,justifycenter,justifyright,justifyfull,|,styleselect,formatselect,fontsizeselect",
                                        theme_advanced_buttons2 : "cut,copy,paste,pasteword,|,bullist,numlist,|,undo,redo,|,link,unlink,anchor,image,media,|,preview,html,code,|,forecolor,backcolor,|,fullscreen",
                                        theme_advanced_toolbar_location : "top",
                                        theme_advanced_toolbar_align : "top",
                                        //theme_advanced_statusbar_location : "bottom",
                                        theme_advanced_resizing : true,
                                        extended_valid_elements : "a[name|href|target|title|onclick],img[class|src|border=0|alt|title|hspace|vspace|width|height|align|onmouseover|onmouseout|name],hr[class|width|size|noshade],font[face|size|color|style],span[class|align|style],iframe[src|width|height|name|align]",
                                        template_external_list_url : "example_template_list.js",
                                        external_image_list_url : base_url+'/static/js/image_list.js',
                                        media_external_list_url : base_url+'/static/js/video_list.js',
                                        entity_encoding : 'raw'

                                },
                                //value:
                }*/;
		
        /*JSON Store that gets the word types*/		
        var wordTypes = Ext.data.Record.create([
              { name: 'word_type_id',  type: 'int' },
              { name: 'word_type',        type: 'string' }
          ]);

        var wordTypeStore = new Ext.data.JsonStore({
              url         : base_url+'/contentmgt/getWordTypes',
              root        : 'json_fields',
              fields      : wordTypes
          });

   var defDataStore = new Ext.data.Store({
        proxy: new Ext.data.HttpProxy({
            url		: base_url+'/contentmgt/defData',
            method	: 'POST'
        }),
        baseParams:  { category_id     : cCombo.getValue(),
                       word_id         : word_id
                     },
                       
        reader: new Ext.data.JsonReader({
            root: 'json_data'},
                [
                 { name: 'definition_data_id', type: 'int'},
                 { name: 'definition',         type: 'string'},
                 { name: 'field_label_id',     type: 'int' },
                 { name: 'field_label',        type: 'string' },
                 { name: 'field_type_id',      type: 'int' },
                 { name: 'required',           type: 'int' },
                 { name: 'editable',           type: 'int' }
               ])
    });

        /*JSON Store that gets the actual identifiers for a particular word
        ** type*/		
        var wordIdentifiers = Ext.data.Record.create([
              { name: 'word_identifier_id',    type: 'int' },
              { name: 'identifier',            type: 'string' },
              { name: 'word_type_identifier',  type: 'string' }
          ]);

        var wordIdentStore = new Ext.data.JsonStore({
              url         : base_url+'/contentmgt/getIdentifiers',
              baseParams  : {category_word_id      : cat_word_id},
              root        : 'json_fields',
              fields      : wordIdentifiers,
              id          : 0
          });

         wordIdentStore.load();
    var editForm = new Ext.FormPanel({
                         id             : "edit_form",
    			 labelWidth	: 75,
                         frame          : true,
                         autoScroll     : true
     			});
	
       editForm.add({
               fieldLabel	: 'Term',
               xtype		: 'textfield',
               value            : word,
               id               : 'word',
               //vtype            : 'shit',
    	       width	        : 200
               //disabled         : true
               },{
	       xtype		: 'hidden',
               id		: 'word_id',
               value		: word_id
               },{
	       xtype		: 'hidden',
               id		: 'category_word_id',
               value		: cat_word_id
               }/*,{
	       xtype		: 'hidden',
               name		: 'category_id',
               id		: category_id
       }*/);

       wordIdentStore.on('load',function(){		
       if(word_type_id != 1){
              var identRecord =  wordIdentStore.getAt(0);
              //alert(identRecord.get('identifier'));
               editForm.add({
                     fieldLabel	        : identRecord.get('word_type_identifier'),
                     name		: identRecord.get('word_type_identifier'),
                     value              : identRecord.get('identifier'),
                     xtype		: 'textfield',
                     width	        : 300
              });
       }
       })
      /*Build the combo boxes for word types and languages*/
       editForm.add({
               fieldLabel	: 'Word Type',
               displayField	: 'word_type',
               valueField	: 'word_type_id',
               hiddenName       : 'word_type_id',
               id               : 'wordTypeCombo',
               mode		: 'local',
               xtype		: 'combo',
               typeAhead	: true,
               triggerAction	: 'all',
               emptyText	: 'Select a word type...',
               forceSelection	: true,
               selectOnFocus	: true,
               store            : wordTypeStore
       });

       editForm.add({
               fieldLabel	: 'Language',
               displayField	: 'language',
               valueField	: 'id',
               hiddenName       : 'language',
               id               : 'addLangCombo',
               mode		: 'local',
               xtype		: 'combo',
               typeAhead	: true,
               triggerAction	: 'all',
               emptyText	: 'Select a language...',
               forceSelection	: true,
               selectOnFocus	: true,
               store            : langStore
       });


        var wtCombo = Ext.getCmp("wordTypeCombo");
       
        /*JSON Store that gets the possible identifiers for a particular word
        ** type*/		
        var identifiers = Ext.data.Record.create([
              { name: 'word_type_identifier_id',  type: 'int' },
              { name: 'word_type_identifier',     type: 'string' }
          ]);

        var identStore = new Ext.data.JsonStore({
              url         : base_url+'/contentmgt/getIdentifierTypes',
              baseParams  : {word_type_id      : wtCombo.getValue()},
              root        : 'json_fields',
              fields      : identifiers
          });


        /*When a word type is select a text fields are added to the form to
        ** input the identifier*/
        wtCombo.on('select',function(){
               identStore.load();
        
        identStore.on('load',function(){		
	       identStore.each(function(record){
                //currentWordTypeId = record.data['identifier_id'];
               currentWordTypeId = wtCombo.getValue();
                
               var test = record.data['word_type_identifier'];
               identField = Ext.getCmp(test.toString());
               if(identField == undefined){
                      editForm.add({
                            fieldLabel	        : record.data['word_type_identifier'],
                            name		: record.data['word_type_identifier'],
                            id		        : record.data['word_type_identifier'],
                            xtype		: 'textfield',
                            width	        : 300
                      });
                }

                editForm.doLayout();

          	});//end each              
	  })//end of on load funtion
        });

        defDataStore.load(); 
        
        langStore.load({
		callback: function(){
			        Ext.getCmp('addLangCombo').setValue(25);
			  }
	});

        wordTypeStore.load({
		callback: function(){
                //alert(word_type_id);
                        Ext.getCmp('wordTypeCombo').setValue(word_type_id);
                
                }
        
        }); 
        defDataStore.on('load',function(){		
		defDataStore.each(function(record){

               editForm.add({
	       xtype		: 'hidden',
               name      	: 'definition_data_id',
               value		: record.data['definition_data_id']
               });

			switch (record.data['field_type_id']){
			case 1:
                                if(record.data['editable'] == 1){
                                    editor.fieldLabel = record.data['field_label'];
                                    editor.name  = record.data['field_label'];
                                    editor.value = record.data['definition'];
                                    editor.width = '95%';
                                    editor.height = '200';
                                    if(record.data['required'] == 1){ editor.allowBlank = false; }
                                    editForm.add(editor);
                                 }
                                 else{
                                    editForm.add({
                                         xtype        : 'panel',
					 fieldLabel   : record.data['field_label'],
                                         html         : record.data['definition'],
    		                         autoScroll   : true,
                                         width        : 550,
                                         height       : 50
                                   });
                                 }
				break;
			case 2:
				editForm.add({
					fieldLabel	: record.data['field_label'],
					name		: record.data['field_label'],
					xtype		: 'textfield'
				});
				break;
			case 3:
				editForm.add({
					fieldLabel	: record.data['field_label'],
					name		: record.data['field_label'],
					xtype		: 'textarea',
                                        height          : 200
				});
				
				break;
			
			}//end switch

          	});//end each              
	  })//end of on load funtion

	var editFormWin = new Ext.Window({
		title		: 'Edit Term',
                frame           : true,
		width		: 700,
                //bodyStyle       : 'padding: 5px',
		height		: 400,
		minWidth	: 100,
		minHeight	: 200,
		layout		: "fit",
    		autoScroll	: true,
		modal		: false,
		resizable	: true,
		maximizable	: true,
		closeAction	: "close",
		hideMode	: "offsets",
		constrainHeader	: true,
		items: [editForm
		],

    buttons: [ {text		: "Cancel",
    		handler 	: function(){ editFormWin.close();}}, 
    	       {text		: "Save",
	        formBind	: true,
	        scope		: this,
		errorReader	: new Ext.data.JsonReader({
            				root: 'json_response'},
                			[{ name: 'success', type: 'bool'},
                 			 { name: 'message', type: 'string'}
                        		]),

	        handler		: function(){ 
                                                tinyMCE.triggerSave();
						editForm.getForm().submit({
    										url		: base_url+'/contentmgt/updateTerm',
    										method		: 'POST',
                                                                                params           : {category_id      : cCombo.getValue()},
    										success: function(f,a) {
													//var response = resp.responseText;
										
													Ext.Msg.alert('Status', 'Changes saved successfully.');
													editFormWin.close();
		                                                                                        var detailP = Ext.getCmp('detail-panel');
		                                                                                        params = { cat_word_id: cat_word_id, word_id: word_id, word: word, cat: cCombo.getValue()};
		                                                                                        detailP.load({url:base_url+'/contentmgt/recordView', params:params});
    										},
    										failure: function(f,a) {
													//var response = resp.responseText;
										
       													alert('ERROR saving data');
    										},
								
										//waitTitle	: 'Status',
										//waitMsg		: 'Saving Data'
									  })
					 }
	       }] 
	});
	  editFormWin.show(this);
};
/*
Ext.apply(Ext.form.VTypes, {
        shit : function(val, field) {
        return false;
        },

        shitText : 'TEST STUFF'
});*/

Ext.apply(Ext.form.VTypes, {
        shit : function(val, field) {
                        var term = Ext.getCmp('word').getValue();
                        Ext.Ajax.request({
                                url: 'checkTermExists',
                                method: 'POST',
                                params: {'word' : term, 'category_id' : cCombo.getValue()},
                                success: function(o) {
                                        var valid = Ext.util.JSON.decode(o.responseText).success;
                                        //alert(valid);
                                        if (valid == 0) {
                                                settermvalidfalse();
                                                //return false;
                                        }
                                }
                });
                return true;
        },

        shitText : 'Term already in glossary. Please use edit funtion'
});

function settermvalidfalse() {
        Ext.apply(Ext.form.VTypes, {
                shit : function(val, field) {
                        var term = Ext.getCmp('word').getValue();
                        Ext.Ajax.request({
                                url: 'checkTermExists',
                                method: 'POST',
                                params: {'word' : term, 'category_id' : cCombo.getValue()},
                                success: function(o) {
                                        var valid = Ext.util.JSON.decode(o.responseText).success;
                                        if (valid == 0) {
                                                settermvalidfalse();
                                        } else {
                                                settermvalidtrue();
                                        }
                                }
                        });
                        return false;
                }
        });
}

function settermvalidtrue() {
        Ext.apply(Ext.form.VTypes, {
                shit : function(val, field) {
                        var term = Ext.getCmp('word').getValue();
                        Ext.Ajax.request({
                                url: 'checkTermExists',
                                method: 'POST',
                                params: {'word' : term, 'category_id' : cCombo.getValue()},
                                success: function(o) {
                                        var valid = Ext.util.JSON.decode(o.responseText).success;
                                        if (valid == 0) {
                                                settermvalidfalse();
                                        } else {
                                                settermvalidtrue();
                                        }
                                }
                        });
                        return true;
                }
        });
}

});
