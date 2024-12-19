package ludi.mind;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassType;

enum ComponentEvent {
    Attach;
    Detach;
    ChildAttached(tag: String, comp: Component);
    Other(tag: String);
}

class Component {
    var parent: Component;
    var components: Map<String, Component> = [];

    public function new(?parent: Component) { 
        if(parent != null){
            this.parent = parent; 
            this.on(Attach);
        }
        
    }
    function on(event: ComponentEvent):Void {}


    public function dispose():Void {
        for (key => value in this.components) {
            value?.dispose();
        }
        this.on(Detach);
        if(this.parent == null) return;
        @:privateAccess for (key => value in this.parent.components) {
            if (value == this) {
                this.parent.components.remove(key);
            }
        }
    }
    
    public macro function with(callingExpr: ExprOf<Component>, expr: Expr): Expr {
        var typePath: TypePath;
        // /var expr = exprs[1];
        switch expr.expr {
            case EConst(CIdent(clazzName)): {

                
                function getClassType(t: haxe.macro.Type):ClassType {
                    switch (t) {
                        case TInst(c, params):
                            return c.get();
                        default:
                            return null;
                    }
                }


                var ct1 = getClassType(Context.getType(clazzName));
                var ct2 = getClassType(Context.getType("ludi.mind.Component"));

                function isSameClass(a:ClassType, b:ClassType):Bool {
                    return (
                        a.pack.join(".") == b.pack.join(".")
                        && a.name == b.name
                    );
                }

                function isSubClassOfBaseClass(subClass:ClassType, baseClass:ClassType):Bool {
                    var cls = subClass;
                    while (cls != null && cls.superClass != null)
                    {
                        cls = cls.superClass.t.get();
                        if (isSameClass(baseClass, cls)) { return true; }
                    }
                    return false;
                }
                
                
                if(isSubClassOfBaseClass(ct1, ct2)) {
                    return macro @:privateAccess ${callingExpr}._compGet($v{clazzName}, $expr, false);
                }
                
                return macro @:privateAccess ${callingExpr}._compGet($v{clazzName}, $expr, true);
            }
            default:
                Context.error("Expected a class identifier", expr.pos);
                return macro null;
        }
    }


    function _compGet<T>(tag: String, clazz: Class<T>, ?virtual: Bool = false): T {
        if(!components.exists(tag)){
            var inst: Component;
            if(virtual) {
                var data = Type.createInstance(clazz, []);
                inst = new VirtualComponent(this, data);
            }
            else{
                inst = cast Type.createInstance(clazz, [this]);
            }
            components[tag] = inst;
            inst.on(Attach);
            this.on(ChildAttached(tag, inst));
        }
        if(!virtual) return cast components[tag];
        return cast (cast components[tag]: VirtualComponent).data;
    }

}


class VirtualComponent extends Component {
    public var data: Dynamic;
    public function new(parent: Component, data: Dynamic) {
        super(parent);
        this.data = data;
    }
}