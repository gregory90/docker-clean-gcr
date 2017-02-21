#!/bin/bash

echo "Authenticating to Google Cloud..."
echo $DOCKER_KEYFILE_BASE64 | base64 --decode > /key.json
gcloud auth activate-service-account --key-file /key.json --project "$GCLOUD_PROJECT" -q

echo "Getting first level of repos..."
# first level of repos
im=$(gcloud beta container images list --repository=eu.gcr.io/pq-infrastructure)
IFS=$'\n' read -rd '' -a images <<<"$im"

for image in "${images[@]}"
do
  if [ $image == "NAME" ]; then
    continue
  fi

  echo "Repo found: $image"
  # second level of repos
  im2=$(gcloud beta container images list --repository=$image)

  IFS=$'\n' read -rd '' -a images2 <<<"$im2"
  for image2 in "${images2[@]}"
  do
    if [ $image2 == "NAME" ]; then
      continue
    fi
    echo "Sub-repo found: $image2"

    # tags
    ts=$(gcloud beta container images list-tags $image2 | sort --reverse -k 3,3 | tail -n +6 | head -n -1)

    IFS=$'\n' read -rd '' -a tags <<<"$ts"
    for tag in "${tags[@]}"
    do
      t=$(echo "$tag" | awk '{print $1}')
      echo "Deleting $image2@sha256:$t"
      echo 'y' | gcloud beta container images delete $image2@sha256:$t -q

    done

  done

done
