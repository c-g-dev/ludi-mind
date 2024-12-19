package ludi.mind.comp;

import haxe.macro.TypeTools;
import haxe.macro.Expr;
import ludi.commons.util.UUID;

typedef Subscriber = {eventUUID: String, tag: String, priority: Float, cb: Dynamic -> Void, system: IEventSystem};

interface IEventSystem {
    public function on(tag: String, cb: Dynamic -> Void, ?priority: Float): String;
    public function off(eventUUID: String): Void;
    public function isActive(eventUUID: String): Bool;
    public function get(eventUUID: String): Subscriber;
    public function getAllOf(tag: String): Array<Subscriber>;
    public function all(): Array<Subscriber>;
    public function dispatch(tag: String, payload: Dynamic): Void;
}       

class BasicEventSystem implements IEventSystem {
    var uuidToSubscriber: Map<String, Subscriber>;
    var tagsToSubscribers: Map<String, Array<Subscriber>>;

    public function new() {
        uuidToSubscriber = new Map<String, Subscriber>();
        tagsToSubscribers = new Map<String, Array<Subscriber>>();
    }

    public function on(tag: String, cb: Dynamic -> Void, ?priority: Float): String {
        var eventUUID = UUID.generate();
        if(priority == null) priority = 0.0;
        var subscriber: Subscriber = {eventUUID: eventUUID, tag: tag, priority: priority, cb: cb, system: this};
        uuidToSubscriber.set(eventUUID, subscriber);

        var subscribers = tagsToSubscribers.get(tag);
        if (subscribers == null) {
            subscribers = [];
            tagsToSubscribers.set(tag, subscribers);
        }
        
        var inserted = false;
        for (i in 0...subscribers.length) {
            if (subscriber.priority > subscribers[i].priority) {
                subscribers.insert(i, subscriber);
                inserted = true;
                break;
            }
        }
        if (!inserted) {
            subscribers.push(subscriber);
        }

        return eventUUID;
    }

    public function off(eventUUID: String): Void {
        var subscriber = uuidToSubscriber.get(eventUUID);
        if (subscriber != null) {
            uuidToSubscriber.remove(eventUUID);
            var subscribers = tagsToSubscribers.get(subscriber.tag);
            if (subscribers != null) {
                subscribers = subscribers.filter(function(s) return s.eventUUID != eventUUID);
                if (subscribers.length == 0) {
                    tagsToSubscribers.remove(subscriber.tag);
                } else {
                    tagsToSubscribers.set(subscriber.tag, subscribers);
                }
            }
        }
    }

    public function isActive(eventUUID: String): Bool {
        return uuidToSubscriber.exists(eventUUID);
    }

    public function get(eventUUID: String): Subscriber {
        return uuidToSubscriber.get(eventUUID);
    }

    public function getAllOf(tag: String): Array<Subscriber> {
        var subscribers = tagsToSubscribers.get(tag);
        if (subscribers != null) {
            return subscribers.copy();
        }
        return [];
    }

    public function all(): Array<Subscriber> {
        var result = new Array<Subscriber>();
        for (subscriber in uuidToSubscriber.iterator()) {
            result.push(subscriber);
        }
        return result;
    }

    public function dispatch(tag: String, payload: Dynamic): Void {
        var subscribers = tagsToSubscribers.get(tag);
        if (subscribers != null) {
            var subscribersCopy = subscribers.copy();
            for (subscriber in subscribersCopy) {
                subscriber.cb(payload);
            }
        }
    }
}

@:forward
abstract EventRef(Subscriber){
    public function new(data: Subscriber) {
        this = data;
    }

    public function on(): Void {
        if(this.eventUUID == null || (this.eventUUID != null && !this.system.isActive(this.eventUUID))){
            var uuid = this.system.on(this.tag, this.cb, this.priority);
            this.eventUUID = uuid;
        }
    }
    
    public function off(): Void {
        if(this.eventUUID != null && this.system.isActive(this.eventUUID)){
            this.system.off(this.eventUUID);
        }
    }

    public function only(): Void {
        for(eachSubscriber in this.system.getAllOf(this.tag)){
            this.system.off(eachSubscriber.eventUUID);
        }
        abstract.on();
    }
}

class EventHandler<T> {

    var system: IEventSystem;
    var tag: String;

    public function new(tag: String, system: IEventSystem) {
        this.tag = tag;
        this.system = system;
    }
    public function on(cb: T -> Void, ?priority: Float): EventRef {
        var ref = new EventRef({
            eventUUID: null,
            tag: this.tag,
            priority: priority != null ? priority : 0.0,
            cb: cb,
            system: this.system
        });
        ref.on();
        return ref; 
    }

    public function only(cb: T -> Void, ?priority: Float): EventRef { 
        var ref = new EventRef({
            eventUUID: null,
            tag: this.tag,
            priority: priority != null ? priority : 0.0,
            cb: cb,
            system: this.system
        });
        ref.only();
        return ref;
    }

    public function dispatch(payload: T): Void { 
        system.dispatch(this.tag, payload);
    }
}

class Events extends Component {

    var system: IEventSystem;

    public function attach() {
        this.system = new BasicEventSystem();
    }

    public function detach() {}

    public function raw(tag: String): EventHandler<Dynamic> {
        return new EventHandler<Dynamic>(tag, this.system);
    }
    
    public macro function of(callingExpr: haxe.macro.ExprOf<Events>, exprArg:haxe.macro.Expr):haxe.macro.Expr {
        var typedExpr = haxe.macro.Context.typeExpr(exprArg);
        var exprType = typedExpr.t;

        switch (exprType) {
            case TInst(c, params):
                if (c.get().name == "String") {
                    return macro @:privateAccess new ludi.mind.comp.Events.EventHandler<Dynamic>(${exprArg}, ${callingExpr}.system);
                } else {
                    return macro @:privateAccess new ludi.mind.comp.EventHandler<Dynamic>(haxe.macro.ExprTools.toString(exprArg), ${callingExpr}.system);
                }
    
            case TEnum(e, params):
                var eiName = e.get().name;
                switch(exprArg.expr){
                    case EField(_, field, _): {
                        eiName = eiName + "." + field;
                    }
                    case EConst(CIdent(field)): {
                        eiName = eiName + "." + field;
                    }
                    default:
                }
    
                if (params.length > 0) {
                    var tparam = params[0];
                    var ct = TypeTools.toComplexType(tparam);
                    
                    var baseExpr: Expr = macro @:privateAccess new ludi.mind.comp.Events.EventHandler<Dynamic>($v{eiName}, ${callingExpr}.system);
                    switch(baseExpr.expr){
                        case ENew(t, params): {
                            t.params = [TPType(ct)];
                        }
                        default:
                    }
                    return baseExpr;
                } else {
                    return macro @:privateAccess new ludi.mind.comp.EventHandler<Dynamic>($v{eiName}, ${callingExpr}.system);
                }
    
            default:
                return macro @:privateAccess new ludi.mind.comp.EventHandler<Dynamic>(haxe.macro.ExprTools.toString(exprArg), ${callingExpr}.system);
        }
    }
    

}