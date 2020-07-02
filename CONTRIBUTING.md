# Acceptance Testing Your Pull Request

## Initial Run

1. Go to the [Jenkins Pipeline for this module][1].
2. Click on 'Scan Repository Now'. Your PR will be added to the [Pull Requests View][2] or a new branch with a Jenkinsfile in it will be added to the default 'Branches' view.
3. Find your pull request number or branch and you can start a build of that pipeline by clicking the PR number or branch and then clicking 'Build Now' on the next page.

## Viewing Run Output

In the page you just loaded to click 'Build Now', a build history will be on the lower left of the page with a progress indicator on the current build number. Click into the build number and then click on 'Console Output'.

## Kicking Off Another Run

Jenkins will not detect when you have pushed new commits. You will need to go to pipelines page and click 'Build Now' to start another build.

If the only thing you want to do is make a slight change to the Jenkinsfile itself to see if something will work, or to add some `echo` debugging, you can click on `Reply` instead of `Rebuild` and a dialog will load allowing you to rebuild the same commit, but edit the Jenkinsfile manually prior to building. Your edits will affect only the current run you are about to kick off.

## Viewing Results

When a build of a PR or a branch is complete you can click on the build number and a 'Test Result' link will be available for you to browse through the test case hierarchy and view failed test details. You can also view the raw console output of any given build to look for more details of failed tests that way.

## Testing Community Pull Requests

This pipeline will not discover Pull Requests that come from community members that are not authorized collaberators on this repository. In order to test their PR's you have a couple options.

1. You can add their PR commits to a branch on your own fork, put up a PR from your own fork, and scan the repo again to find the PR originating from your own fork.
2. You can add a branch to the upstream copy of this repository that has the community members' commits on it, and then rescan the repo and run the build as a branch pipeline instead of a PR pipeline.

Either way please make sure to thoroughly review the commits you are adding to ensure that only authorized code can run. These pipelines are still running on internal infrastructure and we are entrusted with ensuring that no malicious code is being run.

[1]: https://cinext-jenkinsmaster-pipeline-prod-1.delivery.puppetlabs.net/view/PIE%20Team/job/pipeline_PIE_servicenow_cmdb_integration/
[2]: https://cinext-jenkinsmaster-pipeline-prod-1.delivery.puppetlabs.net/view/PIE%20Team/job/pipeline_PIE_servicenow_cmdb_integration/view/change-requests/