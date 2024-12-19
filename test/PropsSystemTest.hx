import ludi.mind.comp.Props;
import utest.*;
import ludi.mind.comp.Props.PropSystem;
import ludi.mind.comp.Props.PropHandler;
import ludi.mind.comp.Props.PropSubscriptionResult;

class PropSystemTest extends Test {
    public function new() {
        super();
    }

    @:before
    function setup() {
        // Setup code if needed
    }

    @:test
    function testSetGetProperty() {
        var propSystem = new PropSystem();
        propSystem.set("test.prop", "Hello World");
        var value = propSystem.get("test.prop");
        Assert.equals(value, "Hello World");
    }

    @:test
    function testSubscription() {
        var propSystem = new PropSystem();
        var called = false;
        propSystem.onChange("test.prop", function(oldValue, newValue) {
            called = true;
            Assert.isNull(oldValue);
            Assert.equals(newValue, 42);
            return PropSubscriptionResult.Retain;
        });
        propSystem.set("test.prop", 42);
        Assert.isTrue(called);
    }

    @:test
    function testSubscriptionRetainAndCancel() {
        var propSystem = new PropSystem();
        var callCount = 0;
        var subscriber = function(oldValue, newValue) {
            callCount++;
            if (callCount == 1) {
                return PropSubscriptionResult.Retain;
            } else {
                return PropSubscriptionResult.Cancel;
            }
        };
        propSystem.onChange("test.prop", subscriber);
        propSystem.set("test.prop", 1);
        propSystem.set("test.prop", 2);
        propSystem.set("test.prop", 3);
        Assert.equals(callCount, 2);
    }

    @:test
    function testPropHandlerGetSet() {
        var propSystem = new PropSystem();
        var propHandler = new PropHandler<String>("test.prop", propSystem);
        propHandler.set("Test Value");
        var value = propHandler.get();
        Assert.equals(value, "Test Value");
    }

    @:test
    function testPropHandlerSubscription() {
        var propSystem = new PropSystem();
        var propHandler = new PropHandler<Int>("test.prop", propSystem);
        var called = false;

        propHandler.onChange(function(oldValue, newValue) {
            called = true;
            Assert.isNull(oldValue);
            Assert.equals(newValue, 100);
            return PropSubscriptionResult.Retain;
        });

        propHandler.set(100);
        Assert.isTrue(called);
    }

    @:test
    function testPropHandlerSubscriptionCancel() {
        var propSystem = new PropSystem();
        var propHandler = new PropHandler<Int>("test.prop", propSystem);
        var callCount = 0;

        propHandler.onChange(function(oldValue, newValue) {
            callCount++;
            return PropSubscriptionResult.Cancel;
        });

        propHandler.set(1);
        propHandler.set(2);
        Assert.equals(callCount, 1);
    }

    @:test
    function testMultipleSubscribers() {
        var propSystem = new PropSystem();
        var callOrder = [];

        propSystem.onChange("test.prop", function(oldValue, newValue) {
            callOrder.push("subscriber1");
            return PropSubscriptionResult.Retain;
        });

        propSystem.onChange("test.prop", function(oldValue, newValue) {
            callOrder.push("subscriber2");
            return PropSubscriptionResult.Retain;
        });

        propSystem.set("test.prop", "Value");

        Assert.equals(callOrder.length, 2);
        Assert.equals(callOrder[0], "subscriber1");
        Assert.equals(callOrder[1], "subscriber2");
    }

    @:test
    function testSubscriberRemovalOnCancel() {
        var propSystem = new PropSystem();
        var subscriberCalls = [];

        var subscriber1 = function(oldValue, newValue) {
            subscriberCalls.push("subscriber1");
            return PropSubscriptionResult.Cancel;
        };

        var subscriber2 = function(oldValue, newValue) {
            subscriberCalls.push("subscriber2");
            return PropSubscriptionResult.Retain;
        };

        propSystem.onChange("test.prop", subscriber1);
        propSystem.onChange("test.prop", subscriber2);

        propSystem.set("test.prop", 1);
        propSystem.set("test.prop", 2);

        Assert.equals(subscriberCalls.length, 3);
        Assert.equals(subscriberCalls[0], "subscriber1");
        Assert.equals(subscriberCalls[1], "subscriber2");
        Assert.equals(subscriberCalls[2], "subscriber2");
    }

    @:test
    function testGetWithDefault() {
        var props = new Props();
        props.attach();
        var value = props.get("test.prop", "default value");
        Assert.equals(value, "default value");
        var value2 = props.get("test.prop");
        Assert.equals(value2, "default value");
    }

    @:test
    function testPropsSetGet() {
        var props = new Props();
        props.attach();
        props.set("test.prop", 123);
        var value = props.get("test.prop");
        Assert.equals(value, 123);
    }

    @:test
    function testPropsOfMacro() {
        var props = new Props();
        props.attach();
        var propHandler = props.of("test.prop");
        propHandler.set("Test Value");
        var value = propHandler.get();
        Assert.equals(value, "Test Value");
    }

}