job "workload" {
  datacenters = ["dc1"]
  type        = "batch"

  group "commands" {
    task "echo" {
      driver = "exec2"
      config {
        command = "echo"
        args    = ["Hello, world!"]
      }
    }
  }
}