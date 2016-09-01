#!/bin/sh

echo "Authenticating to Google Cloud..."
echo $DOCKER_KEYFILE > /key.json
gcloud auth activate-service-account "$GCLOUD_ACCOUNT" --key-file /key.json --project "$GCLOUD_PROJECT" -q

echo "Getting first level of repos..."
# first level of repos
im=$(gcloud alpha container images list --repository=eu.gcr.io/pq-infrastructure)
IFS=$'\n' read -rd '' -a images <<<"$im"

for image in "${images[@]}"
do
  if [ $image == "NAME" ]; then
    continue
  fi

  echo "Repo found: $image"
  # second level of repos
  im2=$(gcloud alpha container images list --repository=$image)

  IFS=$'\n' read -rd '' -a images2 <<<"$im2"
  for image2 in "${images2[@]}"
  do
    if [ $image2 == "NAME" ]; then
      continue
    fi
    echo "Sub-repo found: $image2"

    # tags
    ts=$(gcloud alpha container images list-tags $image2 | sort --reverse -k 3,3 | tail -n +6 | head -n -1)

    IFS=$'\n' read -rd '' -a tags <<<"$ts"
    for tag in "${tags[@]}"
    do
      t=$(echo "$tag" | awk '{print $2}')
      echo "Deleting $image2:$t"
      echo 'y' | gcloud alpha container images delete $image2:$t

    done

  done

done
