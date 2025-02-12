package ludi.mind;

import ludi.mind.util.DefineModule.StaticModuleConfigurations;
import haxe.macro.TypeTools;
import ludi.mind.util.ModificationHandler.ModificationContext;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassType;
import ludi.mind.AppRoot;

enum ComponentEvent {
    Attach;
    Detach;
    ChildAttached(tag: String, comp: Component);
    Other(tag: String);
}

class Component<T = Dynamic> {
    var parent: Component;
    var components: Map<String, Component> = [];
    var modifications: ModificationContext;

    public function new(?parent: Component) { 
        if(parent != null){
            this.parent = parent; 
        }
        this.modifications = new ModificationContext(this);
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

    public macro function modify(callingExpr: ExprOf<Component>, expr: Expr): Expr {
        var typePath: TypePath;
        var callingType = Context.typeExpr(callingExpr).t;
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
                var compCt = getClassType(Context.getType("ludi.mind.Component"));

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
                
                
                if(isSubClassOfBaseClass(ct1, compCt)) {

                    var baseExpr: Expr =  macro @:privateAccess new ludi.mind.util.ModificationHandler<Dynamic>($v{clazzName}, macro ${callingExpr});
                    switch(baseExpr.expr){
                        case ENew(t, params): {
                            t.params = [TPType(TypeTools.toComplexType(Context.getType(clazzName)))];
                        }
                        default:
                    }
                    return baseExpr;
                }
                
                return macro @:privateAccess new ludi.mind.util.ModificationHandler<Dynamic>($v{clazzName}, macro ${callingExpr});
            }
            default:
                Context.error("Expected a class identifier", expr.pos);
                return macro null;
        }
    }
    
    public macro function with(callingExpr: ExprOf<Component>, expr: Expr): Expr {
        var typePath: TypePath;
        var callingType = Context.typeExpr(callingExpr).t;
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
                var compCt = getClassType(Context.getType("ludi.mind.Component"));
                var viewCt = getClassType(Context.getType("ludi.mind.View"));

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
                
                
                if(isSubClassOfBaseClass(ct1, compCt)) {

                    //check for component constraints if necessary
                    if(ct1.superClass != null && ct1.superClass.params.length > 0){
                        switch ct1.superClass.params[0] {
                            case TInst(t, params): {
                                var fullName = t.get().pack.join(".") + "." + t.get().name;
                                 if(fullName != "Dynamic") {
                                    
                                    //get callingExpr type as a classType
                                    switch callingType {
                                        case TInst(t, params): {
                                            
                                            var componentConstraintType = getClassType(Context.getType(fullName));
                                            var callingClassType = t.get();

                                            if(!isSameClass(callingClassType, componentConstraintType) && !isSubClassOfBaseClass(callingClassType, componentConstraintType)) {
                                                Context.error("Component constraint " + fullName + " required by " + clazzName + " not met by " + callingClassType.pack.join(".") + "." + callingClassType.name, expr.pos);
                                            }

                                        }
                                        default:
                                    }
                                }
                            }
                            default:
                        }
                    }


                    return macro @:privateAccess ${callingExpr}._compGet($v{clazzName}, $expr, false);
                }
                else if(isSubClassOfBaseClass(ct1, viewCt)) {
                    var newViewExpr = ludi.mind.util.ExprAsArg.createConstructorExpr(haxe.macro.TypeTools.toComplexType(Context.getType(clazzName)), [], []);
                    return macro @:privateAccess ${newViewExpr}.yields(${callingExpr});
                }
                
                return macro @:privateAccess ${callingExpr}._compGet($v{clazzName}, $expr, true);
            }
            default:
                Context.error("Expected a class identifier", expr.pos);
                return macro null;
        }
    }


    function _compGet<T>(tag: String, clazz: Class<T>, ?virtual: Bool): T {
        if(!components.exists(tag)){
            var inst: Component;
            if(virtual) {
                var data = Type.createInstance(clazz, []);
                inst = new VirtualComponent(this, data);
            }
            else{
                inst = cast Type.createInstance(clazz, [this]);
            }
            @:privateAccess AppRoot.dispatchAppEvent(ComponentCreated(inst));
            inst = modifications.alter(tag, inst);
            StaticModuleConfigurations.fire(tag, inst);
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