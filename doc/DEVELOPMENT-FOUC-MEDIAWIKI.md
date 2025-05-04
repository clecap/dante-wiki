
A nasty problem is the FOUC often found in mediawiki pages.


### 1. Verify That addModuleStyles() is Actually Emitting 

Open the rendered HTML and inspect the head. 
Look for: link rel="stylesheet" href="/w/load.php?...ext.myExtension.styles..."

### 2. The modulde included by addModulesStyles() in extension.json should only include JS. 

If it also includes JS it will be emitted late.

```
  "ResourceModules": {
    "ext.myExtension.styles": {
      "styles": "resources/ext.myExtension.css",
      "scripts": "resources/someScript.js"
    } 
  }
```

### 3. Add positioning "position": "top"

```
  "ext.myExtension.styles": {
    "styles": "resources/ext.myExtension.css",
    "position": "top"
  },
  "ext.myExtension": {
    "scripts": "resources/ext.myExtension.js",
    "dependencies": [ "ext.myExtension.styles" ]
  }
```

### 4. Check Module Registration in extension.json

Make sure your module is under "ResourceModules", not "ResourceFileModulePaths" unless you know exactly what you’re doing.

### Example: DantePresentations.php does it right


## When should we use late loading of css

When styles are not needed for initial rendering.

Examples:
* Dialog styles
* Editor overlays
* Hidden UI components which are shown only later

For this usecase we can 
* place relevant js and css into one extension module and 
* drop position:top in extension


