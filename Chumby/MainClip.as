import flash.display.BitmapData;

class MainClip extends MovieClip
{
	public var loadingText:TextField;
	public var logo:MovieClip;
	public var bgClip:MovieClip;
	
	private var inited:Boolean = false;

	public var urls:Array = new Array();
	public var titles:Array = new Array();
	public var infoDetails:Array = new Array();

	public var lastUpdate:Date = null;
	public var pending:Boolean = false;
	public var clips:Array = new Array();
	
	public function loadNextCover():Void
	{
		if (urls.length == 0)
		{
			_root._chumby_widget_done = true;
			return;
		}
			
		var index:Number = Math.floor(Math.random() * urls.length);
		
		var coverUrl:String = urls[index];
		var titleString:String = titles[index];
		var detailString:String = infoDetails[index];
		
		urls.splice(index, 1);
		titles.splice(index, 1);
		infoDetails.splice(index, 1);

		var me = this;

		var listener:Object = new Object();
		
		var mcl:MovieClipLoader = new MovieClipLoader();

		listener.onLoadInit = function(image_mc:MovieClip, status:Number)
		{
			if (me.loadingText._visible)
				me.loadingText._visible = false;

			while (me.clips.length > 0)
			{
				var oldClip = me.clips.pop();
				
				oldClip.swapDepths(me.bgClip);
				oldClip.removeMovieClip();
			}
				
			var w_ratio = 160 / image_mc._width;
			var h_ratio = 240 / image_mc._height;
			
			var ratio = w_ratio;
			
			if (ratio > h_ratio)
				ratio = h_ratio;
				
			image_mc.forceSmoothing = true;

 			image_mc._width = image_mc._width * ratio;
			image_mc._height = image_mc._height * ratio;

			image_mc._x = (160 - image_mc._width) / 2;
			image_mc._y = (240 - image_mc._height) / 2;
			
			if (image_mc._x < 10)
				image_mc._x = 0;

			me.clips.push(image_mc);
			image_mc.swapDepths(me.logo);

			if (me.titleString != undefined)
				me.titleString.removeTextField();

			if (me.detailString != undefined)
				me.detailString.removeTextField();
			
			var tf:TextField = me.createTextField("titleString", me.getNextHighestDepth(), 165, 0, 150, 230);

			var tft:TextFormat = tf.getNewTextFormat();
			
			tft.bold = true;
			tft.size = 18;
			tft.font = "_sans";
			tft.color = 0xffffff;
			
			tf.text = titleString;
			tf.wordWrap = true;
			tf.selectable = false;
			tf.multiline = true;

			tf.setTextFormat(tft);

			tf = me.createTextField("detailString", me.getNextHighestDepth(), 165, tf.textHeight + 20, 150, 220 - tf.textHeight);

			var tft:TextFormat = tf.getNewTextFormat();
			
			tft.bold = false;
			tft.size = 14;
			tft.font = "_sans";
			tft.color = 0xffffff;
			
			tf.text = detailString;
			tf.wordWrap = true;
			tf.selectable = false;
			tf.multiline = true;

			tf.setTextFormat(tft);
			
			tf._y = me.logo._y - 10 - tf.textHeight;

			me.lastUpdate = new Date();
			me.pending = false;
		}
		
		mcl.addListener(listener);

		var clip:MovieClip = this.createEmptyMovieClip("clip_" + index, this.getNextHighestDepth());
		
		mcl.loadClip(coverUrl, clip);
	}
	
	public function onEnterFrame():Void
	{
		if (!inited)
		{
			var data:XML = new XML();
			data.ignoreWhite = true;
			var me = this;
			
			data.onLoad = function(success:Boolean)
			{
				if (success)
				{
					var rdf = this.firstChild;
					
					var coverUrls:Array = new Array();
					var titles:Array = new Array();
					var infoDetails:Array = new Array();
					
					for (var i = 0; i < rdf.childNodes.length; i++)
					{
						var desc = rdf.childNodes[i];
						
						var mature:Boolean = false;
						var trade:Boolean = false;
						var coverUrl:String = null;
						var series:String = "";
						var issue:String = "";
						var publisher:String = "";
						var price:String = "";

						var writer:String = "";
						var artist:String = "";

						for (var j = 0; j < desc.childNodes.length; j++)
						{
							var field = desc.childNodes[j];
							
							if (field.localName == "cover")
								coverUrl = field.firstChild.nodeValue;
							else if (field.localName == "mature")
								mature = true;
							else if (field.localName == "trade")
								trade = true;
							else if (field.localName == "issue")
								issue = field.firstChild.nodeValue;
							else if (field.localName == "series")
								series = field.firstChild.nodeValue;
							else if (field.localName == "publisher")
								publisher = field.firstChild.nodeValue;
							else if (field.localName == "price")
								price = field.firstChild.nodeValue;
							else if (field.localName == "writer" && writer == "")
								writer = field.firstChild.nodeValue;
							else if (field.localName == "illustrator" && artist == "")
								artist = field.firstChild.nodeValue;
						}
						
						if (!mature && !trade && coverUrl != null)
						{
							coverUrls.push(coverUrl);
							
							if (issue != undefined)
								titles.push(series + "\n" + issue);
							else
								titles.push(series);
								
							var detailString = "Various";
							
							if (writer != "" && artist != "" && writer != artist)
								detailString = writer + "\n" + artist;
							else if (writer != "")
								detailString = writer;
							else if (artist != "")
								detailString = artist;

							if (publisher != undefined)
								detailString += "\n\n" + publisher + "\n" + price;
								
							infoDetails.push(detailString);
						}
					}
					
					me.urls = coverUrls;
					me.titles = titles;
					me.infoDetails = infoDetails;
				} 
				else
				{
					me.loadingText.textColor = 0x880000;
					me.loadingText.text = "Error!";
					
					_root._chumby_widget_done = true;
				}
			}
			
			var sizeArgs = '?size=' + System.capabilities.screenResolutionY;

			data.load('http://freshcomics.us/this-week.xml' + sizeArgs);
			
			this.lastUpdate = new Date();
			
			inited = true;
		}
		else if (urls.length > 0)
		{
			var now:Date = new Date();
			
			if (!pending && (now.getTime() - lastUpdate.getTime()) > 5000)
			{
				this.loadNextCover();

				pending = true;
			}
		}
	}
}
