# Objective

The objective of this example is to demonstrate how mimik ai technology integrates into an iOS application.


# Technical Prerequisites

Connect a **real iOS device** to your computer and select it as the target in  Xcode.

|**NOTE:** <br/><br/>Working with the iOS Simulator and the mimik Client Libraries entails some special consideration. For more more information about iOS Simulator support see [this tutorial](https://devdocs.mimik.com/tutorials/12-index#workingwithaniossimulator).|
|----------|

# Working with the Example Application and the mimik Client Library

The sections below describe the details of the steps required to fix the broken application code using the mimik Client Library. The mimik Client Library simplifies usage and provides straightforward interfaces to streamline mimOE startup, authorization, and microservice deployment at the edge.

# Getting the Source Code

The place to start is cloning the code from GitHub and loading it into Xcode.

Execute the following command to clone the example code from GitHub:

```
git clone https://github.com/mimikgit/mimik-ai-chat-example-iOS.git
```

# Adding the mimik Client Library components to the Application Source Code

As mentioned above, the mimik Client Library in a form of [EdgeCore](https://github.com/mimikgit/cocoapod-EdgeCore/releases) and [mimOE-SE-iOS-developer](https://github.com/mimikgit/cocoapod-mimOE-SE-iOS-developer/releases) (or [mimOE-SE-iOS](https://github.com/mimikgit/cocoapod-mimOE-SE-iOS/releases/)) cocoapods, needs to be made available to the application source code.

We have setup these references in the Podfile file at the project level for you.

**Step 1**:** From the command line run the following command to get to the Xcode project directory.

```
cd mimik-ai-chat-example-iOS/mimik-ai-chat-example/
```

**Step 2**:** From the command line run the following command (from inside the Xcode project directory).

```
pod install --repo-update
```

**Step 3:** Start editing the `Developer-ID-Token` file with:

```
open Developer-ID-Token
```

Go to the mimik Developer Portal and generate the Developer ID Token from an edge project. 

Once generated, copy the Developer ID Token and then paste it into `Developer-ID-Token` file, replacing any existing content already there. Save and Close the file.


**Step 4:** Continue by editing the `Developer-mimOE-License` file with:

```
open Developer-mimOE-License
```

Go to the mimik Developer Portal and copy the Developer mimOE License from there. 

Learn more about the process by reading this the [tutorial](https://devdocs.mimik.com/tutorials/02-index)

Once copied, paste the mimOE License into the `Developer-mimOE-License` file, replacing any existing content already there. Save and Close the file.


**Step 5:** From the command line run the following command in your project directory.

```
open Random-Number-Generator-Example.xcworkspace
```

Figure 2 below shows the command line instructions described previously, from `Steps 1-5`.

Now that references and configurations have been set, it's time to get into the business of programming to the microservice at the edge.