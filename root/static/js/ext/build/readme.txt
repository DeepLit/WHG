 ************************************************************************************
 * Author: Doug Hendricks. doug[always-At]theactivegroup.com
 * Copyright 2007-2009 Active Group, Inc.  All rights reserved.
 ************************************************************************************
  
 ext-basex 4.0 Ext Base Adapter Extensions
 $JIT 1.2  Dynamic ModuleManager/Loader
 
 For Ext 2.x,3.x, Core 3.x+ only.
 
 basex/JIT is structured to permit custom builds (using the Ext JSBuilder 2).
 The distribution should contain a standard build of ext-basex.js and jitx.js with debug versions of
 each designed for typical use with the named Ext frameworks.
 
 Ext 2.x, 3.x
************************************************************************************
Recommended development(debugging) tag configuration for Ext 2,3 and ext-basex Adapter extensions only:
<head>
 <link rel="stylesheet" type="text/css" href="../lib/ext-3.0+/resources/css/ext-all.css" />
 <script type="text/javascript" src="../lib/ext-3.0+/adapter/ext/ext-base.js"></script>
 <script type="text/javascript" src="../lib/ext-3.0+/ext-all[-debug].js"></script>
 <script type="text/javascript" src="../lib/ux/ext-basex[-debug].js"></script>
</head>

************************************************************************************
Recommended development(debugging) tag configuration for Ext 2,3 and $JIT library 
(built with the required ext-basex extensions included)

<head>
 <link rel="stylesheet" type="text/css" href="../lib/ext-3.0+/resources/css/ext-all.css" />
 <script type="text/javascript" src="../lib/ext-3.0+/adapter/ext/ext-base.js"></script>
 <script type="text/javascript" src="../lib/ext-3.0+/ext-all[-debug].js"></script>
 <script type="text/javascript" src="../lib/ux/jitx[-debug].js"></script>
</head>


Ext Core 3.0+
************************************************************************************
Recommended development(debugging) tag configuration for Ext Core and ext-basex Adapter extensions/JIT:
<head>
 <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/ext-core/3.0.0/ext-core[-debug].js"></script>
 <script type="text/javascript" src="../lib/ux/ext-basex[-debug].js"></script>
 <!-- or (not both!) -->
 <script type="text/javascript" src="../lib/ux/jitx[-debug].js"></script>
</head>

 
 The included basex.jsb2 and jit.jsb2 are also provided for further customization to suite
 deployment needs.  Each version creates a default ext-basex.js and jitx.js for general 
 use as described above.
 
 For more details on Ext JSBuilder 2, see : http://www.extjs.com/products/jsbuilder/
  
 