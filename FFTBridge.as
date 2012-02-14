package
{
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.ActivityEvent;
import flash.events.Event;
import flash.events.SampleDataEvent;
import flash.events.StatusEvent;
import flash.events.IEventDispatcher;	// not sure if we actually need this.
import flash.external.ExternalInterface;
import flash.media.Microphone;
import flash.utils.ByteArray;
import flash.text.TextField;
import flash.utils.Timer;
import flash.events.*;

[SWF(backgroundColor='0xaaaaaa')]

public class FFTBridge extends MovieClip {
	private static const SR_AUDIO_ALLOWED:String = 'SRAudioAllowed';
	private var _mic:Microphone;
	private var _container:Array = new Array();
	
	public function FFTBridge() {
		_mic = Microphone.getMicrophone();
	
		if (_mic == null) {
			var helloDisplay:TextField = new TextField();
			helloDisplay.text = 'Cannot Access Microphone';
			addChild(helloDisplay);				
		}
		
		_mic.gain = 60;
		_mic.rate = 11;
		_mic.setUseEchoSuppression(false);
		//_mic.setLoopBack(true);
		_mic.setSilenceLevel(0, 1000);
		ExternalInterface.addCallback('setMicRate', setMicRate);
		ExternalInterface.addCallback('startMicRecording', startMicRecording);
		ExternalInterface.addCallback('stopMicRecording', stopMicRecording);
		startMicRecording();
	}

	private function setMicRate(samplerate:int):void {
		_mic.rate = int(samplerate/1000);
	}

	private function startMicRecording():void {
		_mic.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
	}

	private function stopMicRecording():void {
		_mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
		
		if(ExternalInterface.available) {
			ExternalInterface.call('mic_stopped');
		}
	}

	private function onSampleData(event:SampleDataEvent):void {
		
		while(event.data.bytesAvailable) {
			// fetch the sample information and adjust
			var sample:Number = event.data.readFloat() * 65536;
	
			// add it to our container
			_container.push(sample);
	
			// if we have enough samples, flush and start again
			// ## If this is is too short, Flash doesn't respond to the ##
			// ## stopMicRecording call from javascript. The more data ##
			// ## we collect in javascript, the longer this must be. ##
			if (_container.length >= 512) {
				if(ExternalInterface.available) {
					// send to js function
					ExternalInterface.call('stageOneFFT', _container); 
					_container.length = 0;
				}
			}
		} // end of while
	} // end of function onSampleData
	
}} // end of class movieclip and the outer package definition