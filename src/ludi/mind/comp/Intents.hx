package ludi.mind.comp;

import ludi.mind.Component.ComponentEvent;
import ludi.commons.util.UUID;
import haxe.ds.Option;
import ludi.mind.util.ExprAsArg;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

enum IntentRegistration<T> {
    Default(result: T): IntentRegistration<T>;
    Implement(result: T): IntentRegistration<T>;
    NotImplemented: IntentRegistration<T>;
}

class Intents extends Component {

    var system: IntentSystem;

    public override function on(e: ComponentEvent):Void {
        switch e {
            case Attach: {
                attach();
            }
            case Detach: {
                detach();
            }
            default:
        }
    }


    public function attach() {
        system = new IntentSystem();
    }

    public function detach() {}

    public macro function of(callingExpr: haxe.macro.ExprOf<Intents>, exprArg:haxe.macro.Expr):haxe.macro.Expr {

        switch ExprAsArg.parse(exprArg) {
            case String(str): {
                return macro @:privateAccess new ludi.mind.comp.Intents.IntentRequest<Dynamic, Dynamic>(${ExprAsArg.getField(callingExpr, "")}, $v{str});
            }
            case Type(info): {
                var underlyingType = Context.follow(info.type);
                var params = ExprAsArg.extractTypeParams(underlyingType);
                return ExprAsArg.withPrivateAccess(ExprAsArg.createConstructorExpr(macro: ludi.mind.comp.Intents.IntentRequest, params, [macro ${callingExpr}.system, macro $v{info.typeName}]));
            }
            case EnumInst(info): {
                var key = info.enumName + "." + info.enumInstanceName;
                return ExprAsArg.withPrivateAccess(ExprAsArg.createConstructorExpr(macro: ludi.mind.comp.Intents.IntentRequest, info.enumInstanceTypeParams, [macro ${callingExpr}.system, macro $v{key}]));
            }
            default: {
                throw "Unimplemented expr argument";
            }
        }
        return null;
    }

}

class IntentSystem  {
    var tag2Handlers: Map<String, Array<IntentHandler>> = new Map<String, Array<IntentHandler>>();

    public function new() { }

    public function register(tag: String, callback: (payload: Dynamic) -> IntentRegistration<Dynamic>, ?priority: Int = 0): Void {
        var handler: IntentHandler = {
            uuid: UUID.generate(),
            tag: tag,
            priority: priority,
            callback: callback
        };

        var handlers = tag2Handlers.get(tag);
        if (handlers == null) {
            handlers = [];
            tag2Handlers.set(tag, handlers);
        }
        handlers.push(handler);
        // Sort handlers by priority (higher priority first)
        handlers.sort(function(a, b) return b.priority - a.priority);
    }

    public function request(tag: String, payload: Dynamic): Option<Dynamic> {
        if (tag2Handlers.exists(tag)) {
            var handlers = tag2Handlers.get(tag);
            for (handler in handlers) {
                var result = handler.callback(payload);
                switch (result) {
                    case Default(v) | Implement(v): {
                        return v;
                    }
                    case NotImplemented:
                }
            }
        }
        return None;
    }

    public function chain(tag: String, payload: Dynamic): Option<Dynamic> {
        var result: Dynamic = null;
        if (tag2Handlers.exists(tag)) {
            var handlers = tag2Handlers.get(tag);
            for (handler in handlers) {
                switch handler.callback(payload) {
                    case Default(v) | Implement(v): {
                        result = v;
                    }
                    case NotImplemented:
                }
            }
        }

        if (result != null) {
            return Some(result);
        }
        return None;
    }
}

typedef IntentDef<T_Arg, T_Ret> = {};

typedef IntentHandler<T = Dynamic> = {
    uuid: String,
    tag: String,
    priority: Int,
    callback: (payload: Dynamic) -> IntentRegistration<T>
}

class IntentRequest<T_Arg, T_Ret> {
    var tag: String;
    var system: IntentSystem;

    public function new(system: IntentSystem, tag: String) {
        this.tag = tag;
        this.system = system;
    }

    public function request(payload: T_Arg): Option<T_Ret> {
        return cast system.request(tag, payload);
    }

    public function handle(payload: T_Arg, handle: T_Ret -> Void): Void {
        switch system.request(tag, payload) {
            case Some(v): {
                handle(cast v);
            }
            case None: {

            }
        }
        
    }

    public function chain(payload: T_Arg): T_Ret {
        return switch system.chain(tag, payload) {
            case Some(v): {
                return cast v;
            }
            case None: return null;
        };
    }

    public function register(cb: (payload: T_Arg) -> IntentRegistration<T_Ret>, ?priority: Int): Void {
        system.register(tag, cb, priority);
    }
}