"""
SPDX-License-Identifier: LGPL-3.0-or-later
Copyright (c) 2022 Andrey Andruschyshyn
Copyright (c) 2022 Mikhail Paulyshka
"""

#
# Imports
#

# cpython
import logging

# WoT
import BigWorld
from account_helpers.settings_core.options import UserPrefsFloatSetting, UserPrefsBoolSetting
from constants import DEFAULT_LANGUAGE
from frameworks.wulf import WindowLayer
from gui.app_loader.settings import APP_NAME_SPACE
from gui.shared import g_eventBus, EVENT_BUS_SCOPE
from gui.shared.events import AppLifeCycleEvent
from gui.shared.personality import ServicesLocator
from gui.Scaleform.framework import g_entitiesFactories, ViewSettings, ScopeTemplates
from gui.Scaleform.framework.entities.BaseDAAPIComponent import BaseDAAPIComponent
from gui.Scaleform.framework.entities.View import View
from gui.Scaleform.framework.managers.loaders import SFViewLoadParams
from helpers import getClientLanguage, dependency
from Settings import g_instance as settingsInst
from skeletons.gui.shared.utils import IHangarSpace

# xfw.native
from xfw_native.python import XFWNativeModuleWrapper


#
# Exports
#

__all__ = ('xfw_module_init', 'xfw_is_module_loaded', )



#
# Constants
#

SETTINGS_LOBBY_LINKAGE = 'FramesLimiterSettingsLobbyHookUI'
SETTINGS_LOBBY_HOOK = 'frames_limiter_settings_lobby_hook.swf'

SETTINGS_BATTLE_INJECTOR = 'FramesLimiterSettingsBattleHookInjector'
SETTINGS_BATTLE_LINKAGE = 'FramesLimiterSettingsBattleHookUI'
SETTINGS_BATTLE_HOOK = 'frames_limiter_settings_battle_hook.swf'

SETTINGS_KEY_ENABLED = 'FramesLimiterEnabled'
SETTINGS_KEY_VALUE = 'FramesLimiterValue'

CPP_PACKAGE_NAME = 'poliroid.frames_limiter'
CPP_PACKAGE_FILENAME = 'frames_limiter.pyd'
CPP_MODULE_NAME = 'Frames_Limiter'
CPP_OBJECT_NAME = 'Frames_Limiter_Instance'

labeles_l10n = {
	'ru': {
		'checkboxText': 'Максимальная частота кадров',
		'tooltipText': "{HEADER}Максимальная частота кадров{/HEADER}{BODY}Задаётся максимальная частота кадров для 3D рендеринга.\nОграничение частоты кадров чаще всего используется для:\n\n• Cнижения нагрузки и как следствие нагрева с шумом у видеокарты.\n• Увеличение стабильности и плавности игрового процесса.\n• Увеличения автономности при использовании ноутбука.{/BODY}",
	},
	'en': {
		'checkboxText': 'Maximum frame rate',
		'tooltipText': "{HEADER}Maximum frame rate{/HEADER}{BODY}Sets the maximum frame rate for 3D rendering.\nFrame rate limitation is most often used for:\n\n• Reducing the load and as a consequence of heat and noise in the video card.\n• Increased stability and smooth gameplay.\n• Increase the battery life when using a laptop.{/BODY}",
	}
}



#
# Global Vers
#

logger = None
g_controller = None

MAX_FRAME_RATE = 0
REDUCED_FRAME_RATE = 0
LOCALIZATION = None



#
# Helpers
#

l10n = lambda key: LOCALIZATION.get(key, key)



#
# Classes
#

class FramesLimiterController(object):

	hangarSpace = dependency.descriptor(IHangarSpace)

	@property
	def framesLimit(self):
		if self._isBattle:
			return self._framesLimit
		return REDUCED_FRAME_RATE

	@framesLimit.setter
	def framesLimit(self, value):
		self._framesLimit = value

	def __init__(self):
		self.enabled = False
		self._framesLimit = 0
		self._isBattle = False
		self.__state = {}
		self.__native_module = XFWNativeModuleWrapper(CPP_PACKAGE_NAME, CPP_PACKAGE_FILENAME, CPP_MODULE_NAME)
		self.__native_object = getattr(self.__native_module, CPP_OBJECT_NAME)()

		# subscrive to lobby space load
		# for override ingame maxFrameRate value
		self.hangarSpace.onSpaceCreate += self.__onSpaceCreate

	def onAppInitialized(self, event):

		if event.ns == APP_NAME_SPACE.SF_BATTLE:
			app = ServicesLocator.appLoader.getApp(APP_NAME_SPACE.SF_BATTLE)
			if not app:
				return
			BigWorld.callback(0.0, lambda:app.loadView(SFViewLoadParams(SETTINGS_BATTLE_INJECTOR)))
			self._isBattle = True
			self.sync_native()

		if event.ns == APP_NAME_SPACE.SF_LOBBY:
			app = ServicesLocator.appLoader.getApp(APP_NAME_SPACE.SF_LOBBY)
			if not app:
				return
			app.loadView(SFViewLoadParams(SETTINGS_LOBBY_LINKAGE))
			self._isBattle = False
			self.sync_native()

	def sync_native(self):
		if self.isStateChanged('isBattle', self._isBattle):
			self._updateMaxFrameRate()
		if self.isStateChanged('enabled', self.enabled):
			self._updateMaxFrameRate(True)
			self.__native_object.set_hook_status(self.enabled)
		if self.isStateChanged('fps', self.framesLimit):
			self.__native_object.set_target_fps(self.framesLimit)

	def isStateChanged(self, name, value):
		if name not in self.__state:
			self.__state[name] = value
			return True
		if name in self.__state:
			if self.__state[name] != value:
				self.__state[name] = value
				return True
		return False

	def _updateMaxFrameRate(self, forced=False):
		maxFrameRate = REDUCED_FRAME_RATE
		if self._isBattle:
			maxFrameRate = MAX_FRAME_RATE
		if self.enabled:
			maxFrameRate = 1000
		if self.isStateChanged('maxFrameRate', maxFrameRate) or forced:
			BigWorld.wg_setMaxFrameRate(maxFrameRate)

	def __onSpaceCreate(self, *a, **kw):
		self._updateMaxFrameRate(True)

class FramesLimiterSettingsHolder:

	def getFramesLimiterSettings(self):
		tooltipText = l10n('tooltipText')
		checkboxText = l10n('checkboxText')
		return {
			'label': checkboxText,
			'toolTip': tooltipText,
			'enabled': g_controller.enabled,
			'value': g_controller._framesLimit,
		}

	def setFramesLimiterSettings(self, enabled, value):
		g_controller.enabled = bool(enabled)
		g_controller.framesLimit = int(value)
		g_controller.sync_native()

class FramesLimiterSettingsHookLobby(View, FramesLimiterSettingsHolder):

	def onFocusIn(self, alias):
		if self._isDAAPIInited():
			return False

class FramesLimiterSettingsHookBattle(BaseDAAPIComponent, FramesLimiterSettingsHolder):

	def onFocusIn(self, alias):
		if self._isDAAPIInited():
			return False

class UserPrefsIntSettings(UserPrefsFloatSetting):

	def getDefaultValue(self):
		return 0

	def _readValue(self, section):
		value = super(UserPrefsIntSettings, self)._readValue(section)
		if value is not None:
			return int(value)

	def _writeValue(self, section, value):
		if section is not None:
			return section.writeString(self.sectionName, str(int(value)))
		return False

	def _set(self, value):
		value = int(value)
		super(UserPrefsIntSettings, self)._set(value)



#
# XFW Loader
#

__is_module_loaded = False

def xfw_module_init():
	global logger
	global g_controller
	logger = logging.getLogger('FramesLimiter')
	g_controller = FramesLimiterController()

	g_entitiesFactories.addSettings(ViewSettings(SETTINGS_LOBBY_LINKAGE, FramesLimiterSettingsHookLobby, SETTINGS_LOBBY_HOOK, WindowLayer.WINDOW, None, ScopeTemplates.GLOBAL_SCOPE))
	g_entitiesFactories.addSettings(ViewSettings(SETTINGS_BATTLE_INJECTOR, View, SETTINGS_BATTLE_HOOK, WindowLayer.WINDOW, None, ScopeTemplates.GLOBAL_SCOPE))
	g_entitiesFactories.addSettings(ViewSettings(SETTINGS_BATTLE_LINKAGE, FramesLimiterSettingsHookBattle, None, WindowLayer.UNDEFINED, None, ScopeTemplates.DEFAULT_SCOPE))

	if not settingsInst.userPrefs.has_key(SETTINGS_KEY_ENABLED):
		settingsInst.userPrefs.write(SETTINGS_KEY_ENABLED, 'false')
	if not settingsInst.userPrefs.has_key(SETTINGS_KEY_VALUE):
		settingsInst.userPrefs.write(SETTINGS_KEY_VALUE, '60')

	ServicesLocator.settingsCore.options.settings += ((SETTINGS_KEY_ENABLED, UserPrefsBoolSetting(SETTINGS_KEY_ENABLED)), )
	ServicesLocator.settingsCore.options.indices[SETTINGS_KEY_ENABLED] = max(ServicesLocator.settingsCore.options.indices.values()) + 1
	ServicesLocator.settingsCore.options.settings += ((SETTINGS_KEY_VALUE, UserPrefsIntSettings(SETTINGS_KEY_VALUE)), )
	ServicesLocator.settingsCore.options.indices[SETTINGS_KEY_VALUE] = max(ServicesLocator.settingsCore.options.indices.values()) + 1

	g_controller.enabled = bool(ServicesLocator.settingsCore.getSetting(SETTINGS_KEY_ENABLED))
	g_controller.framesLimit = int(ServicesLocator.settingsCore.getSetting(SETTINGS_KEY_VALUE))

	g_eventBus.addListener(AppLifeCycleEvent.INITIALIZED, g_controller.onAppInitialized, scope=EVENT_BUS_SCOPE.GLOBAL)

	global MAX_FRAME_RATE
	global REDUCED_FRAME_RATE
	MAX_FRAME_RATE = settingsInst.engineConfig.readInt('renderer/maxFrameRate', 1000)
	REDUCED_FRAME_RATE = settingsInst.engineConfig.readInt('renderer/reducedFrameRate', 60)

	global LOCALIZATION
	client_language = getClientLanguage()
	if client_language in labeles_l10n:
		LOCALIZATION = labeles_l10n[client_language]
	elif DEFAULT_LANGUAGE in labeles_l10n:
		LOCALIZATION = labeles_l10n[DEFAULT_LANGUAGE]
	else:
		LOCALIZATION = labeles_l10n.get('en')

	global __is_module_loaded
	__is_module_loaded = True


def xfw_is_module_loaded():
	global __is_module_loaded
	return __is_module_loaded
