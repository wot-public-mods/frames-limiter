package me.poliroid.gui.frames_limiter
{

	import flash.display.MovieClip;
	import flash.events.Event;

	import scaleform.clik.data.DataProvider;
	import scaleform.clik.events.ButtonEvent;
	import scaleform.clik.events.IndexEvent;
	import scaleform.clik.events.ListEvent;
	import scaleform.clik.events.SliderEvent;

	import net.wg.data.constants.generated.LAYER_NAMES;
	import net.wg.gui.components.containers.MainViewContainer;
	import net.wg.gui.components.controls.CheckBox;
	import net.wg.gui.components.controls.LabelControl;
	import net.wg.gui.components.controls.Slider;
	import net.wg.gui.events.ViewStackEvent;
	import net.wg.gui.lobby.settings.SoundSettings;
	import net.wg.gui.lobby.settings.SoundVivoxForm;
	import net.wg.gui.lobby.settings.SettingsWindow;
	import net.wg.gui.lobby.settings.events.SettingViewEvent;
	import net.wg.infrastructure.base.AbstractView;
	import net.wg.infrastructure.events.LifeCycleEvent;
	import net.wg.infrastructure.events.LoaderEvent;
	import net.wg.infrastructure.interfaces.IManagedContent;
	import net.wg.infrastructure.interfaces.ISimpleManagedContainer;
	import net.wg.infrastructure.interfaces.IView;
	import net.wg.infrastructure.managers.impl.ContainerManagerBase;

	import me.poliroid.gui.frames_limiter.SettingsUI;

	public class LobbyHook extends AbstractView
	{
		public static const SETTINGS_WINDOW_LINKAGE:String = "settingsWindow";

		public var getFramesLimiterSettings:Function;
		public var setFramesLimiterSettings:Function;

		private function _getContainer(containerName:String) : ISimpleManagedContainer
		{
			return App.containerMgr.getContainer(LAYER_NAMES.LAYER_ORDER.indexOf(containerName))
		}

		override protected function onPopulate() : void
		{
			super.onPopulate();
			var viewContainer:MainViewContainer = _getContainer(LAYER_NAMES.VIEWS) as MainViewContainer;
			if (viewContainer != null)
			{
				var num:int = viewContainer.numChildren;
				for (var idx:int = 0; idx < num; ++idx)
				{
					var view:IView = viewContainer.getChildAt(idx) as IView;
					if (view != null)
					{
						processView(view);
					}
				}
				var topmostView:IManagedContent = viewContainer.getTopmostView();
				if (topmostView != null)
				{
					viewContainer.setFocusedView(topmostView);
				}
			}
			var containerMgr:ContainerManagerBase = App.containerMgr as ContainerManagerBase;
			containerMgr.loader.addEventListener(LoaderEvent.VIEW_LOADED, onViewLoaded, false, 0, true);
		}
		
		override protected function onDispose() : void 
		{
			var containerMgr:ContainerManagerBase = App.containerMgr as ContainerManagerBase;
			containerMgr.loader.removeEventListener(LoaderEvent.VIEW_LOADED, onViewLoaded);
			super.onDispose();
		}

		// this needs for valid Focus and Position in Login Window 
		override protected function nextFrameAfterPopulateHandler() : void 
		{
			super.nextFrameAfterPopulateHandler();
			if (parent != App.instance)
			{
				(App.instance as MovieClip).addChild(this);
			}
		}

		private function onViewLoaded(_event:LoaderEvent) : void
		{
			processView(_event.view as IView);
		}

		private function processView(view:IView) : void
		{
			if (view.as_config.alias == SETTINGS_WINDOW_LINKAGE)
			{
				var _settings:Object = getFramesLimiterSettings();
				var _callback:Function = setFramesLimiterSettings;
				new SettingsUI(view, _settings, _callback);
			}
		}
	}
}
