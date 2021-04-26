package com.poliroid.gui.frames_limiter
{

	import flash.events.Event;
	
	import scaleform.clik.data.DataProvider;
	import scaleform.clik.events.ListEvent;
	import scaleform.clik.events.IndexEvent;
	import scaleform.clik.events.SliderEvent;
	
	import net.wg.infrastructure.interfaces.IView;
	import net.wg.gui.lobby.settings.SettingsWindow;
	import net.wg.gui.lobby.settings.GraphicSettings;
	import net.wg.gui.events.ViewStackEvent;
	import net.wg.infrastructure.events.LifeCycleEvent;
	import net.wg.gui.components.controls.DropdownMenu;
	import net.wg.gui.components.controls.LabelControl;
	import net.wg.gui.lobby.settings.events.SettingViewEvent;
	import net.wg.gui.components.controls.NumericStepper;
	import net.wg.gui.components.controls.Slider;
	import net.wg.gui.components.controls.InfoIcon;
	import net.wg.gui.components.controls.CheckBox;

	public class SettingsUI
	{
		private static const GRAPHICS_SETTINGS_LINKAGE: String = "GraphicSettings";
		private static var settingsWindow:SettingsWindow = null;
		private static var graphicSettings:GraphicSettings = null;
		private static var _callback:Function = null;
		private static var _settings:Object = null;
		
		public function SettingsUI(view:IView, settings:Object, callback:Function): void
		{
			_callback = callback;
			_settings = settings;
			settingsWindow = view as SettingsWindow;
			settingsWindow.view.addEventListener(ViewStackEvent.VIEW_CHANGED, onViewStackEventHandler);
			settingsWindow.view.addEventListener(ViewStackEvent.NEED_UPDATE, onViewStackEventHandler);
			settingsWindow.addEventListener(LifeCycleEvent.ON_AFTER_DISPOSE, handleSettingsWindowDispose);
			App.utils.scheduler.scheduleOnNextFrame(onSettingsWindowOpened);
		}

		private function onSettingsWindowOpened(): void
		{
			if (settingsWindow.view.currentViewId != GRAPHICS_SETTINGS_LINKAGE)
				return
			graphicSettings = settingsWindow.view.currentView as GraphicSettings;
			hookGraphicSettings();
		}

		private function onViewStackEventHandler(_event: ViewStackEvent): void
		{
			if (_event.viewId != GRAPHICS_SETTINGS_LINKAGE)
				return;
			graphicSettings = _event.view as GraphicSettings
			hookGraphicSettings();
		}

		private function handleSettingsWindowDispose(_event: LifeCycleEvent): void
		{
			graphicSettings = null;
			settingsWindow = null;
		}

		private function hookGraphicSettings(): void
		{
			if (graphicSettings.screenForm.hasOwnProperty('fps_limiter_injected'))
				return;

			var _checkbox:CheckBox = App.utils.classFactory.getComponent("CheckBox", CheckBox);
			_checkbox.y = 245;
			_checkbox.x = 283;
			_checkbox.label = _settings.label;
			_checkbox.selected = _settings.enabled;
			_checkbox.toolTip = _settings.toolTip;
			_checkbox.width = 250;
			_checkbox.validateNow();
			_checkbox.infoIcoType = _settings.toolTip ? InfoIcon.TYPE_INFO : "";

			var _slider:Slider = App.utils.classFactory.getComponent("Slider", Slider);
			_slider.y = 276;
			_slider.x = 287;
			_slider.width = 160;
			_slider.minimum = 60;
			_slider.maximum = 220;
			_slider.snapInterval = 1;
			_slider.snapping = true;
			_slider.liveDragging = true;
			_slider.enabled = _settings.enabled;
			_slider.value = _settings.value;
			_slider.validateNow();

			var _number:NumericStepper = App.utils.classFactory.getComponent("NumericStepper", NumericStepper);
			_number.y = 275;
			_number.x = 450;
			_number.minimum = 60;
			_number.maximum = 220;
			_number.stepSize = 1;
			_number.enabled = _settings.enabled;
			_number.value = _settings.value;
			_number.validateNow();

			_checkbox.addEventListener(Event.SELECT, function () {
				graphicSettings.dispatchEvent(new SettingViewEvent(SettingViewEvent.ON_CONTROL_CHANGED, 'GraphicSettings', null, 'FramesLimiterEnabled', _checkbox.selected));
				_number.enabled = _checkbox.selected;
				_slider.enabled = _checkbox.selected;
				_callback(_checkbox.selected, _number.value);
			});
			_slider.addEventListener(SliderEvent.VALUE_CHANGE, function () {
				graphicSettings.dispatchEvent(new SettingViewEvent(SettingViewEvent.ON_CONTROL_CHANGED, 'GraphicSettings', null, 'FramesLimiterValue', _slider.value));
				_number.value = _slider.value;
				_callback(_checkbox.selected, _number.value);
			});
			_number.addEventListener(IndexEvent.INDEX_CHANGE, function () {
				graphicSettings.dispatchEvent(new SettingViewEvent(SettingViewEvent.ON_CONTROL_CHANGED, 'GraphicSettings', null, 'FramesLimiterValue', _number.value));
				_slider.value = _number.value;
				_callback(_checkbox.selected, _number.value);
			});

			graphicSettings.screenForm.addChild(_checkbox);
			graphicSettings.screenForm.addChild(_slider);
			graphicSettings.screenForm.addChild(_number);
			graphicSettings.screenForm['fps_limiter_injected'] = true;
		}
	}
}
