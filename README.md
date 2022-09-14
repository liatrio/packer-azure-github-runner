# Packer Custom Image for Azure GitHub Self Hosted Runners

This should build a custom Linux image that can be pushed to Azure Community Gallery.

# Release Instructions

CI is set to run when a tag is created in trunk. Increment the version number of the previous tag to release. Use SemVer (vX.X.X). The CI run will upload the image with version X.X.X to match their image versioning requirements, Major(int).Minor(int).Patch(int) .