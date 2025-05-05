package ludi.mind;

import ludi.commons.messaging.Topic;
import haxe.macro.ExprTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import ludi.mind.Component;

enum AppRootEvent {
    ComponentCreated(c: Component);
}

@:noCompletion
class _AppRootComponentImpl extends Component {
    var eventTopic: Topic<AppRootEvent> = new Topic<AppRootEvent>();

    public function onAppEvent(cb: AppRootEvent -> Void): String {
        return eventTopic.subscribe(cb);
    }

    function dispatchAppEvent(e: AppRootEvent) {
        eventTopic.notify(e);
    }

    public function removeAppEventListener(id: String) {
        eventTopic.unsubscribe(id);
    }
}

var AppRoot = new _AppRootComponentImpl();