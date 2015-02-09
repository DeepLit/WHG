Ext.apply(Ext.form.VTypes, {
        uniqueterm : function(val, field) {
                var term = Ext.getCmp('add_term_id').getValue();
                Ext.Ajax.request({
                        url: 'contentmgt/checkTermeExists',
                        method: 'POST',
                        params: {'word' : term, 'category_id' : cCombo.getValue()},
                        success: function(o) {
                                if (o.responseText == 0) {
                                        settermvalidfalse();
                                }
                        }
                });
                return true;
        },

        uniqueutermText : 'Term already in glossary. Please use edit funtion'
});

function settermvalidfalse() {
        Ext.apply(Ext.form.VTypes, {
                uniqueusername : function(val, field) {
                        var username = Ext.getCmp('add_term_id').getValue();
                        Ext.Ajax.request({
                                url: 'contentmgt/checkTermeExists',
                                method: 'POST',
                                params: {'word' : term, 'category_id' : cCombo.getValue()},
                                success: function(o) {
                                        if (o.responseText == 0) {
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
                uniqueusername : function(val, field) {
                        var username = Ext.getCmp('add_term_id').getValue();
                        Ext.Ajax.request({
                                url: 'contentmgt/checkTermeExists',
                                method: 'POST',
                                params: {'word' : term, 'category_id' : cCombo.getValue()},
                                success: function(o) {
                                        if (o.responseText == 0) {
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

