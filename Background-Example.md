# Background execution using SwiftSyft

## iOS 13 Background Task Scheduler

Up until iOS 13, there were very limited ways to run background tasks on iOS. Background Task Scheduler was introduced in iOS 13 as a way to run background tasks used for maintenance (ex. cleaning a database), updating app content (ex. fetching data to display) or training a machine learning model. This tutorial will focus on using the task scheduler API to execute our federated learning tasks in the background.

## Requirements for Task Scheduler API

You need to configure your application to be able to **1.)** Enable `Background processing` background mode and **2.)** Register a background task identifier in your `Info.plist` file.

The full instructions for these steps can be found [here](https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler) under the **Configuring App for Background Tasks** section.

## MNIST Example

The full background task example using MNIST dataset can be found under the [`Example-Background`]() folder in the `AppDelegate.swift` file.

Here we'll focus on the differences with how `SwiftSyft` is used together with the background task API, namely the registration/scheduling of a background task and gracefully handling the completion/failure/cancellation of a task.

### Registering a background task

```swift
func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // Register a background task launch handler to execute whenever the system decides to run a
    // background tasks with our registered task identifier
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.openmined.background", using: DispatchQueue.global()) { task in

        self.executeSyftJob(backgroundTask: task)

    }

    ...

}
```

Here a closure is registered to be called whenever the system wants to execute a background task for your app. Inside this closure is where we'll be doing all our federated learning tasks like searching for and executing a federated learning cycle.

Make sure that the task identifier you use for this call is the same one you registered in your `Info.plist`. This call needs to be done inside `application(didFinishLaunchingWithOptions:)`.

### Submitting a background task request

Now we need to specify the background task request we need to submit to the system so it can be scheduled and run at a later time.

```swift
func scheduleTrainingJob() {
    do {
        let processingTaskRequest = BGProcessingTaskRequest(identifier: "com.openmined.background")
        processingTaskRequest.requiresExternalPower = true
        processingTaskRequest.requiresNetworkConnectivity = true
        try BGTaskScheduler.shared.submit(processingTaskRequest)
    } catch {
        print(error.localizedDescription)
    }
}
```

We specify a `BGProcessingTaskRequest` because we're going to execute a processing task, not an app refresh task (`BGAppRefreshTaskRequest`). Again, initialize it with the correct backgrond task identifier.

For the other options of the task requests, we need to specify that the state of the Phone should charging (`requiresExternalPower = true`) because that removes the CPU usage limits for processing tasks. Training an ML model can use up a lot of CPU and without removing the CPU limit by specifying that the phone should be charging, the background task can be completely stopped by the operating system.

Also, we need to specify network connectivity (`requiresNetworkConnectivity=true`) since we need to connect to PyGrid to register for a cycle and submit the results of our training.

### Handling Success/Failure/Cancelled background task

When executing a background task handler, you are given an instance of `BGTask` to use to inform iOS whether your background task has been completed/failed. It's also used to register a cancellation handler closure to inform you when you need to gracefully stop your processing task.

The main API to stop the background task is `BGTask.setTaskCompleted(success: Bool)`

Below is the list of instances where you will need to handle background task completion:

### Failure

**1.)** Any errors/exceptions from SwiftSyft:

URL for PyGrid is invalid
```swift
// Create a client with a PyGrid server URL
guard let syftClient = SyftClient(url: URL(string: "ws://127.0.0.1:5000")!) else {

    // Set background task failed if creating a client fails
    backgroundTask.setTaskCompleted(success: false)
    return
}
```

**2.)** Any errors/exceptions during training in `onReady` block:

```swift
self.syftJob?.onReady(execute: { plan, clientConfig,modelReport in

    try {

        .... Do some training using data

    } catch let error {
        backgroundTask.setTaskCompleted(success: false)
    }
}
```

**3.)** Any errors while communicating with PyGrid in the `onError` block:

```swift
// This is the error handler for any job exeuction errors like connecting to PyGrid
self.syftJob?.onError(execute: { error in

    backgroundTask.setTaskCompleted(success: false)

})
```

### Completion

The training cycle completes once you are able to report your model diffs to PyGrid:

```swift
self.syftJob?.onReady(execute: { plan, clientConfig, modelReport in

    ... Finish training using all your data

    // Generate diff data and report the final diffs as
    let diffStateData = try plan.generateDiffData()
    modelReport(diffStateData)

    // Finish the background task
    backgroundTask.setTaskCompleted(success: true)
}
```

### Cancellation

Your background task may be stopped at any time by iOS depending on the background time alloted by the system to your task. You should gracefully stop your task if it still isn't finished by then.

You can find out about a cancelled task by registering an expiration handler with a `BGTask` instance.

```swift
// If the background task has expired,
// we set this flag as true so that the training cycle
// can be informed and cancel any following cycles
backgroundTask.expirationHandler = {
    self.backgroundTaskCancelled = true
}
```

Here, `backgroundTaskCancelled` is a boolean flag we check during training to see if there is no more time left for the task. 

```swift
self.syftJob?.onReady(execute: { plan, clientConfig, modelReport in

    // Iterate through each batch of MNIST data and label
    for case let (batchData, labels) in zip(mnistData, labels) {

        // This checks if the background task has been cancelled. If it is, cancel the training cycle
        guard !self.backgroundTaskCancelled else {
            return
        }

        ...

    }
}
```

## Simulating a background task

Full instructions for simulating the launch and termination of a background task can be found [here](https://developer.apple.com/documentation/backgroundtasks/starting_and_terminating_tasks_during_development)

## Why not put all of this in the library?

The main restriction for us in using the background task scheduler is that the background execution handler needs to be registered in `application(didFinishLaunchingOptions:)` and nowhere else. Putting all of these background task registration code in the library will limit the use of the library to only during launch time and nowhere else.

For now, we found it best to let the library user handle all of the background task code implementation and configuration if they choose to use SwiftSyft in a background task.