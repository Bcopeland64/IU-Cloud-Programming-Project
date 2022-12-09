#Define Configurations
resource "aws_launch_configuration" "launch_config" {
  name_prefix   = "dev_launch_config"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key_pair.key_name
  user_data     = file("userdata.tpl")
}

#Define Auto Scaling Group
resource "aws_autoscaling_group" "auto_scaling_group" {
  name_prefix               = "dev_auto_scaling_group"
  launch_configuration      = aws_launch_configuration.launch_config.name
  availability_zones        = data.aws_availability_zones.available_zones.names 
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 100
  health_check_type         = "EC2"
  force_delete              = true
  tag {
    key                 = "Name"
    value               = "dev_auto_scaling_group"
    propagate_at_launch = true
  }
}

#Define Auto Scaling Policy
resource "aws_autoscaling_policy" "auto_scaling_policy" {
  name                   = "dev_auto_scaling_policy"
  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

#Define desclaing cloud watch alarm
resource "aws_cloudwatch_metric_alarm" "cloudwatch_descale_alarm" {
  alarm_name          = "dev_cloudwatch_descale_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.auto_descale_policy.arn]
  actions_enabled     = true
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.auto_scaling_group.name
  }
}

#Define descaling policy
resource "aws_autoscaling_policy" "auto_descale_policy" {
  name                   = "dev_auto_descale_policy"
  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  policy_type            = "SimpleScaling"
}



