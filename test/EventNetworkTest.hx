import utest.*;
import ludi.mind.comp.EventNetwork;
import ludi.mind.comp.EventNetwork.EventNetworkReport;

class EventNetworkTest extends Test {
    public function new() {
        super();
    }

    @:before
    function setup() {
        // Setup code if needed
    }

    @:test
    function testBasicEventFiring() {
        var network = new EventNetwork();
        var called = false;
        network.when("test.event", function() {
            called = true;
            return EventNetworkReport.Complete("eventZ");
        });
        network.fire("test.event");
        Assert.isTrue(called);
    }

    @:test
    function testCompleteEvent() {
        var network = new EventNetwork();
        var calledA = false;
        var calledB = false;

        network.when("eventA", function() {
            calledA = true;
            return EventNetworkReport.Complete("eventB");
        });

        network.when("eventB", function() {
            calledB = true;
            return EventNetworkReport.Complete("eventZ");
        });

        network.fire("eventA");

        Assert.isTrue(calledA);
        Assert.isTrue(calledB);
    }

    @:test
    function testWaitForEvent() {
        var network = new EventNetwork();
        var calledA = false;
        var calledB = false;

        network.when("eventA", function() {
            calledA = true;
            return EventNetworkReport.WaitFor("eventB");
        });

        network.when("eventB", function() {
            calledB = true;
            return EventNetworkReport.Complete("eventZ");
        });

        network.fire("eventA");

        Assert.isTrue(calledA);
        Assert.isFalse(calledB);

        network.fire("eventB");

        Assert.isTrue(calledB);
    }

    @:test
    function testDelayedHandler() {
        var network = new EventNetwork();
        var callOrder = [];
        var handlerACallCount = 0;

        network.when("eventA", function() {
            handlerACallCount++;
            callOrder.push("handlerA_call" + handlerACallCount);
            if (handlerACallCount == 1) {
                return EventNetworkReport.Delay;
            } else {
                return EventNetworkReport.Complete("eventZ");
            }
        });

        network.when("eventA", function() {
            callOrder.push("handlerB");
            return EventNetworkReport.Complete("eventZ");
        });

        network.fire("eventA");

        Assert.equals(callOrder.length, 3);
        Assert.equals(callOrder[0], "handlerA_call1");
        Assert.equals(callOrder[1], "handlerB");
        Assert.equals(callOrder[2], "handlerA_call2");
    }


    @:test
    function testStopPropagation() {
        var network = new EventNetwork();
        var callOrder = [];

        network.when("eventA", function() {
            callOrder.push("handlerA");
            return EventNetworkReport.StopPropagation;
        });

        network.when("eventA", function() {
            callOrder.push("handlerB");
            return EventNetworkReport.Complete("eventB");
        });

        network.fire("eventA");

        Assert.equals(callOrder.length, 1);
        Assert.equals(callOrder[0], "handlerA");
    }


    @:test
    function testWaitingHandlersFiredAfterEvent() {
        var network = new EventNetwork();
        var calledHandler1 = false;
        var calledHandler2 = false;

        network.when("eventA", function() {
            return EventNetworkReport.WaitFor("eventB");
        });

        network.when("eventA", function() {
            calledHandler1 = true;
            return EventNetworkReport.Complete("eventZ");
        });

        network.when("eventB", function() {
            calledHandler2 = true;
            return EventNetworkReport.Complete("eventZ");
        });

        network.fire("eventA");

        Assert.isTrue(calledHandler1);
        Assert.isFalse(calledHandler2);

        network.fire("eventB");

        Assert.isTrue(calledHandler2);
        Assert.isTrue(calledHandler1);
    }

    @:test
    function testEventDoesNotReFire() {
        var network = new EventNetwork();
        var callCount = 0;

        network.when("eventA", function() {
            callCount++;
            return EventNetworkReport.Complete("eventA");
        });

        network.fire("eventA");

        Assert.equals(callCount, 1);
    }

}