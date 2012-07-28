package com.grapefrukt.exporter.utils {
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	/**
	 * @author ruben01
	 */
	public class RecursiveTracer {
		public static function traceDisplayList(container : DisplayObjectContainer, indentString : String = "") : void {
			var child : DisplayObject;
			for (var i : uint = 0; i < container.numChildren; i++) {
				child = container.getChildAt(i);
				trace(indentString, child, child.name);
				if (container.getChildAt(i) is DisplayObjectContainer) {
					traceDisplayList(DisplayObjectContainer(child), indentString + "    ")
				}
			}
		}
	}
}
