package hxp;


import haxe.io.Path;
import haxe.Template;
import sys.io.File;
import sys.FileSystem;


class FileHelper {
	
	
	private static var knownExtensions:Map<String, FileType>;
	
	
	private static function __init__ ():Void {
		
		knownExtensions = [
			
			"jpg" => IMAGE,
			"jpeg" => IMAGE,
			"png" => IMAGE,
			"gif" => IMAGE,
			"webp" => IMAGE,
			"bmp" => IMAGE,
			"tiff" => IMAGE,
			"jfif" => IMAGE,
			"otf" => FONT,
			"ttf" => FONT,
			"wav" => SOUND,
			"wave" => SOUND,
			"mp3" => MUSIC,
			"mp2" => MUSIC,
			"exe" => BINARY,
			"bin" => BINARY,
			"so" => BINARY,
			"pch" => BINARY,
			"dll" => BINARY,
			"zip" => BINARY,
			"tar" => BINARY,
			"gz" => BINARY,
			"fla" => BINARY,
			"swf" => BINARY,
			"atf" => BINARY,
			"psd" => BINARY,
			"awd" => BINARY,
			"txt" => TEXT,
			"text" => TEXT,
			"xml" => TEXT,
			"java" => TEXT,
			"hx" => TEXT,
			"cpp" => TEXT,
			"c" => TEXT,
			"h" => TEXT,
			"cs" => TEXT,
			"js" => TEXT,
			"mm" => TEXT,
			"hxml" => TEXT,
			"html" => TEXT,
			"json" => TEXT,
			"css" => TEXT,
			"gpe" => TEXT,
			"pbxproj" => TEXT,
			"plist" => TEXT,
			"properties" => TEXT,
			"ini" => TEXT,
			"hxproj" => TEXT,
			"nmml" => TEXT,
			"lime" => TEXT,
			"svg" => TEXT,
			
		];
		
	}
	
	
	public static function copyFile (source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		var extension = Path.extension (source);
		
		if (process && context != null) {
			
			if (knownExtensions.exists (extension) && knownExtensions.get (extension) != TEXT) {
				
				copyIfNewer (source, destination);
				return;
				
			}
			
			var _isText = false;
			
			if (knownExtensions.exists (extension) && knownExtensions.get (extension) == TEXT) {
				
				_isText = true;
				
			} else {
				
				_isText = isText (source);
				
			}
			
			if (_isText) {
				
				//Log.info ("", " - \x1b[1mProcessing template file:\x1b[0m " + source + " \x1b[3;37m->\x1b[0m " + destination);
				
				var fileContents:String = File.getContent (source);
				var template:Template = new Template (fileContents);
				var result:String = template.execute (context, { 
					toJSON: function(_, s) return haxe.Json.stringify(s),
					upper: function (_, s) return s.toUpperCase (),
					replace: function (_, s, sub, by) return StringTools.replace(s, sub, by)
				});
				
				try {
					
					if (FileSystem.exists (destination)) {
						
						var existingContent = File.getContent (destination);
						if (result == existingContent) return;
						
					}
					
				} catch (e:Dynamic) {}
				
				PathHelper.mkdir (Path.directory (destination));
				
				Log.info ("", " - \x1b[1mCopying template file:\x1b[0m " + source + " \x1b[3;37m->\x1b[0m " + destination);
				
				try {
					
					File.saveContent (destination, result);
					
				} catch (e:Dynamic) {
					
					Log.error ("Cannot write to file \"" + destination + "\"");
					
				}
				
				return;
				
			}
			
		}
		
		copyIfNewer (source, destination);
		
	}
	
	
	public static function copyFileTemplate (templatePaths:Array<String>, source:String, destination:String, context:Dynamic = null, process:Bool = true, warnIfNotFound:Bool = true) {
		
		var path = PathHelper.findTemplate (templatePaths, source, warnIfNotFound);
		
		if (path != null) {
			
			copyFile (path, destination, context, process);
			
		}
		
	}
	
	
	public static function copyIfNewer (source:String, destination:String) {
		
		//allFiles.push (destination);
		
		if (!isNewer (source, destination)) {
			
			return;
			
		}
		
		PathHelper.mkdir (Path.directory (destination));
		
		Log.info ("", " - \x1b[1mCopying file:\x1b[0m " + source + " \x1b[3;37m->\x1b[0m " + destination);
		
		try {
			
			File.copy (source, destination);
			
		} catch (e:Dynamic) {
			
			try {
				
				if (FileSystem.exists (destination)) {
					
					Log.error ("Cannot copy to \"" + destination + "\", is the file in use?");
					return;
					
				} else {}
				
			} catch (e:Dynamic) {}
			
			Log.error ("Cannot open \"" + destination + "\" for writing, do you have correct access permissions?");
			
		}
		
	}
	
	
	public static function getLastModified (source:String):Float {
		
		if (FileSystem.exists (source)) {
			
			return FileSystem.stat (source).mtime.getTime ();
			
		}
		
		return -1;
		
	}
	
	
	public static function linkFile (source:String, destination:String, symbolic:Bool = true, overwrite:Bool = false) {
		
		if (!isNewer (source, destination)) {
			
			return;
			
		}
		
		if (FileSystem.exists (destination)) {
			
			FileSystem.deleteFile (destination);
			
		}
		
		if (!FileSystem.exists (destination)) {
			
			try {
				
				var command = "/bin/ln";
				var args = [];
				
				if (symbolic) {
					
					args.push ("-s");
					
				}
				
				if(overwrite){
					
					args.push("-f");
					
				}
				
				args.push (source);
				args.push (destination);
				
				ProcessHelper.runCommand (".", command, args);
				
			} catch (e:Dynamic) {}
			
		}
		
	}
	
	
	public static function recursiveCopy (source:String, destination:String, context:Dynamic = null, process:Bool = true) {
		
		PathHelper.mkdir (destination);
		
		var files:Array<String> = null;
		
		try {
			
			files = FileSystem.readDirectory (source);
			
		} catch (e:Dynamic) {
			
			Log.error ("Could not find source directory \"" + source + "\"");
			
		}
		
		for (file in files) {
			
			if (file.substr (0, 1) != ".") {
				
				var itemDestination:String = destination + "/" + file;
				var itemSource:String = source + "/" + file;
				
				if (FileSystem.isDirectory (itemSource)) {
					
					recursiveCopy (itemSource, itemDestination, context, process);
					
				} else {
					
					copyFile (itemSource, itemDestination, context, process);
					
				}
				
			}
			
		}
		
	}
	
	
	public static function recursiveCopyTemplate (templatePaths:Array<String> = null, source:String, destination:String, context:Dynamic = null, process:Bool = true, warnIfNotFound:Bool = true) {
		
		var destinations = [];
		var paths = PathHelper.findTemplateRecursive (templatePaths, source, warnIfNotFound, destinations);
		
		if (paths != null) {
			
			PathHelper.mkdir (destination);
			var itemDestination;
			
			for (i in 0...paths.length) {
				
				itemDestination = PathHelper.combine (destination, destinations[i]);
				copyFile (paths[i], itemDestination, context, process);
				
			}
			
		}
		
	}
	
	
	public static function replaceText (source:String, replaceString:String, replacement:String) {
		
		if (FileSystem.exists (source)) {
			
			var output = File.getContent (source);
			
			var index = output.indexOf (replaceString);
			
			if (index > -1) {
				
				output = output.substr (0, index) + replacement + output.substr (index + replaceString.length);
				File.saveContent (source, output);
				
			}
			
		}
		
	}
	
	
	public static function isNewer (source:String, destination:String):Bool {
		
		if (source == null || !FileSystem.exists (source)) {
			
			Log.error ("Source path \"" + source + "\" does not exist");
			return false;
			
		}
		
		if (FileSystem.exists (destination)) {
			
			if (FileSystem.stat (source).mtime.getTime () < FileSystem.stat (destination).mtime.getTime ()) {
				
				return false;
				
			}
			
		}
		
		return true;
		
	}
	
	
	public static function isText (source:String):Bool {
		
		if (!FileSystem.exists (source)) {
			
			return false;
			
		}
		
		var input = File.read (source, true);
		
		var numChars = 0;
		var numBytes = 0;
		var byteHeader = [];
		var zeroBytes = 0;
		
		try {
			
			while (numBytes < 512) {
				
				var byte = input.readByte ();
				
				if (numBytes < 3) {
					
					byteHeader.push (byte);
					
				} else if (byteHeader != null) {
					
					if (byteHeader[0] == 0xFF && byteHeader[1] == 0xFE) return true; // UCS-2LE or UTF-16LE
					if (byteHeader[0] == 0xFE && byteHeader[1] == 0xFF) return true; // UCS-2BE or UTF-16BE
					if (byteHeader[0] == 0xEF && byteHeader[1] == 0xBB && byteHeader[2] == 0xBF) return true; // UTF-8
					byteHeader = null;
					
				}
				
				numBytes++;
				
				if (byte == 0) {
					
					zeroBytes++;
					
				}
				
				if ((byte > 8 && byte < 16) || (byte > 32 && byte < 256) || byte > 287) {
					
					numChars++;
					
				}
				
			}
			
		} catch (e:Dynamic) { }
		
		input.close ();
		
		if (numBytes == 0 || (numChars / numBytes) > 0.9 || ((zeroBytes / numBytes) < 0.015 && (numChars / numBytes) > 0.5)) {
			
			return true;
			
		}
		
		return false;
		
	}
	
	
}


private enum FileType {

	BINARY;
	FONT;
	IMAGE;
	MUSIC;
	SOUND;
	TEXT;

}