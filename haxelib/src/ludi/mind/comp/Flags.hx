package ludi.mind.comp;

import ludi.mind.Component;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.Expr;


class FlagSystem {
    var data: Map<String, Bool> = new Map();
    var subscribers: Map<String, Array<(Bool) -> FlagSubscriptionResult>> = [];

    public function new() {
    }


    public function get(tag: String): Dynamic {
        if(!data.exists(tag)){
            data.set(tag, false);
        }
        return data.get(tag);
    }

    public function set(tag: String, item: Bool): Void {
        var oldValue = data.get(tag);
        data.set(tag, item);
        var list = subscribers.get(tag);
        if (list != null) {
            var i = 0;
            while (i < list.length) {
                var subscriber = list[i];
                var result = subscriber(item);
                switch result {
                    case Retain:
                        i++;
                    case Cancel:
                        list.splice(i, 1);
                }
            }
            if (list.length == 0) {
                subscribers.remove(tag);
            }
        }
    }

    public function onChange(tag: String, subscriber: (Bool) -> FlagSubscriptionResult): Void {
        var list = subscribers.get(tag);
        if (list == null) {
            list = [];
            subscribers.set(tag, list);
        }
        list.push(subscriber);
    }
}

class FlagHandler {
    var tag: String;
    var system: FlagSystem;

    public function new(tag: String, system: FlagSystem) {
        this.tag = tag;
        this.system = system;
    }

    public function check(): Bool {
        return cast system.get(this.tag);
    }

    public function set(flag: Bool): Void {
        system.set(this.tag, flag);
    }

    public function listen(subscriber: (Bool) -> FlagSubscriptionResult): Void {
        system.onChange(this.tag, function(flag: Bool): FlagSubscriptionResult {
            return subscriber(flag);
        });
        if(check()){
            subscriber(true);
        }
    }
}

enum FlagSubscriptionResult {
    Retain;
    Cancel;
}

class Flags extends Component {

    var system: FlagSystem;

    public function new(?parent: Component) {
        super(parent);
    }

    public override function on(e: ComponentEvent) {
        switch e {
            case Attach: {
                this.system = new FlagSystem();
            }
            default:
        }
    }

    public function get(key: String, ?def: Dynamic): Dynamic {
        var result = system.get(key);
        if(result == null && def != null){
            system.set(key, def);
            return def;
        }
        return result;
    }

    public function set(key: String, value: Dynamic): Void {
        system.set(key, value);
    }

    public macro function of(callingExpr: haxe.macro.ExprOf<Flags>, exprArg:haxe.macro.Expr):haxe.macro.Expr {
        
        var name = haxe.macro.ExprTools.toString(exprArg);
        var typedExpr = haxe.macro.Context.typeExpr(exprArg);

       // var ct: haxe.macro.ComplexType;

        switch(typedExpr.t) {
            case TInst(c, params): {
                var className = c.get().name;

                if (className == "String") {
                    // It's a string literal
                    return macro @:privateAccess new FlagHandler(${exprArg}, ${callingExpr}.system);
                }
            }
            case TEnum(e, params): {
                name = e.get().name;

                switch(exprArg.expr){
                    case EField(_, field, _): {
                        name = name + "." + field;
                    }
                    case EConst(CIdent(field)): {
                        name = name + "." + field;
                    }
                    default:
                }
            }
            case TFun(args, retType): {

            }
            default:
                // For other types, we'll use Dynamic
                return macro @:privateAccess new ludi.mind.comp.Flags.FlagHandler($v{name}, ${callingExpr}.system);
        }

        
        return macro @:privateAccess new ludi.mind.comp.Flags.FlagHandler($v{name}, ${callingExpr}.system);
    }

}