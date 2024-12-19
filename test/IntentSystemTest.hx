
import utest.*;
import ludi.mind.comp.Intents.IntentSystem;
import ludi.mind.comp.Intents.IntentRequest;
import ludi.mind.comp.Intents;
import ludi.mind.comp.Intents.IntentRegistration;

class IntentSystemTest extends Test {

    public function new() {
        super();
    }

    @:before
    function setup() {
        // Setup code if necessary
    }

    @:test
    function testSimpleRequest() {
        var intentSystem = new IntentSystem();

        intentSystem.register("test.intent", function(tag, payload) {
            return Some("Handler Result");
        });

        var intentRequest = new IntentRequest<Dynamic, String>(intentSystem, "test.intent");

        var result = intentRequest.request(null);

        switch (result) {
            case Some(value):
                Assert.equals(value, "Handler Result");
            case None:
                Assert.fail("Expected Some, got None");
        }
    }

    @:test
    function testNoHandlers() {
        var intentSystem = new IntentSystem();

        var intentRequest = new IntentRequest<Dynamic, String>(intentSystem, "test.intent");

        var result = intentRequest.request(null);

        switch (result) {
            case Some(_):
                Assert.fail("Expected None, got Some");
            case None:
                Assert.isTrue(true);
        }
    }

    @:test
    function testMultipleHandlers() {
        var intentSystem = new IntentSystem();

        intentSystem.register("test.intent", function(tag, payload) {
            return None;
        });

        intentSystem.register("test.intent", function(tag, payload) {
            return Some("Second Handler Result");
        });

        var intentRequest = new IntentRequest<Dynamic, String>(intentSystem, "test.intent");

        var result = intentRequest.request(null);

        switch (result) {
            case Some(value):
                Assert.equals(value, "Second Handler Result");
            case None:
                Assert.fail("Expected Some, got None");
        }
    }

    @:test
    function testHandlerPriority() {
        var intentSystem = new IntentSystem();

        intentSystem.register("test.intent", function(tag, payload) {
            return Some("Low Priority Handler");
        }, 1);

        intentSystem.register("test.intent", function(tag, payload) {
            return Some("High Priority Handler");
        }, 5);

        var intentRequest = new IntentRequest<Dynamic, String>(intentSystem, "test.intent");

        var result = intentRequest.request(null);

        switch (result) {
            case Some(value):
                Assert.equals(value, "High Priority Handler");
            case None:
                Assert.fail("Expected Some, got None");
        }
    }

    @:test
    function testPayloadPassing() {
        var intentSystem = new IntentSystem();

        intentSystem.register("test.intent", function(tag, payload) {
            Assert.equals(payload, "Test Payload");
            return Some("Handler Result with Payload");
        });

        var intentRequest = new IntentRequest<String, String>(intentSystem, "test.intent");

        var result = intentRequest.request("Test Payload");

        switch (result) {
            case Some(value):
                Assert.equals(value, "Handler Result with Payload");
            case None:
                Assert.fail("Expected Some, got None");
        }
    }

    @:test
    function testHandleMethod() {
        var intentSystem = new IntentSystem();

        intentSystem.register("test.intent", function(tag, payload) {
            return Some(payload * 2);
        });

        var intentRequest = new IntentRequest<Int, Int>(intentSystem, "test.intent");

        var wasHandled = false;

        intentRequest.handle(21, function(result) {
            wasHandled = true;
            Assert.equals(result, 42);
        });

        Assert.isTrue(wasHandled);
    }

    @:test
    function testHandleMethodNotHandled() {
        var intentSystem = new IntentSystem();

        var intentRequest = new IntentRequest<Dynamic, Dynamic>(intentSystem, "test.intent");

        var wasHandled = false;

        intentRequest.handle(null, function(result) {
            wasHandled = true;
        });

        Assert.isFalse(wasHandled);
    }
}