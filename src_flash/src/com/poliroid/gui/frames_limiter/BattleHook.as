package com.poliroid.gui.frames_limiter
{

	import flash.events.Event;

	import net.wg.data.constants.generated.LAYER_NAMES;
	import net.wg.gui.components.containers.MainViewContainer;
	import net.wg.gui.events.ViewStackEvent;
	import net.wg.gui.lobby.settings.GameSettings;
	import net.wg.gui.lobby.settings.GameSettingsContent;
	import net.wg.gui.lobby.settings.SettingsWindow;
	import net.wg.infrastructure.events.LoaderEvent;
	import net.wg.infrastructure.interfaces.IManagedContent;
	import net.wg.infrastructure.interfaces.ISimpleManagedContainer;
	import net.wg.infrastructure.interfaces.IView;
	import net.wg.infrastructure.managers.impl.ContainerManagerBase;

	import mods.common.BattleDisplayable;

	import flash.display.MovieClip;
	import flash.events.MouseEvent;

	import com.poliroid.gui.frames_limiter.SettingsUI;

	public class BattleHook extends BattleDisplayable
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
		
		private function onViewLoaded(_event:LoaderEvent) : void
		{
			processView(_event.view as IView);
		}

		private function processView(view:IView) : void
		{
			if (view.as_config.alias == SETTINGS_WINDOW_LINKAGE)
			{
				var settings:Object = getFramesLimiterSettings();
				var callback:Function = setFramesLimiterSettings;
				new SettingsUI(view, settings, callback);
			}
		}
	}
}