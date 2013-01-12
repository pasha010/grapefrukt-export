package com.grapefrukt.exporter.serializers.data {

    import com.grapefrukt.exporter.animations.Animation;
    import com.grapefrukt.exporter.animations.AnimationFrame;
    import com.grapefrukt.exporter.animations.AnimationMarker;
    import com.grapefrukt.exporter.animations.AnimationPart;
    import com.grapefrukt.exporter.collections.AnimationCollection;
    import com.grapefrukt.exporter.collections.TextureSheetCollection;
    import com.grapefrukt.exporter.settings.Settings;
    import com.grapefrukt.exporter.textures.BitmapTexture;
    import com.grapefrukt.exporter.textures.FontSheet;
    import com.grapefrukt.exporter.textures.MultiframeBitmapTexture;
    import com.grapefrukt.exporter.textures.TextureBase;
    import com.grapefrukt.exporter.textures.TextureSheet;
    import com.grapefrukt.exporter.textures.VectorTexture;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.utils.ByteArray;

/**
	 * ...
	 * @author Martin Jonasson, m@grapefrukt.com
	 */
	public class XMLDataWithMatrixSerializer extends BaseDataSerializer implements IDataSerializer  {

    private static var tmp_point:Point = new Point;

    public function serialize(target:*, useFilters:Boolean = true):ByteArray {
        var xml:XML = _serialize(target);
        var ba:ByteArray = new ByteArray;
        ba.writeUTFBytes(xml.toXMLString());

        if (useFilters) return filter(ba);
        return ba;
    }

    protected function _serialize(target:*):XML {
        if (target is FontSheet)	 			return serializeFontSheet(FontSheet(target));

        if (target is VectorTexture) 			return serializeVectorTexture(VectorTexture(target));
        if (target is BitmapTexture) 			return serializeTexture(BitmapTexture(target));
        if (target is TextureSheet) 			return serializeTextureSheet(TextureSheet(target));
        if (target is TextureSheetCollection) 	return serializeTextureSheetCollection(TextureSheetCollection(target));

        if (target is Animation)				return serializeAnimation(Animation(target));
        if (target is AnimationCollection)		return serializeAnimationCollection(AnimationCollection(target));
        if (target is AnimationFrame)			return serializeAnimationFrame(AnimationFrame(target));

        throw new Error("no code to serialize " + target);
        return null;
    }

    protected function serializeVectorTexture(texture:VectorTexture):XML {
        var xml:XML = <VectorTexture></VectorTexture>;
        xml.@name 	= texture.name;
        xml.@path 	= texture.filenameWithPath;
        if (texture.isMask) xml.@mask = texture.isMask ? "1" : "0";
        if (texture.zIndex != 0) xml.@zIndex = texture.zIndex;
        return xml;
    }

    protected function serializeTextureSheetCollection(collection:TextureSheetCollection):XML {
        collection.sort();
        var xml:XML = <Textures></Textures>
        for (var i:int = 0; i < collection.size; i++) {
            xml.appendChild(_serialize(collection.getAtIndex(i)));
        }
        return xml;
    }

    protected function serializeTextureSheet(sheet:TextureSheet):XML {
        var xml:XML = <TextureSheet></TextureSheet>;
        xml.@name = sheet.name;

        sheet.sort();

        for each(var texture:TextureBase in sheet.textures) {
            xml.appendChild(_serialize(texture))
        }

        return xml;
    }

    protected function serializeTexture(texture:BitmapTexture):XML {
        var xml:XML = <Texture></Texture>;
        xml.@name 	= texture.name;
        xml.@width 	= Math.round(texture.bounds.width);
        xml.@height = Math.round(texture.bounds.height);
        xml.@path 	= texture.filenameWithPath;

        xml.@registrationPointX = texture.registrationPoint.x.toFixed(2);
        xml.@registrationPointY = texture.registrationPoint.y.toFixed(2);

        if (texture.isMask) xml.@mask = texture.isMask ? "1" : "0";
        if (texture.zIndex != 0) xml.@zIndex = texture.zIndex;


        var mftexture:MultiframeBitmapTexture = texture as MultiframeBitmapTexture;
        if (mftexture) {
            xml.@frameCount 	= mftexture.frameCount;
            xml.@frameWidth 	= mftexture.frameBounds.width;
            xml.@frameHeight 	= mftexture.frameBounds.height;
            xml.@columns 		= mftexture.columns;

            if (mftexture.framerate != Settings.defaultFramerate) xml.@framerate = mftexture.framerate;
        }

        return xml;
    }


    protected function serializeAnimationCollection(collection:AnimationCollection):XML {
        collection.sort();
        var xml:XML = <Animations></Animations>
        for (var i:int = 0; i < collection.size; i++) {
            xml.appendChild(_serialize(collection.getAtIndex(i)));
        }
        return xml;
    }

    protected function serializeAnimation(animation:Animation):XML {
        var xml:XML = <Animation></Animation>;
        xml.@name 		= animation.name;
        xml.@frameCount = animation.frameCount;
        if (animation.loopAt != -1) 							xml.@loopAt = animation.loopAt;
        if (animation.mask) 									xml.@mask	= animation.mask;
        if (animation.framerate != Settings.defaultFramerate) 	xml.framerate	= animation.framerate;

        animation.sort();

        for each (var marker:AnimationMarker in animation.markers) {
            var markerXML:XML = <Marker></Marker>;
            markerXML.@name = marker.name;
            markerXML.@frame = marker.frame;
            xml.appendChild(markerXML);
        }

        for each (var part:AnimationPart in animation.parts) {
            var partXML:XML = <Part></Part>;
            partXML.@name = part.name;
            for (var i:int = 0; i < part.frames.length; i++) {
                var frameXML:XML = _serialize(part.frames[i]);
                if (frameXML) {
                    frameXML.@index = i;
                    partXML.appendChild(frameXML);
                }
            }

            xml.appendChild(partXML)
        }

        return xml;
    }

    protected function serializeAnimationFrame(frame:AnimationFrame):XML {

        var xml:XML = <Frame></Frame>;
        var m:Matrix = frame.transformMatrix;
        var tmp_point:Point = new Point;

        if (frame.alpha > 0) {
            // warning. here be matrix math!
            var scaleX:Number = Math.sqrt(m.a * m.a + m.b * m.b);

            // use a temporary point and transform it using the matrix
            tmp_point.x = 1 / scaleX;
            tmp_point.y = 0;
            tmp_point = m.deltaTransformPoint(tmp_point);

            // figure out rotation using atan2 and round using the set precision
            var rotation:Number = ((180 / Math.PI) * Math.atan2(tmp_point.x, tmp_point.y) - 90);
            // flip rotation (not sure why this is needed)
            rotation *= -1;

            xml.@x          = m.tx.toFixed(Settings.positionPrecision);
            xml.@y          = m.ty.toFixed(Settings.positionPrecision);
            xml.@scaleX 	= m.a.toFixed(Settings.scalePrecision);
            xml.@scaleY 	= m.d.toFixed(Settings.scalePrecision);
            xml.@rotation   = wrap(rotation).toFixed(Settings.rotationPrecision);
            xml.@skewX 	    = m.c.toFixed(Settings.rotationPrecision);
            xml.@skewY 	    = m.b.toFixed(Settings.rotationPrecision);
            xml.@alpha 	    = frame.alpha.toFixed(Settings.alphaPrecision);

            stripAnimationFrameDefaults(xml);
        } else {
            return null;
        }

        return xml;
    }

    protected static function stripAnimationFrameDefaults(frameNode:XML):void {
        if (frameNode.@x 		== (0).toFixed(Settings.positionPrecision)) {
            delete frameNode.@x;
        }
        if (frameNode.@y 		== (0).toFixed(Settings.positionPrecision)) {
            delete frameNode.@y;
        }
        if (frameNode.@scaleX 	== (1).toFixed(Settings.scalePrecision)) {
            delete frameNode.@scaleX;
        }
        if (frameNode.@scaleY	== (1).toFixed(Settings.scalePrecision)) {
            delete frameNode.@scaleY;
        }
        if (frameNode.@alpha 	== (1).toFixed(Settings.alphaPrecision)) {
            delete frameNode.@alpha;
        }
        if (frameNode.@rotation == (0).toFixed(Settings.rotationPrecision)) {
            delete frameNode.@rotation;
        }

        if (frameNode.@skewX 	== (0).toFixed(Settings.rotationPrecision)) {
            delete frameNode.@skewX;
        }
        if (frameNode.@skewY	== (0).toFixed(Settings.rotationPrecision)) {
            delete frameNode.@skewY;
        }

    }

    protected function serializeFontSheet(sheet:FontSheet):XML {
        var xml:XML = <FontData></FontData>;
        xml.Texture = sheet.filenameWithPath;
        xml.LineHeight = sheet.lineHeight;
        xml.CharSpace = sheet.charSpace;
        xml.WordSpace = sheet.wordSpace;

        sheet.sort();

        for each(var texture:BitmapTexture in sheet.unmergedTextures) {
            var charXML:XML = XML("<Char>\n  </Char>");
            charXML.@id		= texture.name.charCodeAt(0);
            charXML.@rect_x = texture.bounds.x;
            charXML.@rect_y = texture.bounds.y;
            charXML.@rect_w = texture.bounds.width;
            charXML.@rect_h = texture.bounds.height;

            xml.appendChild(charXML);
        }

        return xml;
    }

    /**
     * finally wrap rotation to be between -180 and 180
     * (as is normal flash behaviour) and round off to specified number of decimals
     */
    protected static function wrap(value:Number, max:Number = 180, min:Number = -180):Number {
        while (value >= max) value -= (max - min);
        while (value < min) value += (max - min);
        return value;
    }

}

}