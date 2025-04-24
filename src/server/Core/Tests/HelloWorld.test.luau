local TestEZ = require(game:GetService("ReplicatedStorage"):WaitForChild("TestEZ"))

local function helloWorld()
    return "Hello, World!"
end

local function testHelloWorld()
    assert(helloWorld() == "Hello, World!")
end

TestEZ.TestBootstrap:run({
    TestEZ.TestSuite.new("HelloWorld Tests", {
        TestEZ.Test.new("Test HelloWorld function", testHelloWorld)
    })
})