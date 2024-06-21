<?php

namespace MediaWiki\Hook;

use PathRouter;

/**
 * This is a hook handler interface, see docs/Hooks.md.
 * Use the hook name "WebRequestPathInfoRouter" to register handlers implementing this interface.
 *
 * @stable to implement
 * @ingroup Hooks
 */
interface WebRequestPathInfoRouterHook {
	/**
	 * This hook is called while building the PathRouter to parse the
	 * REQUEST_URI.
	 *
	 * @since 1.35
	 *
	 * @param PathRouter $router
	 * @return bool|void True or no return value to continue or false to abort
	 */
	public function onWebRequestPathInfoRouter( $router );
}
