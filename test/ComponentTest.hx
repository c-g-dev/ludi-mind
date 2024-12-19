
import utest.*;
import ludi.mind.Component;

class ComponentTest extends Test {
    public function new() {
        super();
    }

    @:before
    function setup() {
        // Setup if needed
    }

    @:test
    function testComponentInstantiation() {
        var parent = new Component();
        var child = parent.with(ComponentChild);
        Assert.notNull(child);
        Assert.isTrue(child is ComponentChild);
        @:privateAccess Assert.equals(child.parent, parent);
        @:privateAccess Assert.isTrue(parent.components.exists("ComponentChild"));
        @:privateAccess Assert.equals(parent.components.get("ComponentChild"), child);
    }

    @:test
    function testVirtualComponentInstantiation() {
        var parent = new Component();
        var child = parent.with(NonComponentClass);
        Assert.notNull(child);
        Assert.isTrue(child is NonComponentClass);
        @:privateAccess Assert.isTrue(parent.components.exists("NonComponentClass"));
        @:privateAccess var virtualComp: VirtualComponent = cast parent.components.get("NonComponentClass");
        Assert.isTrue(virtualComp is VirtualComponent);
        Assert.notNull(virtualComp);
        @:privateAccess Assert.equals(virtualComp.parent, parent);
        Assert.equals(virtualComp.data, child);
    }

    @:test
    function testMultipleComponentInstantiation() {
        var parent = new Component();
        var child1 = parent.with(ComponentChild);
        var child2 = parent.with(ComponentChild);
        Assert.notNull(child1);
        Assert.equals(child1, child2);
        @:privateAccess Assert.equals(parent.components.get("ComponentChild"), child1);
    }

    @:test
    function testAttachEvent() {
        var parent = new Component();
        var child = new TestComponent(parent);
        Assert.isTrue(child.wasAttached);
    }

    @:test
    function testChildAttachedEvent() {
        var parent = new TestComponent();
        var child = parent.with(ComponentChild);
        var testParent = cast parent, TestComponent;
        Assert.isTrue(testParent.childAttached);
        Assert.equals(testParent.attachedChildTag, "ComponentChild");
        Assert.equals(testParent.attachedChild, child);
    }

    @:test
    function testNonComponentWith() {
        var parent = new Component();
        var nonCompInstance = parent.with(NonComponentClass);
        Assert.notNull(nonCompInstance);
        Assert.isTrue(nonCompInstance is NonComponentClass);
    }

    @:test
    function testComponentHierarchy() {
        var root = new Component();
        var level1 = root.with(ComponentChild);
        var level2 = level1.with(ComponentChild);
        @:privateAccess Assert.equals(level1.parent, root);
        @:privateAccess Assert.equals(level2.parent, level1);
    }

    @:test
    function testEventPropagation() {
        var root = new TestComponent();
        var child = root.with(TestComponent);
        var grandChild = child.with(TestComponent);
        Assert.isTrue(child.wasAttached);
        Assert.isTrue(grandChild.wasAttached);
    }

    @:test
    function testVirtualComponentData() {
        var parent = new Component();
        var dataInstance = parent.with(NonComponentClass);
        Assert.notNull(dataInstance);
        @:privateAccess var virtualComp: VirtualComponent = cast parent.components.get("NonComponentClass");
        Assert.equals(virtualComp.data, dataInstance);
    }

    @:test
    function testComponentEvents() {
        var events = [];
        var parent = new ComponentWithEvents();
        parent.events = events;
        var child = parent.with(ComponentWithEvents);
        Assert.equals(events.length, 1);
        Assert.equals(events[0], "ChildAttached:ComponentWithEvents");
    }

    @:test
    function testDispose() {
        var events = [];
        var root = new ComponentWithEvents();
        var child = root.with(ComponentWithEvents);
        var grandChild = child.with(ComponentWithEvents);
        root.dispose();
        Assert.equals(root.events[root.events.length - 1], "Detach");
        Assert.equals(child.events[child.events.length - 1], "Detach");
        Assert.equals(grandChild.events[grandChild.events.length - 1], "Detach");
    }
}

class ComponentChild extends Component {
    public function new(?parent: Component) {
        super(parent);
    }
}

class NonComponentClass {
    public function new() {}
}

class TestComponent extends Component {
    public var wasAttached:Bool = false;
    public var childAttached:Bool = false;
    public var attachedChildTag:String;
    public var attachedChild:Component;

    override function on(event: ComponentEvent):Void {
        switch event {
            case Attach:
                wasAttached = true;
            case ChildAttached(tag, comp):
                childAttached = true;
                attachedChildTag = tag;
                attachedChild = comp;
            default:
        }
    }
}

class ComponentWithEvents extends Component {
    public var events:Array<String> = [];
    public function new(?parent: Component) {
        super(parent);
    }

    override function on(event: ComponentEvent):Void {
        switch event {
            case Attach:{
                events.push("Attach");
            }
            case ChildAttached(tag, comp): {
                events.push("ChildAttached:" + tag);
            }
            case Detach: {
                events.push("Detach");
            }
            default:
        }
    }
}