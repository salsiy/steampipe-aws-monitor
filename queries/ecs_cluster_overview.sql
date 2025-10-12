SELECT 
  cluster_name,
  status,
  active_services_count,
  running_tasks_count,
  pending_tasks_count,
  registered_container_instances_count,
  region,
  tags ->> 'Environment' AS environment,
  tags ->> 'Project' AS project,
  tags ->> 'Owner' AS owner
FROM aws_ecs_cluster
ORDER BY cluster_name;

