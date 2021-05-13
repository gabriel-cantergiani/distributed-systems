struct = {
  name = "messageStruct",
  fields = {
    {name = "timeout", type = "int"},
    {name = "fromNode", type = "int"},
    {name = "toNode", type = "int"},
    {name = "type", type = "string"},
    {name = "value", type = "string"}
  }
}

interface = {
  name = "minhaInt",
  methods = {
    ReceiveMessage = {
      resulttype = "string",
      args = {
        {direction = "in", type = "messageStruct"}
      }
    },
    InitializeNode = {
      resulttype = "void",
      args = {
      }
    },
    PartitionNode ={
      resulttype = "void",
      args = {
      }
    },
    StopNode ={
      resulttype = "void",
      args = {
      }
    },
    ResumeNode ={
      resulttype = "void",
      args = {
      }
    },
    AppendEntries ={
      resulttype = "void",
      args = {
        {direction = "in", type = "int"}
      }
    },
    RequestVote ={
      resulttype = "string",
      args = {
        {direction = "in", type = "int"},
        {direction = "in", type = "int"}
      }
    },
    RequestVoteReply ={
      resulttype = "void",
      args = {
        {direction = "in", type = "string"}
      }
    },
    ApplyEntry ={
      resulttype = "string",
      args = {
        {direction= "in", type="int"}
      },
    },
    Snapshot ={
      resulttype = "void",
      args = {
      }
    },
  }
}
