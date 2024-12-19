package ludi.mind.comp;

enum EventNetworkReport {
    Complete(tag: String);
    WaitFor(tag: String);
    Delay;
    StopPropagation;
}

class EventNetwork extends Component {
    private var handlers: Map<String, Array<() -> EventNetworkReport>> = new Map();
    private var rootHandler: () -> EventNetworkReport;
    
    public function new(?parent: Component) {
        super(parent);
    }
    
    public function when(event: String, handler: () -> EventNetworkReport): Void {
        if (!handlers.exists(event)) {
            handlers.set(event, []);
        }
        handlers.get(event).push(handler);
    }
    
    public function root(handler: () -> EventNetworkReport): Void {
        this.rootHandler = handler;
    }
    
    public function fire(tag: String = null): Void {
        var state: EventNetworkState = {
            firedEvents: new Map<String, Bool>(),
            eventsToProcess: [],
            delayedHandlers: [],
            waitingHandlers: new Map<String, Array<() -> EventNetworkReport>>()
        }
    
        if (tag == null) {
            // Execute root handler
            var report = rootHandler();
            processReport(report, null, state);
        } else {
            // Start by processing the given tag
            processComplete(tag, state);
        }
    
        // Main loop
        while (state.eventsToProcess.length > 0 || state.delayedHandlers.length > 0) {
            // Process events
            while (state.eventsToProcess.length > 0) {
                var eventTag = state.eventsToProcess.shift();
                var eventHandlers = [];
                if (handlers.exists(eventTag)) {
                    eventHandlers = handlers.get(eventTag).concat([]);
                }
                if (state.waitingHandlers.exists(eventTag)) {
                    eventHandlers = eventHandlers.concat(state.waitingHandlers.get(eventTag));
                    state.waitingHandlers.remove(eventTag);
                }
                var stopPropagation = false;
                for (handler in eventHandlers) {
                    if (stopPropagation) break;
                    var handlerReport = handler();
                    switch (handlerReport) {
                        case Complete(tag):
                            processComplete(tag, state);
                        case WaitFor(tag):
                            processWaitFor(tag, handler, state);
                        case Delay:
                            state.delayedHandlers.push(handler);
                        case StopPropagation:
                            stopPropagation = true;
                    }
                }
            }
            // Process delayed handlers
            if (state.delayedHandlers.length > 0) {
                var handlersToProcess = state.delayedHandlers.splice(0, state.delayedHandlers.length);
                for (handler in handlersToProcess) {
                    var handlerReport = handler();
                    processReport(handlerReport, handler, state);
                }
            }
        }
    }
    
    function processReport(report: EventNetworkReport, handler: () -> EventNetworkReport, state: EventNetworkState): Void {
        switch (report) {
            case Complete(tag):
                processComplete(tag, state);
            case WaitFor(tag):
                processWaitFor(tag, handler, state);
            case Delay:
                state.delayedHandlers.push(handler);
            case StopPropagation:
                // StopPropagation is not relevant here
        }
    }

    function processComplete(tag: String, state: EventNetworkState): Void {
        if (!state.firedEvents.exists(tag)) {
            state.firedEvents.set(tag, true);
            state.eventsToProcess.push(tag);
        }
    }

    function processWaitFor(tag: String, handler: () -> EventNetworkReport, state: EventNetworkState): Void {
        if (!state.firedEvents.exists(tag)) {
            if (!state.waitingHandlers.exists(tag)) {
                state.waitingHandlers.set(tag, []);
            }
            state.waitingHandlers.get(tag).push(handler);
        }
        // Else, the event has already fired, and the handler will not be retried
    }
}

typedef EventNetworkState = {
    firedEvents: Map<String, Bool>,
    eventsToProcess: Array<String>,
    delayedHandlers: Array<() -> EventNetworkReport>,
    waitingHandlers: Map<String, Array<() -> EventNetworkReport>>
}