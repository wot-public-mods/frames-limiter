﻿package me.poliroid.gui.frames_limiter
{
	import mods.common.AbstractComponentInjector;
	import me.poliroid.gui.frames_limiter.BattleHook;

	public class BattleInjector extends AbstractComponentInjector 
	{
		override protected function onPopulate() : void
		{
			componentName = "FramesLimiterSettingsBattleHookUI";
			componentUI = BattleHook;
			super.onPopulate();
		}
	}
}
