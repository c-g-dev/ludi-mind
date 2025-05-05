package ludi.mind.util;

import ludi.mind.comp.EventNetwork;
import haxe.macro.Expr;


class StaticModuleConfigurations {
    private static var modules: Map<String, Array<ModuleDefinition>> = [];
    
    public static function configure(compTag: String, definition: ModuleDefinition) {
        if(modules.exists(compTag)) {
            modules.get(compTag).push(definition);
        }
        else {
            modules.set(compTag, [definition]);
        }
    }

    public static function fire(compTag: String, comp: Dynamic) {
        var eventNetwork = new EventNetwork();

        if(!modules.exists(compTag)) {
            return;
        }
        
        for (module in modules[compTag]) {

            if(module.dependency != null) {
                eventNetwork.when(module.dependency, function() {
                    for (injector in module.injectors) {
                        injector(comp);
                    }
                    return EventNetworkReport.Complete(module.name);
                });
            }
            else {
                eventNetwork.anytime(function() {
                    for (injector in module.injectors) {
                        injector(comp);
                    }
                    return EventNetworkReport.Complete(module.name);
                });
            }
        }

        eventNetwork.fire();
    }
}

typedef ModuleDefinition = {
    name: String,
    injectors: Array<Dynamic -> Void>,
    dependency: String,
}

class ModuleHandler<T> {
    var tag: String;

    public function new(tag: String) {
        this.tag = tag;
    }

    public function configure(options: Array<ModuleOption<T>>): Bool {
        var module = {
            name: null,
            injectors: [],
            dependency: null
        }

        for (option in options) {
            switch (option) {
                case ModuleOption.Name(name): {
                    module.name = name;   
                }
                case ModuleOption.Execute(handler):{
                    module.injectors.push(handler);
                }
                case ModuleOption.DependentOn(tag): {
                    module.dependency = tag;
                }
                case ModuleOption.ExecuteAs(tag, handler): {
                    module.name = tag;
                    module.injectors.push(handler);
                }
            }
        }

        StaticModuleConfigurations.configure(this.tag, module);

        return true;
    }

}

macro function DefineModule(comp: Expr): Expr {
    var ct = LudiMindUtils.getComponentType(comp);
    var name = LudiMindUtils.getComponentTag(comp);
    return macro @:privateAccess new ludi.mind.util.DefineModule.ModuleHandler<$ct>($v{name});
}

/*

var e = DefineModule(Level).configure([

]);

*/

/*
macro function DefineModule(comp: Expr, options: ExprOf<Array<ModuleOption>>): Expr {
    return macro @:privateAccess StaticModuleConfigurator.configure(LudiMindUtils.getComponentTag(comp), ${options});
}
*/

enum ModuleOption<T> {
    Name(name: String);
    Execute(handler: T -> Void);
    ExecuteAs(name: String, handler: T -> Void);
    DependentOn(tag: String);
}