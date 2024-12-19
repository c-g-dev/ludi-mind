

import ludi.mind.comp.Events;
import ludi.mind.comp.Events.EventHandler;
import ludi.mind.comp.Events.EventRef;
import ludi.mind.comp.Events.BasicEventSystem;
import ludi.mind.comp.Events.IEventSystem;
import utest.*;


class EventSystemTest extends Test {

    public function new() {
        super();
    }

    @:test 
    public function testSubscription(): Void {
        var eventSystem = new BasicEventSystem();

        var called = false;
        var handler = function(payload: Dynamic) {
            called = true;
            Assert.equals(payload, "test payload");
        };

        var eventUUID = eventSystem.on("test.event", handler);
        Assert.isTrue(eventSystem.isActive(eventUUID));

        eventSystem.dispatch("test.event", "test payload");
        Assert.isTrue(called);

        eventSystem.off(eventUUID);
        Assert.isFalse(eventSystem.isActive(eventUUID));
    }

    @:test 
    public function testPriority(): Void {
        var eventSystem = new BasicEventSystem();

        var result = [];

        var handler1 = function(payload: Dynamic) {
            result.push("handler1");
        };
        var handler2 = function(payload: Dynamic) {
            result.push("handler2");
        };
        var handler3 = function(payload: Dynamic) {
            result.push("handler3");
        };

        eventSystem.on("priority.event", handler1, 1);
        eventSystem.on("priority.event", handler2, 3);
        eventSystem.on("priority.event", handler3, 2);

        eventSystem.dispatch("priority.event", null);

        Assert.equals(result[0], "handler2");
        Assert.equals(result[1], "handler3");
        Assert.equals(result[2], "handler1");

    }

    @:test 
    public function testEventRef(): Void {
        var eventSystem = new BasicEventSystem();

        var called = false;
        var handler = function(payload: Dynamic) {
            called = true;
        };

        var ref = new EventRef({
            eventUUID: null,
            tag: "event.ref.test",
            priority: 0.0,
            cb: handler,
            system: eventSystem
        });

        ref.on();
        Assert.isTrue(eventSystem.isActive(ref.eventUUID));
        eventSystem.dispatch("event.ref.test", null);
        Assert.isTrue(called);

        called = false;
        ref.off();
        Assert.isFalse(eventSystem.isActive(ref.eventUUID));
        eventSystem.dispatch("event.ref.test", null);
        Assert.isFalse(called);
    }

    @:test 
    public function testEventHandler(): Void {
        var eventSystem = new BasicEventSystem();

        var called = false;
        var handler = function(payload: String) {
            called = true;
            Assert.equals(payload, "Hello World");
        };

        var eventHandler = new EventHandler<String>("event.handler.test", eventSystem);
        var ref = eventHandler.on(handler);
        eventHandler.dispatch("Hello World");
        Assert.isTrue(called);

        called = false;
        ref.off();
        eventHandler.dispatch("Hello Again");
        Assert.isFalse(called);
    }

    @:test 
    public function testOnly(): Void {
        var eventSystem = new BasicEventSystem();
        
        var result = [];

        var handler1 = function(payload: Dynamic) {
            result.push("handler1");
        };
        var handler2 = function(payload: Dynamic) {
            result.push("handler2");
        };

        var eventHandler = new EventHandler<Dynamic>("only.test", eventSystem);
        var ref1 = eventHandler.on(handler1);
        var ref2 = eventHandler.on(handler2);

        eventHandler.dispatch(null);
        Assert.equals(result[0], "handler1");
        Assert.equals(result[1], "handler2");

        result = [];

        var onlyRef = eventHandler.only(function(payload: Dynamic) {
            result.push("onlyHandler");
        });

        eventHandler.dispatch(null);
        Assert.equals(result[0], "onlyHandler");

        Assert.isFalse(eventSystem.isActive(ref1.eventUUID));
        Assert.isFalse(eventSystem.isActive(ref2.eventUUID));
    }

    @:test 
    public function testEventsMacro(): Void {
        var events = new Events();
        events.attach();

        var eventHandler = events.of("macro.event");

        var called = false;
        eventHandler.on(function(payload: Dynamic) {
            called = true;
        });

        eventHandler.dispatch(null);
        Assert.isTrue(called);
    }

}