[
  {
    "name": "api",
    "image": "${ecr_uri}",
    "cpu": 1,
    "memory": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
