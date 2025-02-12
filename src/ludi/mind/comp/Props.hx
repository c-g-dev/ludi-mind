package ludi.mind.comp;

import haxe.macro.Expr;
import ludi.mind.Component.ComponentEvent;

class PropSystem {
    var data: Map<String, Dynamic> = new Map();
    var subscribers: Map<String, Array<(Dynamic, Dynamic) -> PropSubscriptionResult>> = new Map();

    public function new() {
    }


    public function get(tag: String): Dynamic {
        return data.get(tag);
    }

    public function set(tag: String, item: Dynamic): Void {
        var oldValue = data.get(tag);
        data.set(tag, item);
        var list = subscribers.get(tag);
        if (list != null) {
            var i = 0;
            while (i < list.length) {
                var subscriber = list[i];
                var result = subscriber(oldValue, item);
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

    public function onChange(tag: String, subscriber: (Dynamic, Dynamic) -> PropSubscriptionResult): Void {
        var list = subscribers.get(tag);
        if (list == null) {
            list = [];
            subscribers.set(tag, list);
        }
        list.push(subscriber);
    }
}

class PropHandler<T> {
    var tag: String;
    var system: PropSystem;

    public function new(tag: String, system: PropSystem) {
        this.tag = tag;
        this.system = system;
    }

    public function get(): T {
        return cast system.get(this.tag);
    }

    public function set(prop: T): Void {
        system.set(this.tag, prop);
    }

    public function onChange(subscriber: (Null<T>, T) -> PropSubscriptionResult): Void {
        system.onChange(this.tag, function(oldObj: Dynamic, newObj: Dynamic): PropSubscriptionResult {
            return subscriber(cast oldObj, cast newObj);
        });
    }
}

enum PropSubscriptionResult {
    Retain;
    Cancel;
}

class Props extends Component {

    var system: PropSystem;

    public function new(?parent: Component) {
        super(parent);
    }

    public override function on(e: ComponentEvent) {
        switch e {
            case Attach: {
                this.system = new PropSystem();
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

    public macro function of(callingExpr: haxe.macro.ExprOf<Props>, exprArg:haxe.macro.Expr):haxe.macro.Expr {
        
        var name = haxe.macro.ExprTools.toString(exprArg);
        var typedExpr = haxe.macro.Context.typeExpr(exprArg);

        var ct: haxe.macro.ComplexType;

        switch(typedExpr.t) {
            case TInst(c, params):
                var className = c.get().name;

                if (className == "String") {
                    // It's a string literal
                    return macro @:privateAccess new ludi.mind.comp.Props.PropHandler<Dynamic>(${exprArg}, ${callingExpr}.system);
                }

                // For other classes, we use their type
                ct = haxe.macro.TypeTools.toComplexType(typedExpr.t);

            case TEnum(e, params):
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

                if (params.length > 0) {
                    var tparam = params[0];
                    ct = haxe.macro.TypeTools.toComplexType(tparam);
                } else {
                    ct = haxe.macro.TypeTools.toComplexType(typedExpr.t);
                }

            case TFun(args, retType):
                switch (retType) {
                    case TEnum(e, params):
                        if (params.length > 0) {
                            var tparam = params[0];
                            ct = haxe.macro.TypeTools.toComplexType(tparam);
                        } else {
                            ct = haxe.macro.TypeTools.toComplexType(retType);
                        }
                    default:
                        ct = haxe.macro.TypeTools.toComplexType(retType);
                }

            default:
                // For other types, we'll use Dynamic
                return macro @:privateAccess new ludi.mind.comp.Props.PropHandler<Dynamic>($v{name}, macro ${callingExpr}.system);
        }

        return macro @:privateAccess new ludi.mind.comp.Props.PropHandler<$ct>($v{name}, ${callingExpr}.system);
    }

}