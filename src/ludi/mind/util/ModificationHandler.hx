package ludi.mind.util;

class ModificationHandler<T> {

    public var shouldCoalesce: Bool = false;
    public var host: Component;
    public var tag: String;

    var alterCallback: T -> T;

    public function new(tag: String, host: Component) {
        this.tag = tag;
        this.host = host;    
    }

    public function alter(cb: T -> T): ModificationHandler<T> {
        alterCallback = cb;
        @:privateAccess host.modifications.register(tag, this);
        return this;
    }

    public function coalesce(): Void {
        shouldCoalesce = true;
    }
}



class ModificationContext {

    var host: Component;
    var handlers: Map<String, Array<ModificationHandler<Dynamic>>>;

    public function new(host: Component) {
        this.host = host;
    }

    public function register(tag: String, handler: ModificationHandler<Dynamic>): Void {
        if(handlers == null){
            handlers = [];
        }
        if(!handlers.exists(tag)){
            handlers.set(tag, []);
        }
        handlers.get(tag).push(handler);
    }
    
    
    public function alter(tag: String, inst: Component, ?calledFromChild: Bool = false): Component {
        if(handlers == null){
            handlers = [];
        }
        if(handlers.exists(tag)){
            var handlerGroup = handlers.get(tag);

            for (handler in handlerGroup) {
                if(calledFromChild && handler.shouldCoalesce){
                    @:privateAccess if(handler.alterCallback != null){
                        @:privateAccess handler.alterCallback(inst);        
                    }
                }
                else if(!calledFromChild){
                    @:privateAccess if(handler.alterCallback != null){
                        @:privateAccess handler.alterCallback(inst);        
                    }
                }
            }

            @:privateAccess host.parent.modifications.alter(tag, inst, true);
        }
        return inst;
    }

}