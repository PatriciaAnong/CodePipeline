resource "aws_sns_topic" "pipeline_updates" {
  count = "${length("${var.subscriptions}")}"
  name  = "${var.name_prefix}_${var.name_suffix}_${var.environment}_pipeline-updates-topic"
}

resource "aws_sns_topic_subscription" "subscription" {
  count     = "${length("${var.subscriptions}")}"
  topic_arn = "${aws_sns_topic.pipeline_updates}"
  protocol  = "sms"
  endpoint  = "${element(var.subscriptions, count.index)}"
}

resource "aws_codepipeline" "codepipeline" {
  count    = "${var.approval == "True" ? "1" : "0"}"
  name     = "${var.name_prefix}-${var.name_suffix}-${var.environment}-pipeline"
  role_arn = "${var.role_arn}"

  artifact_store {
    location = "${var.tflambda_bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "${var.name_prefix}-${var.name_suffix}-${var.environment}-Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        S3Bucket             = "${var.tflambda_bucket}"
        S3ObjectKey          = "ArchiveItems.zip"
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name             = "${var.name_prefix}-${var.name_suffix}-${var.environment}-Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["plan"]

      configuration = {
        ProjectName = "${aws_codebuild_project.codepipeline_plan_project[count.index].name}"
      }
    }
  }


  stage {
    name = "Approval"


    action {
      name     = "${var.name_prefix}-${var.name_suffix}-${var.environment}-Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        NotificationArn = "${aws_sns_topic.pipeline_updates}"
      }
    }
  }

  stage {
    name = "Apply"

    action {
      name             = "${var.name_prefix}-${var.name_suffix}-${var.environment}-Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["plan"]
      output_artifacts = ["apply"]

      configuration = {
        ProjectName = "${aws_codebuild_project.codepipeline_apply_project[count.index].name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "${var.name_prefix}-${var.name_suffix}-${var.environment}-Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["apply"]
      version         = 1

      configuration = {
        BucketName  = "${var.tflambda_bucket}"
        Extract     = "true"
        ObjectKey   = "${var.name_prefix}-${var.name_suffix}-${var.environment}-Deploy"
      }
    }
  }
}

resource "aws_codebuild_project" "codepipeline_plan_project" {
  count         = "${var.approval == "True" ? "1" : "0"}"
  name          = "${var.name_prefix}-${var.name_suffix}-${var.environment}-plan-project"
  description   = "${var.environment}_codebuild_project"
  build_timeout = "5"
  service_role  = "${var.role_arn}"

  artifacts {
    type           = "CODEPIPELINE"
    namespace_type = "BUILD_ID"
    packaging      = "ZIP"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_FILES"
      value = "ArchiveItems/files"
    }

    environment_variable {
      name  = "TF_VERSION"
      value = "0.12.0"
    }

    environment_variable {
      name  = "name_prefix"
      value = "${var.name_prefix}"
    }

    environment_variable {
      name  = "name_suffix"
      value = "${var.name_suffix}"
    }

    environment_variable {
      name  = "environment"
      value = "${var.environment}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ArchiveItems/buildspec-plan.yml"
  }

  tags = {
    "Environment" = "${var.environment}"
    "Owner"       = "${var.name_prefix}"
    "Project"     = "${var.name_prefix}-${var.name_suffix}-${var.environment}"
  }
}

resource "aws_codebuild_project" "codepipeline_apply_project" {
  count         = "${var.approval == "True" ? "1" : "0"}"
  name          = "${var.name_prefix}-${var.name_suffix}-${var.environment}-apply-project"
  description   = "${var.environment}_codebuild_project"
  build_timeout = "5"
  service_role  = "${var.role_arn}"

  artifacts {
    type           = "CODEPIPELINE"
    namespace_type = "BUILD_ID"
    packaging      = "ZIP"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_FILES"
      value = "ArchiveItems/files"
    }

    environment_variable {
      name  = "TF_VERSION"
      value = "0.12.0"
    }

    environment_variable {
      name  = "name_prefix"
      value = "${var.name_prefix}"
    }

    environment_variable {
      name  = "name_suffix"
      value = "${var.name_suffix}"
    }

    environment_variable {
      name  = "environment"
      value = "${var.environment}"
    }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "ArchiveItems/buildspec-apply.yml"
  }

  tags = {
    "Environment" = "{var.environment}"
    "Owner"       = "$var.name_prefix}"
    "Project"     = "${var.name_prefix}-${var.name_suffix}-${var.environment}"
  }
}