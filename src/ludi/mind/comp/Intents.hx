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
    Default<K>(result: K): IntentRegistration<K>;
    Implement<K>(result: K): IntentRegistration<K>;
    NotImplemented: IntentRegistration<{}>;
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
        switch(exprArg.expr){
            case EConst(CIdent(ident)): {
                trace("ident: " + Context.getType(ident));
            }
            default:
        }

        switch ExprAsArg.parse(exprArg) {
            case String(str): {
                return macro @:privateAccess new system.lvl.v2.components.IntentRequest<Dynamic, Dynamic>(${ExprAsArg.getField(callingExpr, "")}, $v{str});
            }
            case Type(info): {
                var underlyingType = Context.follow(info.type);
                var params = ExprAsArg.extractTypeParams(underlyingType);
                return ExprAsArg.withPrivateAccess(ExprAsArg.createConstructorExpr(macro: system.lvl.v2.components.IntentRequest, params, [macro ${callingExpr}.system, macro $v{info.typeName}]));
            }
            case EnumInst(info): {
                var key = info.enumName + "." + info.enumInstanceName;
                return ExprAsArg.withPrivateAccess(ExprAsArg.createConstructorExpr(macro: system.lvl.v2.components.IntentRequest, info.enumInstanceTypeParams, [macro ${callingExpr}.system, macro $v{key}]));
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

    public function register(tag: String, callback: (tag: String, payload: Dynamic) -> Option<Dynamic>, ?priority: Int = 0): Void {
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
                var result = handler.callback(tag, payload);
                switch (result) {
                    case Some(value):
                        return Some(value);
                    case None:
                        // Continue to next handler
                }
            }
        }
        return None;
    }
}

typedef IntentDef<T_Arg, T_Ret> = {};

typedef IntentHandler<T = Dynamic> = {
    uuid: String,
    tag: String,
    priority: Int,
    callback: (tag: String, payload: Dynamic) -> Option<T>
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

    public function register(cb: T_Arg -> T_Ret): Void {}
}