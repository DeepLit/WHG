 /* global Ext */

 /**
    jit.js 1.2
  ************************************************************************************

   $JIT [Dynamic Resource loader (basex 3.1+ support required)]

  ************************************************************************************
  * Author: Doug Hendricks. doug[always-At]theactivegroup.com
  * Copyright 2007-2008, Active Group, Inc.  All rights reserved.
  ************************************************************************************

  License: ext-basex and $JIT are licensed under the terms of : GNU Open Source GPL 3.0 license:

  Commercial use is prohibited without contacting licensing[at]theactivegroup.com.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see < http://www.gnu.org/licenses/gpl.html>.

   Donations are welcomed: http://donate.theactivegroup.com

  */
  

   if(typeof Ext == undefined || !Ext.hasBasex)
      {throw "Ext and ext-basex 3.1 or higher required.";}

  (function(){
    
    /**
     * private -- <script and link> tag support
     */
    var A = Ext.lib.Ajax,
        StopIter = "StopIteration",
        defined = function(test){return typeof test !== 'undefined';},
        emptyFn = function(){};
    
    
    /**
     * @class Ext.ux.ModuleManager
     * @version 1.2
     * ***********************************************************************************
     * @author Doug Hendricks. doug[always-At]theactivegroup.com 
     * @copyright 2007-2008, Active Group, Inc. All rights reserved.
     * ***********************************************************************************
     * @donate <a target="tag_donate" href="http://donate.theactivegroup.com"><img border="0" src="http://www.paypal.com/en_US/i/btn/x-click-butcc-donate.gif" border="0" alt="Make a donation to support ongoing development"></a>
     * @license <a href="http://www.gnu.org/licenses/gpl.html">GPL 3.0</a>
     *
     * Commercial Use is prohibited without contacting
     * licensing[at]theactivegroup.com.
     *
     * This program is free software: you can redistribute it and/or modify
     * it under the terms of the GNU General Public License as published by
     * the Free Software Foundation, either version 3 of the License, or any
     * later version.
     *
     * This program is distributed in the hope that it will be useful, but
     * WITHOUT ANY WARRANTY; without even the implied warranty of
     * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
     * General Public License for more details.
     *
     * You should have received a copy of the GNU General Public License
     * along with this program. If not, see <
     * http://www.gnu.org/licenses/gpl.html>.
     *
     * Donations are welcomed: http://donate.theactivegroup.com
     *
     * @constructor - creates a new instance of ux.ModuleManager 
     * @methodOf Ext.ux.ModuleManager @param {Object} config
     * @example
     * Sample Usage:
     *
     * YourApp.CodeLoader = new
     * Ext.ux.ModuleManager({modulePath:yourBasePath });
     * YourApp.CodeLoader.on({ 'beforeload':function(manager, module,
     * response){
     *
     * //return false to prevent the script from being executed. return
     * module.extension == 'js';
     *  } ,scope:YourApp.CodeLoader });
     *
     * //Create a useful 'syntax' for your App.
     *
     * YourApp.needs =
     * YourApp.CodeLoader.load.createDelegate(YourApp.CodeLoader);
     * YourApp.provide =
     * YourApp.CodeLoader.provides.createDelegate(YourApp.CodeLoader);
     *
     * YourApp.needs('ext/layouts','js/dragdrop','js/customgrid','style/custom.css');
     *
     *
     * Configuration options
     */
    Ext.namespace('Ext.ux');
    Ext.ux.ModuleManager = function(config) {

        Ext.apply(this, config || {}, {
                    modulePath : function() { // based on current page
                        var d = location.href.indexOf('\/') != -1
                                ? '\/'
                                : '\\';
                        var u = location.href.split(d);
                        u.pop(); // this page
                        return u.join(d) + d;
                    }()
                });

        this.addEvents({
            /**
             * @event loadexception Fires when any exception is
             *        raised returning false prevents any subsequent
             *        pending module load requests
             * @param {Ext.ux.ModuleManager}
             *            this
             * @param {String}
             *            module -- the module object
             * @param {Object}
             *            error -- An error object containing:
             *            httpStatus, httpStatusText, error object
             */
            "loadexception" : true,

            /**
             * @event alreadyloaded Fires when the ModuleManager
             *        determines that the requested module has
             *        already been loaded
             * @param {Ext.ux.ModuleManager}
             *            this
             * @param {String}
             *            module -- the module object
             */
            "alreadyloaded" : true,

            /**
             * @event load Fires when the retrieved content has been
             *        successfully loaded
             * @param {Ext.ux.ModuleManager}
             *            this
             * @param {String}
             *            module -- the module name
             * @param {Object}
             *            response -- the Ajax response object
             * @param {String}
             *            contents -- the raw text content retrieved
             * @param {Boolean}
             *            executed -- true if the resource was
             *            executed into the target context.
             */
            "load" : true,

            /**
             * @event beforeload Fires when the request has
             *        successfully completed and just prior to eval
             *        returning false prevents the content (of this
             *        module) from being loaded (eval'ed)
             * @param {Ext.ux.ModuleManager}
             *            this
             * @param {String}
             *            module -- the module name
             * @param {Object}
             *            response - the Ajax response object
             * @param {String}
             *            contents -- the raw text content retrieved
             */
            "beforeload" : true,

            /**
             * @event complete Fires when all module load request
             *        have completed (successfully or not)
             * @param {Ext.ux.ModuleManager}
             *            this
             * @param {Boolen}
             *            success
             * @param {Array}
             *            loaded -- the modules now available as a
             *            result of (or previously -- already
             *            loaded) the last load operation.
             * @param {Array}
             *            executed -- modules that were executed
             *            (evaled) as a result of (or previously
             *            executed) the last load operation.
             */
            "complete" : true,

            /**
             * @event timeout Fires when module {@link #load} or
             *        {@link #onAvailable} requests have timed out.
             * @param {Ext.ux.ModuleManager}
             *            this
             */
            "timeout" : true
        });
        Ext.ux.ModuleManager.superclass.constructor.call(this);

    };

    /** @private */
    var gather = function(method, url, callbacks, data, options) {

        var tag, attribs;
        callbacks || (callbacks = {});
        
        if (method == 'SCRIPT') {
            tag  = method;
            attribs = {
                 type : "text/javascript",
                  src : url
             };
            
        } else if (method == 'LINK') {
            tag = method;
            attribs = {
                    rel : "stylesheet",
                    type : "text/css",
                    href : url
                    };   
        }
        return tag ? A.monitoredNode(tag, attribs, callbacks, options.target || window) :
                 A.request.apply(A,arguments);
     };
     
    // normalize a resource to name-component hash
    /** @private */
    var modulate = function(moduleName, options) {
        if (!moduleName)
            return null;
        options || (options = {});
        var mname = String(moduleName.name || moduleName),
            name = mname.trim().split('\/').last(),
            fname = options ? (name.indexOf('.') !== -1 ? mname : mname + '.js') : '',
            path = options.path || '';

        var mod = Ext.apply({
                    name : name,
                    fullName : moduleName.name ? moduleName.name : fname,
                    extension : !moduleName.name ? fname.split('.').last()
                            .trim().toLowerCase() : '',
                    path : path
                }, options);

        mod.url = options.url || (path + fname);
        return mod;
    };

    Ext.extend(Ext.ux.ModuleManager, Ext.util.Observable, {
        /**
         * @cfg {Boolean} disableCaching True to ensure the the browser's
         *      cache is bypassed when retrieving resources.
         */
        disableCaching : false,

        /** @private */

        modules : {},

        /**
         * @cfg {String} method The default request method used to retrieve
         *      resources. This method may also changed in-line during a
         *      {@link #load) operation. Supported methods:
         *      <ul>
         *      <li>DOM - Retrieve the resource by <SCRIPT/LINK> tag
         *      insertion</li>
         *      <li>GET Retrieve the resource by Ajax Request</li>
         *      <li>POST</li>
         *      <li>PUT</li>
         *      </ul>
         */

        method : 'GET',

        /**
         * @cfg {Boolean} noExecute Permits retrieval of a resource without
         *      script execution of the results. This option may also be
         *      changed in-line during a {@link #load) operation.
         */

        noExecute : false,
        /**
         * @cfg {Boolean} asynchronous Sets the default behaviour for AJAX
         *      requests onlu This option may also be changed in-line
         *      (async: true) during a {@link #load) operation.
         */

        asynchronous : true,

        /**
         * @cfg {Boolean} cacheResponses True, saves any content received in
         *      a content object with the following structure:
         *
         * This option may also be changed in-line during a
         * {@link #load) operation.
         */

        cacheResponses : false,

        /**
         * @cfg {Integer} default onAvailable/load method timeout value in
         *      milliseconds
         */

        timeout : 30000,

        /**
         * @cfg {Boolean} True retains the resulting content within each
         *      module object for debugging.
         */

        debug : false,

        /** @private */
        loadStack : new Array(),

        loaded : function(name) {
            var module;
            return (module = this.getModule(name))? module.loaded === true : false;
        },


        getModule : function(name) {
            name && (name = name.name ? name.name : modulate(name, false).name);
            return name ? this.modules[name] : null;
        },
        /*
         * A mechanism for modules to identify their presence when loaded
         * via conventional <script> tags
         * @param {String} module names(s)
         * Usage: <pre><code>Ext.Loader.provides('moduleA', 'moduleB');</code></pre>
         */

        createModule : function(name, extras) {
            var mod, existing;
            mod = (existing = this.getModule(name)) || modulate(name, extras);

            return existing ||
                (this.modules[mod.name] = Ext.apply({
                            executed : false,
                            contentType : '',
                            content : null,
                            loaded : false,
                            pending : false
                        },mod));


            if (!mod) {
                var m = modulate(name, extras);
                mod = this.modules[m.name] = Ext.apply({
                            executed : false,
                            contentType : '',
                            content : null,
                            loaded : false,
                            pending : false
                        }, m);
            }

            return mod;
        },

        /**
         * Assert loaded status of module name arguments and invoke
         * callback(s) when all are available
         *
         * @param {Array/String}
         *            modules A list of module names to monitor
         * @param {Function}
         *            callback The callback function called when all named
         *            resources are available
         * @param (Object)
         *            scope The execution scope of the callback
         * @param {integer}
         *            timeout The timeout value in milliseconds.
         */

        onAvailable : function(modules, callback, scope, timeout, options) {

            if (arguments.length < 2) {
                return false;
            }

            var MM = this;
            var block = {

                modules : new Array().concat(modules),
                poll : function() {
                    if (!this.polling)return;

                    var cb = callback;
                    var depends = (window.$JIT ? $JIT.depends : null) || {};

                    var assert = this.modules.every( function(arg, index, args) {
                        
                           var modName = arg.replace('@',''),virtual = false, test=true;
                              
                           if(depends[modName] && 
                             ((virtual = depends[modName].virtual || false) || 
                               (Ext.isArray(depends[modName].depends && 
                                  !!depends[modName].length
                                )))){
                               test = depends[modName].depends.every(arguments.callee);
                               test = virtual ? test && ((MM.getModule(modName)||{}).loaded = true): test;
                           }
                           return test && (virtual || MM.loaded(modName) === true);
                    });

                    if (!assert && this.polling && !this.aborted) {
                        this.poll.defer(50, this);
                        return;
                    }

                    this.stop();
                    Ext.isFunction(cb) && cb.call(scope, assert);

                },

                polling : false,

                abort : function() {
                    this.aborted = true;
                    this.stop();
                },

                stop : function() {
                    this.polling = false;
                    this.timer && clearTimeout(this.timer);
                    this.timer = null;
                },

                timer : null,

                timeout : parseInt(timeout || MM.timeout, 10) || 10000,

                onTimeout : function() {
                    this.abort();
                    MM.fireEvent('timeout', MM, this.modules);
                },

                retry : function(timeout) {

                    this.stop();
                    this.polling = true;
                    this.aborted = false;
                    this.timer = this.onTimeout.defer(this.timeout, this);
                    this.poll();
                    return this;
                }
            };
            return block.retry();
        },

        /**
         * A mechanism for modules to identify their presence when loaded
         * via conventional <script> tags or nested on other scripts.
         *
         * @param {String}
         *            module names(s) Usage:
         *
         * <pre><code>
         * Ext.Loader.provides('moduleA', 'moduleB');
         * </code></pre>
         */

        provides : function() {
            forEach(arguments, function(module) {

                        var moduleObj = this.createModule(module, false);
                        moduleObj.loaded || //already loaded ?
                            Ext.apply(moduleObj, {
                                    executed : moduleObj.extension === 'js',
                                    contentType : '',
                                    content : null,
                                    loaded : true,
                                    pending : false
                                });
                    }, this);

        },
        /**
         * load external resources in dependency order alternate load
         * syntax:
         *
         * <pre><code>
         *           load( 'moduleA', 'path/moduleB'  );
         *           load( {module:['modA','path/modB'], callback:cbFn, method:'DOM', queue:'fast', ... });
         *           load( {async:false, listeners: {complete: onCompleteFn, loadexception: loadExFn }}, 'moduleA', inlineFn, {async:true}, 'moduleB', inlineFn, .... );
         *
         * </code></pre>
         *
         * @name load
         * @methodOf Ext.ux.ModuleManager
         * @param {Mixed}
         *            args One or more module definitions, inline functions
         *            to be execute in sequential order
         */


        load : function(modList) {

            try {
                var task = new Task(this, Ext.isArray(modList) ? modList : Array.slice(arguments, 0));
                task.start();

            } catch (ex) {
                
                if (ex != StopIter) {

                    if (task) {
                        task.lastError = ex;
                        task.active = false;
                    }

                    this.fireEvent('loadexception', this, task
                                    ? task.currentModule
                                    : null, this.lastError = ex);
                }
            }

            return task;
        },


        globalEval : function(data, scope, context) {
            scope || (scope = window);
            data = String(data || "").trim();
            if (data.length === 0) {return false;}
            try {
                if (scope.execScript) {
                    // window.execScript in IE fails when scripts include
                    // HTML comment tag.
                    scope.execScript(data.replace(/^<!--/, "").replace(/-->$/, ""));

                } else {
                    // context (target namespace) is only support on Gecko.
                    eval.call(scope, data, context || null);
                }
                return true;
            } catch (ex) {
                return ex;
            }

        },
        styleAdjust : null,


        applyStyle : function(module, styleRules, target) {
            var rules;
            if (module = this.getModule(module)) {
                // All css is injected into document's head section
                var doc = (target || window).document;
                var ct = (styleRules
                        || (module.content ? module.content.text : '') || '')
                        + '';
                var head;
                if (doc && !!ct.length
                        && (head = doc.getElementsByTagName("head")[0])) {

                    if (module.element) {
                        this.removeModuleElement(module);
                    }
                    if (this.styleAdjust && this.styleAdjust.pattern) {
                        // adjust CSS (eg. urls (images etc))
                        ct = ct.replace(this.styleAdjust.pattern,
                                this.styleAdjust.replacement || '');
                    }

                    rules = doc.createElement("style");
                    module.element = Ext.get(rules);
                    A._domRefs.push(module.element);
                    rules.setAttribute("type", "text/css");
                    if (Ext.isIE) {
                        head.appendChild(rules);
                        rules.styleSheet.cssText = ct;
                    } else {
                        try {
                            rules.appendChild(doc.createTextNode(ct));
                        } catch (e) {
                            rules.cssText = ct;
                        }
                        head.appendChild(rules);
                    }
                }
            }
            return rules; // the style element created
        },

        /**
         * Remove a style element
         *
         * @name removeStyle
         * @param {Mixed}
         *            module A Ext.ux.ModuleManager.module or dom Node
         * @return {Ext.Element} the element removed.
         */

        removeStyle : function(module) {
            return this.removeModuleElement(module);
        },

        /** @private */
        // Remove an associated module.element from the DOM

        removeModuleElement : function(module) {
            var el;
            if (module = this.getModule(module)) {
                if (el = module.element) {
                    el.dom ? el.removeAllListeners().remove(true) : Ext.removeNode(el);
                }
                module.element = el = null;
            }

        },
        destroy : function(){
            forEach(this.modules,
               function(module, name){
                this.removeModuleElement(name);
                delete this.modules[name];
               }, this);
        }
    });

    var Task = Ext.ux.ModuleManager.Task = function(MM, modules) {

        Ext.apply(this, {
                    result : true,
                    active : false,
                    options : null,
                    executed : new Array(),
                    loaded : new Array(),
                    params : null,
                    data : null,
                    oav : null,
                    unlisteners : new Array(),
                    MM : MM,
                    id : Ext.id(null, 'mm-task-'),
                    defOptions : {
                        async : MM.asynchronous,
                        headers : MM.headers || false,
                        modulePath : MM.modulePath,
                        forced : false,
                        cacheResponses : MM.cacheResponses,
                        method : (MM.noExecute || MM.cacheResponses
                                ? 'GET'
                                : MM.method || 'GET').toUpperCase(),
                        noExecute : MM.noExecute || false,
                        disableCaching : MM.disableCaching,
                        timeout : MM.timeout,
                        callback : null,
                        scope : null,
                        params : null
                    }
                });

        this.prepare(modules);

    };

    Ext.apply(Task.prototype, {
        /**
         *  @private
         *
         */

        start : function() {
            this.active = true;
            this.nextModule();
            if (this.options.async) {
                this.oav = this.MM.onAvailable.call(this.MM,
                        this.onAvailableList, this.onComplete, this,
                        this.options.timeout, this.options);
            } else {
                this.onComplete(this.result);
            }

        },

        /**
         *  @private
         *
         */
        doCallBacks : function(options, success, currModule, args) {
            var cb, C;
            
            if (C = currModule) {
                var res = this.MM.fireEvent.apply(this.MM, [
                                (success ? 'load' : 'loadexception'),
                                this.MM, C ].concat(args || []));
                
                success || (this.active = (res !== false));

                // Notify other pending async listeners
                if (this.active && Ext.isArray(C.notify)) {
                    forEach(C.notify, 
                        function(chain, index, chains) {
                                if (chain) {
                                    chain.nextModule();
                                    chains[index] = null;
                                }
                            });
                    C.notify = [];
                }
               
                //script Tag cleanup
                if(C.element && !options.debug && C.extension == "js" && options.method == 'DOM'){
                         
                    C.element.removeAllListeners();  
	                var d = C.element.dom;
                    if(Ext.isIE){
                        //Script Tags are re-usable in IE
                        A.SCRIPTTAG_POOL.push(C.element);
                    }else{
                        Ext.Element.uncache(C.element);
                        C.element.remove();
                        //Other Browsers will not GBG-collect these tags, so help them along
                        if(d){
                            for(var prop in d) {delete d[prop];}
                        }
                    }
                    d = null;
                    delete C.element;
                }
                
            }
        },

        /**
         *  @private
         *
         */
        success : function(response , ev, target ) {
            
            var module = response.argument.module.module, 
                opt = response.argument.module, 
                executable = (!opt.proxied && module.extension == "js" && !opt.noExecute && opt.method !== 'DOM'), 
                cbArgs = null;
            
            module = this.MM.getModule(module.name);
            this.currentModule = module.name;

            if (!module.loaded) {
                try {

                    if (this.MM.fireEvent('beforeload', this.MM, module,
                            response, response.responseText) !== false) {

                        Ext.apply(module, {
                            loaded : true,
                            pending : false,
                            contentType : response.contentType || (target && Ext.fly(target) ? Ext.fly(target).getAttributeNS(null,'type'):''),
                            content : opt.cacheResponses
                                    || module.extension == "css" ? {
                                text : response.responseText || null,
                                XML : response.responseXML || null,
                                JSON : response.responseJSON || null,
                                parts : response.parts
                           
                            } : null
                        });

                        this.loaded.push(module);
                        var exception = executable
                                && (!module.executed || opt.forced)
                                ? this.MM.globalEval(response.responseText, opt.target)
                                : true;
                        if (exception === true) {
                            if (executable) {
                                module.executed = true;
                                this.executed.push(module);
                            }
                            cbArgs = [response, response.responseText, module.executed];
                        } else {
                            // coerce to actual module URL
                            throw Ext.applyIf({
                                        fileName : module.url,
                                        lineNumber : exception.lineNumber || 0
                                    }, exception);
                        }
                    }

                } catch (exl) {
                    cbArgs = [{
                                error : (this.lastError = exl),
                                httpStatus : response.status,
                                httpStatusText : response.statusText
                            }];

                    this.result = false;
                }

                this.doCallBacks(opt, this.result, module, cbArgs);
            } else {
                opt.async && this.nextModule();
            }

        },

        /**
         *  @private
         *
         */

        failure : function(response) {
           
            var module = response.argument.module.module, opt = response.argument.module;
            module.contentType = response.contentType || ''
            this.currentModule = module.name;
            this.result = module.pending = false;

            this.doCallBacks(opt, this.result, module, [{
                        error : (this.lastError = response.fullStatus.error),
                        httpStatus : response.status,
                        httpStatusText : response.statusText
                    }]);
        },

        /**
         *  @private
         *
         */

        nextModule : function() {
            var module, transport, executable, options, url;

            while (this.active && (module = this.workList.shift())) {

                // inline callbacks
                if (Ext.isFunction(module)) {
                    module.apply(this, [this.result, null, this.loaded]);
                    continue;
                }

                // setup possible single-use listeners for the current
                // request chain
                if (module.listeners) {
                    this.unlisteners.push(module.listeners);
                    this.MM.on(module.listeners);
                    delete module.listeners;

                }

                var params = null, data = null, moduleObj;
                options = module;
                if (params = module.params) {
                    Ext.isFunction(params)&& (params = params.call(options.scope || window,options));
                    Ext.isObject(params) && (params = Ext.urlEncode(params));
                    module.params = data = params; // setup for possible post
                }

                if (moduleObj = this.MM.createModule(module.module, {
                            path : options.modulePath
                        })) {
                    url = moduleObj.url;

                    executable = (!options.proxied
                            && moduleObj.extension == "js" && !options.noExecute);

                    if ((!moduleObj.loaded) || options.forced) {

                        if (!moduleObj.pending) {
                            moduleObj.pending = true;
                            if (/get|script|dom|link/i.test(options.method)) {
                                url += (params ? '?' + params : '');
                                if (options.disableCaching == true) {
                                    url += (params ? '&' : '?') + '_dc='
                                            + (new Date().getTime());
                                }
                                data = null;
                            }

                            options.async = options.method === 'DOM'
                                    ? true
                                    : options.async;

                            transport = gather(
                                        options.method == 'DOM'
                                            ? (moduleObj.extension == 'css'
                                                    ? 'LINK'
                                                    : 'SCRIPT')
                                            : options.method,
                                        url, 
                                        {
	                                        success : this.success,
	                                        failure : this.failure,
	                                        scope : this,
	                                        argument : {
	                                            module : module
	                                        }
                                        },
                                        data,
                                        options);
                                        
                            Ext.apply( moduleObj,{
                                element : options.method == 'DOM' ? transport : null,
                                method : options.method || this.method,
                                options : options
                            });
                        }

                        if (options.async) { break; }

                    } else {
                        this.active = this.MM.fireEvent('alreadyloaded', this.MM, moduleObj) !== false;
                        executable && this.executed.push(moduleObj);
                        this.loaded.push(moduleObj);
                    }

                } // if moduleObj
            } // oe while(module)

            if (this.active && module && module.async && moduleObj) {
                moduleObj.notify || (moduleObj.notify = new Array());
                moduleObj.notify.push(this);
            }

        },

        /**
         *  @private
         * Normalize requested modules and options into a sequential series
         * of load requests and inline callbacks
         */

        prepare : function(modules) {

            var onAvailableList = new Array(),
                workList = new Array(),
                options = this.defOptions,
                mtype,
                MM = this.MM;

            var adds = new Array();

            var expand = function(mods) {

                mods = new Array().concat(mods);
                var adds = new Array();
                forEach(mods, function(module) {

                    if (!module)return;
                    var m;

                    mtype = typeof(module);
                    switch (mtype) {
                        case 'string' : // a named resource

                            m = MM.createModule(module, {
                                        path : options.modulePath,
                                        url : module.url || null
                                    });
                            if (!m.loaded) {
                                module = Ext.applyIf({
                                            name : m.name,
                                            module : m,
                                            callback : null
                                        }, options);
                                delete options.listeners;
                                workList.push(module);
                                adds.push(module);
                            }

                            onAvailableList.push(m.name);
                            break;
                        case 'object' : // or array of modules
                            // coerce to array to support this notation:
                            // {module:'name' or
                            // {module:['name1','name2'],callback:cbFn,...
                            // so that callback is only called when the last
                            // in the implied list is loaded.

                            if (m = (module.modules || module.module)) {
                                adds = expand(m);
                                delete module.module;
                                delete module.modules;
                            }

                            if (module.proxied) {
                                module.method = 'GET';
                                module.cacheResponses = module.async = true;
                            }

                            if (Ext.isArray(module)) {
                                adds = expand(module);
                            } else {
                                var mod = module;
                                if (module.name) { // for notation
                                                    // {name:'something',
                                                    // url:'assets/something'}

                                    m = MM.createModule(module, {
                                                path : options.modulePath,
                                                url : mod.url || null
                                            });
                                    delete mod.url;
                                    Ext.apply(options, mod);
                                    if (!m.loaded) {
                                        mod = Ext.applyIf({
                                                    name : m.name,
                                                    module : m,
                                                    callback : null
                                                }, options);
                                        delete options.listeners;
                                        workList.push(mod);
                                        adds.push(mod);
                                    }

                                    onAvailableList.push(m.name);

                                } else {
                                    Ext.apply(options, mod);
                                }

                            }
                            break;
                        case 'function' :
                            workList.push(module);
                        default :
                    }

                });

                return adds;
            };

            expand(modules);
            this.options = options;
            this.workList = workList.flatten().compact();
            this.onAvailableList = onAvailableList.flatten().unique();
        },

        /**
         * @private
         */
        onComplete : function(loaded) { // called with scope of last module
                                        // in chain
            var cb;

            if (loaded) {

                if (cb = this.options.callback) {
                    cb.apply(this.options.scope || this, [this.result,
                                    this.loaded, this.executed]);
                }
                this.MM.fireEvent('complete', this.MM, this.result,
                        this.loaded, this.executed);
            }

            // cleanup single-use listeners from the previous request chain
            if (this.unlisteners) {
                forEach(this.unlisteners, function(block) {
                    forEach(block, function(listener, name,
                                    listeners) {
                                var fn = listener.fn || listener;
                                var scope = listener.scope
                                        || listeners.scope
                                        || this.MM;
                                var ev = listener.name || name;
                                this.MM.removeListener(ev, fn,
                                        scope);
                            }, this);
                }, this);
            }
            this.active = false;
        }
    });

    //Enable local file access for IE
    Ext.lib.Ajax.forceActiveX = (Ext.isIE7 && document.location.protocol == 'file:');

    var L = Ext.Loader = new Ext.ux.ModuleManager({

        modulePath : '',  //adjust for site root
        method : 'DOM',
        depends  : {},  // Ext dependency table
        disableCaching : true,

        getMap:function(module){

            var result = new Array(), mods= new Array().concat(module.module || module);
            var options = Ext.isObject(module) ? module : {module:module};

            forEach(mods,
              function(mod){
                var c=arguments.callee;
                var moduleName = Ext.isObject(mod)? mod.module || null : mod;
                var map = moduleName ? this.depends[moduleName.replace("@","")]||false : false;

                map = Ext.apply({path:'',depends:false}, map);

                forEach(map.depends||new Array() ,
                    function(module,index,dep){
                        //chain dependencies
                        module.substr(0,1)=="@" ?
                            c.call(this, module ):
                              (result = result.concat(module));

                    },this);

                if(moduleName && !(map.none || map.virtual)){result = result.concat((map.path||'') + moduleName.replace("@","")); }
            },this);

            return Ext.applyIf({module:!!result.length ? result.unique() :null},options);

        },

        styleAdjust  : {pattern:/url\(\s*\.\.\//ig, replacement:'url(resources/'}

    });


    /**
     * @class $JIT
     * @version 1.4
     * @author Doug Hendricks. doug[always-At]theactivegroup.com 
     * @copyright 2007-2009, Active Group, Inc. All rights reserved.
     * @donate <a target="tag_donate" href="http://donate.theactivegroup.com"><img border="0" src="http://www.paypal.com/en_US/i/btn/x-click-butcc-donate.gif" border="0" alt="Make a donation to support ongoing development"></a>
     * @license <a href="http://www.gnu.org/licenses/gpl.html">GPL 3.0</a>
     * @singleton
     * @static
     * @description Load external resources in dependency order by any transport supported by the ext-basex adapter.
     * <p>For an online demonstration of $JIT in action, <a href="http://demos.theactivegroup.com/?demo=basex&script=multipart" target="tagdemo">click here.</a>
     * @example
     * Flexible load syntaxes:
     *
     * $JIT( 'moduleA', 'path/moduleB', function(loaded, modules){
     *     if(loaded){
     *        var t = new justLoadedClass();
     *       }
     *  });
     *  
     * //or, A long running request can be evaluated asynchronously later:
     * $JIT.onAvailable (['moduleA', 'uxpackage'], function(loaded){
     *     if(loaded){
     *        var t = new justLoadedClass();
     *       }
     * });
     * 
     * $JIT( {module:['modA','path/modB'],
     *      callback: cbFn,
     *      scope: null,  //callback scope
     *      modulePath : 'assets/scripts/', //(optional) root for request chain
     *      disableCaching : true, //prevent browser caching of modules
     *      cacheResponses : false, //true to cache the text content of the module
     *      async : false // synchronous request 
     *      method:'DOM', //others: 'GET', 'POST', 'DOM' writes to script tags for debugging
     *      proxied : false //if true or config, uses the JSONP transport
     *      xdomain : false,  //(optional) for modern browsers supporting cross-domain requests  
     *      queue:{name:'fast', priority: 2}, //(optional) Queuing support 
     *      ... });
     *
     * //Inline callbacks
     * $JIT( {
     *      async    :false, //start out synchronous mode
     *      listeners: {
     *          complete: onCompleteFn,
     *          loadexception: loadExFn
     *        }
     *      },
     *      'moduleA',
     *      progressFn,
     *      {async:true}, //switch to asynchronous mode
     *      'moduleB',
     *      progressFn, .... );
     *
     * //Define logical dependencies: (Adjust to suite your site layout.)
     *  
     *  var ux= 'ux/';
     *  Ext.apply( $JIT.depends , {
     *  // JS source file | source location | Dependencies (in required load order)
     *   'uxvismode'   :   {path: ux }
     *  ,'uxmedia'     :   {path: ux ,          depends: [ '@uxvismode']}
     *  ,'uxflash'     :   {path: ux ,          depends: [ '@uxmedia'] }
     *  ,'uxchart'     :   {path: ux ,          depends: [ '@uxflash'] }
     *  ,'uxfusion'    :   {path: ux ,          depends: [ '@uxchart'] }
     *  ,'uxofc'       :   {path: ux ,          depends: [ '@uxchart'] }
     *  ,'uxamchart'   :   {path: ux ,          depends: [ '@uxchart'] }
     *  ,'uxflex'      :   {path: ux ,          depends: [ '@uxflash'] }
     *  ,'mif'         :   {path: ux ,          depends: [ '@uxvismode' ] }
     *  ,'mifmsg'      :   {path: ux ,          depends: [ '@mif'] }
     *  ,'mifdd'       :   {path: ux ,          depends: [ '@mif'] }
     * });
     * 
     * //then, load as assembly:
     * $JIT('@uxfusion', callbackFn);
     * or
     * $JIT.onAvailable('uxfusion', callbackFn);
     *  
     * //$JIT also amends Ext.ComponentMgr to permit inline dynamic (synchronous-only)
     * loading of resources when using delayed-loading of Component configurations:
     *  
     *  new Ext.Panel({
     *     layout:'fit',
     *     items:{
     *        //demand and load 'customerform.js' and 'gmap' modules (if not already available)
     *        <b>require</b> : ['dialogs/customerform','gmap'],    
     *        xtype : 'tabpanel',
     *        items : {title:'Grid', <b>JIT:</b>'custom-grid',...}
     *      }
     *  });
     *  
     *  Another asynchronous method available is namespace/object polling:
     *  $JIT('ux/Rowediter');
     *  $JIT.onClassAvailable('Ext.ux.grid.RowEditor',function(available){
              if(available){
                   var plugin = new Ext.ux.grid.RowEditor().init(this);
                   .....
              }
          },
          myGrid,
          30  //second timeout
         );
     *  
     *  
     *  //Load a script via script tag:
     *  $JIT.script('resources/script/admin[.js]', function(loaded){ ... } );
     *  
     *  //Make an Ajax request
     *  $JIT.post({params:{node:44}}, 'assets/treenodes.php',
     *   function(loaded, modules){
     *      if(loaded){
     *        var nodes = modules.first().content['JSON/text/XML'];
     *        ... 
     *      }
     *    });
     *    
     *  //Retrieve the content from a previously loaded (cached) resource:
     *  var text = $JIT.getModule('treenodes').content.text;
     *  
     *  //Load a CSS resource and apply it as a theme:
     *  $JIT.css('themes/brightblue.css', 'lightgreen.css' );
     *  $JIT.onAvailable('brightblue.css', function(loaded){
     *     loaded && $JIT.applyStyle('brightblue.css');
     *  });
     *  //Stylesheet removal:
     *  $JIT.removeStyle('brightblue.css');
     */

    $JIT = function(){
        var modules = new Array();

        forEach(Array.slice(arguments, 0),
           function(module){
            modules = modules.concat(typeof module == 'function' ? module : L.getMap(module) );
         }, L);
         L.load.apply(L,modules.flatten());
         return L;
    };
    
    Ext.ux.$JIT = Ext.require = $JIT;
    
    var on = L.addListener.createDelegate(L),
        un = L.removeListener.createDelegate(L);

    //create a unique flexible dialect for $JIT:
    Ext.apply($JIT,{

            /**
             * @name onAvailable
             * @methodOf $JIT
             * Invoke the passed callback when all named modules in the array are available
             * @example
             *  $JIT.onAvailable(['tree','grid'], this.buildWin , scope,  timeout);
             */
            onAvailable : Ext.Loader.onAvailable.createDelegate(L),
            
            /**
             * @name onClassAvailable
             * @methodOf $JIT
             * Invoke the passed callback when all specified class Objects are available.
             * @param {Array,String} classList single of Array of string classNames to test.
             * @param {Function} callbackFn Callback function invoked with the following arguments:<p>
             *   {Boolean} success,
             *   {Array} classes</p>
             * @param {Object} scope Scope with call the callback with.
             * @param (Integer) timeout Number of seconds to wait before timeout (default 30 seconds)
             * @example
  $JIT.onClassAvailable('Ext.ux.grid.RowEditor',function(available){
      if(available){
         var plugin = new Ext.ux.grid.RowEditor().init(this);
         .....
      }
    },
    myGrid
    );
  
 or
 
 $JIT.onClassAvailable(['Ext.ux.grid.RowEditor','Ext.ux.ManagedIFrame'],classesAreHereFn);
             */
            onClassAvailable : (function(){ 
            
	            var options = null;
	            
	            var F = function OCAV(classList, callback, scope, timeout) { 
		               var o, 
		                   d, 
		                   classes=[],
		                   opt = {
		                      interval : 100,
		                      retries  : (timeout||30000)/100,
		                      callback : callback || Ext.emptyFn,
		                      scope    : scope || null
		                      };
		                     
	
	                   if(!options){
	                       options = Ext.clone(opt);
	                   }
		               
		               Ext.each([].concat(classList||[]).compact(), 
		                  function (v) {
		                     if(Ext.isString(v)){
			                     d = v.split(".");
			                     if(o = window[d[0]]){
				                     Ext.each(d.slice(1), 
				                        function (next) {
				                           return !!(o = o[next]);
				                       }); 
				                       o && classes.push(o);
			                      } else return false;
	                         }
		                 }); 
                         
                         //callback with the first Array element if only one
                         var C = classes.compact();
                         C = C.length < 2 ? C.first() : C;
                         
	                     if(!!o){ 
		                    options.callback.call(options.scope, true, C);
		                 }else{
		                    if(--options.retries){
	                           arguments.callee.defer(options.interval,this,arguments);
	                           return;
	                        }
		                    else {
	                           options.callback.call(options.scope, false, C);
	                        }
		                }
	                    options = null;
		             };
	                 var OCAV = null;
	                 return F;
            })(),

            //Logical Registration of a module  eg: $JIT.provide('mainAppStart');
            provide     : Ext.provide = L.provides.createDelegate(L),

            on          : on,
            addListener : on,
            un          : un,
            removeListener : un,
            depends     : L.depends,
            
            loaded      : L.loaded.createDelegate(L),
            getModule   : L.getModule.createDelegate(L),


            //Set the default module retrieval mechanism (DOM == <script, link> tags, GET,PUT,POST == XHR methods )
            setMethod   : function(method){
                              L.method = (method||'DOM').toUpperCase();
                          },
            //Set the default site path (relative/absolute)
            setModulePath: function(path){
                              L.modulePath = path || '';
                          },
            execScript  : L.globalEval.createDelegate(L),
            lastError   : function(){return L.lastError;},
            
            /**
             * @param {Integer} set/change the default onAvailable/load method timeout value in
             *      milliseconds
             */
            setTimeout  : function(tmo){ L.timeout = parseInt(tmo||0,10);},
            applyStyle  : L.applyStyle.createDelegate(L),
            removeStyle  : L.removeStyle.createDelegate(L),

            css         : L.load.createDelegate(L,[
                            {method        :'GET',
                             cacheResponses: true,
                             modulePath    :''
                             }],0),

            script      : L.load.createDelegate(L,[
                            {method        :'DOM',
                             modulePath    :''
                             }],0),

            get         : L.load.createDelegate(L,[
                            {method        :'GET',
                             modulePath    :''
                             }],0),
                             
            post         : L.load.createDelegate(L,[
				            {method        :'POST',
				             modulePath    :''
				             }],0),

            getCached   : L.load.createDelegate(L,[
                            {method        :'GET',
                             modulePath    :'',
                             cacheResponses: true
                             }],0)
    });

    $JIT.provide('jit','ext-basex');

    $JIT.on('loadexception',function(loader, module , ecode, title){

      if(!ecode)return;
      var ec = ecode.error || ecode;
      var msg = ec? ec.message || ec.description || ec.name || ecode: null;

      if(msg){
          if(Ext.MessageBox){
              Ext.MessageBox.alert(title||'unknown',msg);
          } else {
              alert((title?title+'\n':'')+msg );
          }
      }
    });

    /* Add 'require/JIT' support (synchronous only) permitting progressive loads to lazy-loaded component configs
     new Ext.Panel({
        layout:'fit',
        items:{
           require : ['tabs','gmap'],    //demand and load 'tabs' and 'gmap' module configs if not already available
           xtype : 'tabpanel',
           items : {title:'Grid', JIT:'edit-grid',...}
         }
     });
     
     or
     
     var grid = $JIT.create({
         require : [{timeout: 15000}, 'customGrid.js'],
         title : 'User List',
         ....
      });
    */

    var mgr = Ext.ComponentMgr,
        load_options =
            {async    :false,
             method   :'GET',
             callback : function(completed){
                 !completed && 
                     L.fireEvent('loadexception', L, this.currentModule, "Ext.ComponentMgr:$JIT Load Failure");
             },
             scope : L
        },
        assert =  function(rm){
           return !!rm && typeof rm == 'object' ? Ext.apply({},load_options, rm): rm;
        };

    if(mgr){
       
       $JIT.create =
       Ext.create = 
       mgr.create = 
       mgr.create.createInterceptor( function(config, defaultType){

               var require= config.require || config.JIT;
               if(!!require){
                   require = [load_options].concat(require).map( assert ).compact();
                   //This synchronous request will block until completed
                   Ext.require.apply(Ext, require);

               }
          });

   }


 })();