#!/usr/bin/env sh

############### Host   ##############################
HOST=$(hostname)
echo "Current host is: $HOST"

# Automatic check the host and configuration
case $HOST in
"alpha")
    PYTHON="/home/elliot/anaconda3/envs/pytorch041/bin/python" # python environment path
    TENSORBOARD='/home/elliot/anaconda3/envs/pytorch041/bin/tensorboard' # tensorboard environment path
    data_path='/home/elliot/data/imagenet' # dataset path
    ;;
"scalar"*)
    /home/scalar/anaconda3/condabin/conda activate bfa
    PYTHON="/home/scalar/anaconda3/envs/bfa/bin/python"
    TENSORBOARD="/home/scalar/anaconda3/envs/bfa/bin/tensorboard"
    data_path="/home/scalar/source/BFA/datasets/ImageNet/ILSVRC/Data/CLS-LOC"
    ;;
esac

DATE=`date +%Y-%m-%d`

if [ ! -d "$DIRECTORY" ]; then
    mkdir ./save/${DATE}/
fi

############### Configurations ########################
enable_tb_display=true # enable tensorboard display
model=resnet18_quan
dataset=imagenet
epochs=50
train_batch_size=256
test_batch_size=256
optimizer=Adam

label_info=idx_11

tb_path=./save/${DATE}/${dataset}_${model}_${epochs}_${optimizer}_${label_info}/tb_log  #tensorboard log path

############### Neural network ############################
{
$PYTHON main.py --dataset ${dataset} \
    --data_path ${data_path}   \
    --arch ${model} --save_path ./save/${DATE}/${dataset}_${model}_${epochs}_${optimizer}_${label_info} \
    --epochs ${epochs} --learning_rate 0.0001 \
    --optimizer ${optimizer} \
	--schedule 30 40 45  --gammas 0.2 0.2 0.5 \
    --test_batch_size ${test_batch_size} \
    --attack_sample_size ${train_batch_size} \
    --workers 8 --ngpu 1 --gpu_id 0 \
    --print_freq 100 --decay 0.000005 \
    # --momentum 0.9 \
    # --evaluate
} &
############## Tensorboard logging ##########################
{
if [ "$enable_tb_display" = true ]; then 
    sleep 30 
    wait
    $TENSORBOARD --logdir $tb_path  --port=6006
fi
} &
{
if [ "$enable_tb_display" = true ]; then
    sleep 45
    wait
    case $HOST in
    "Hydrogen")
        firefox http://0.0.0.0:6006/
        ;;
    "alpha")
        google-chrome http://0.0.0.0:6006/
        ;;
    "scalar"*)
        google-chrome -incognito http://0.0.0.0:6006/
        ;;
    esac
fi 
} &
wait