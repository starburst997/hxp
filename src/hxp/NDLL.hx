package hxp;


import sys.FileSystem;


class NDLL {


	public var extensionPath:String;
	public var haxelib:Haxelib;
	public var name:String;
	public var path:String;
	public var registerStatics:Bool;
	public var staticLink:Null<Bool>;
	public var subdirectory:String;


	public function new (name:String, haxelib:Haxelib = null, staticLink:Null<Bool> = null, registerStatics:Bool = true) {

		this.name = name;
		this.haxelib = haxelib;
		this.staticLink = staticLink;
		this.registerStatics = registerStatics;

	}


	public function clone ():NDLL {

		var ndll = new NDLL (name, haxelib, staticLink, registerStatics);
		ndll.path = path;
		ndll.extensionPath = extensionPath;
		ndll.subdirectory = subdirectory;
		return ndll;

	}
	
	
	public static function getLibraryPath (ndll:NDLL, directoryName:String, namePrefix:String = "", nameSuffix:String = ".ndll", allowDebug:Bool = false):String {
		
		var usingDebug = false;
		var path = "";
		
		if (allowDebug) {
			
			path = searchForLibrary (ndll, directoryName, namePrefix + ndll.name + "-debug" + nameSuffix);
			usingDebug = FileSystem.exists (path);
			
		}
		
		if (!usingDebug) {
			
			path = searchForLibrary (ndll, directoryName, namePrefix + ndll.name + nameSuffix);
			
		}
		
		return path;
		
	}
	
	
	private static function searchForLibrary (ndll:NDLL, directoryName:String, filename:String):String {
		
		if (ndll.path != null && ndll.path != "") {
			
			return ndll.path;
			
		} else if (ndll.haxelib == null) {
			
			if (ndll.extensionPath != null && ndll.extensionPath != "") {
				
				var subdirectory = "ndll/";
				
				if (ndll.subdirectory != null) {
					
					if (ndll.subdirectory != "") {
						
						subdirectory = ndll.subdirectory + "/";
						
					} else {
						
						subdirectory = "";
						
					}
					
				}
				
				return Path.combine (ndll.extensionPath, subdirectory + directoryName + "/" + filename);
				
			} else {
				
				return filename;
				
			}
			
		} else if (ndll.haxelib.name == "hxcpp") {
			
			var extension = Path.extension (filename);
			
			if (extension == "a" || extension == "lib") {
				
				return Path.combine (Haxelib.getPath (ndll.haxelib, true), "lib/" + directoryName + "/" + filename);
				
			} else {
				
				return Path.combine (Haxelib.getPath (ndll.haxelib, true), "bin/" + directoryName + "/" + filename);
				
			}
			
		} else {
			
			var subdirectory = "ndll/";
			
			if (ndll.subdirectory != null) {
				
				if (ndll.subdirectory != "") {
					
					subdirectory = ndll.subdirectory + "/";
					
				} else {
					
					subdirectory = "";
					
				}
				
			}
			
			return Path.combine (Haxelib.getPath (ndll.haxelib, true), subdirectory + directoryName + "/" + filename);
			
		}
		
	}


}