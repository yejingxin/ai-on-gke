#!/bin/bash

mode=$1


case $mode in
    init)
        echo "get GKE cluster credentials"
        gcloud container clusters get-credentials ${cluster_name} \
        --region ${region} --project ${project_id}

        echo "install leaderworkerset"
        VERSION=v0.3.0
        kubectl apply --server-side -f https://github.com/kubernetes-sigs/lws/releases/download/$VERSION/manifests.yaml
    ;;
    up)
        echo "Start notebook service.."
        kubectl apply -f preprov-filestore.yaml
        kubectl apply -f deployment.yaml
        kubectl apply -f service.yaml
        ;;
    down)
        echo "Tear down notebook service.."
        kubectl delete -f preprov-filestore.yaml
        kubectl delete -f deployment.yaml
        kubectl delete -f service.yaml
        ;;
    reload)
        echo "Reload notebook service.."    
        kubectl delete -f preprov-filestore.yaml
        kubectl delete -f deployment.yaml
        kubectl delete -f service.yaml
        kubectl apply -f preprov-filestore.yaml
        kubectl apply -f deployment.yaml
        kubectl apply -f service.yaml
        echo $mode
        ;;
    portforward)
        echo "connect colab to http://127.0.0.1:8888/lab?token=${jupyter_token}"
        kubectl port-forward service/ipp 8888:8888
        ;;
    *)
    echo -n "unknown"
    ;;
esac