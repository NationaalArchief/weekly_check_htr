#!/bin/bash

if [ -z $1 ]; then echo "please provide path to images and pagexml to be converted. The pageXML must be one level deeper than the images in a directory called \"page\"" && exit 1; fi;
if [ -z $2 ]; then echo "please provide output path" && exit 1; fi;
if [ -z $3 ]; then
        echo "setting numthreads=4"
        numthreads=4
else 
        numthreads=$3
        echo $numthreads
fi;

#directory containing images and pagexml. The pageXML must be one level deeper than the images in a directory called "page"
inputdir=$1/
outputdir=$2/
filelist=$outputdir/training_all.txt
filelisttrain=$outputdir/training_all_train.txt
filelistval=$outputdir/training_all_val.txt
longlines=$outputdir/longlines.txt

echo $inputdir
echo $outputdir
echo $filelist
echo $filelisttrain
echo $filelistval
echo $longlines

find $inputdir -name '*.done' -exec rm {} \;

mkdir -p $outputdir
echo "inputfiles: " `find $inputdir|wc -l`


#echo /home/rutger/src/opencvtest2/agenttesseract/target/appassembler/bin/MinionCutFromImageBasedOnPageXMLNew -input_path $inputdir -outputbase $outputdir -channels 4 -output_type png -write_text_contents -threads $numthreads
#/home/rutger/src/opencvtest2/agenttesseract/target/appassembler/bin/MinionCutFromImageBasedOnPageXMLNew -input_path $inputdir -outputbase $outputdir -channels 4 -output_type png -write_text_contents -threads $numthreads
echo docker run --rm -v $inputdir/:$inputdir/ -v $outputdir:$outputdir dockeranalyzerwebservice_analyzerwebservice /src/agenttesseract/target/appassembler/bin/MinionCutFromImageBasedOnPageXMLNew -input_path $inputdir -outputbase $outputdir -channels 4 -output_type png -write_text_contents -threads $numthreads
docker run --rm -v $inputdir/:$inputdir/ -v $outputdir:$outputdir docker.loghi-tooling \
  /src/loghi-tooling/minions/target/appassembler/bin/MinionCutFromImageBasedOnPageXMLNew -input_path $inputdir -outputbase $outputdir -channels 4 -output_type png -write_text_contents -threads $numthreads

echo "outputfiles: " `find $outputdir|wc -l`


count=0
> $filelist
for input_path in $(find $outputdir -name '*.png');
do
        filename=$(basename -- "$input_path")
        filename="${filename%.*}"
        base="${input_path%.*}"
        text=`cat $base.box|colrm 2|tr -d '\n'`
        echo -e "$input_path\t$text" >>$filelist
done

 
grep -E '.{130,}' $filelist > $longlines

shuf $longlines> shuffled
head -n 100 shuffled > $filelisttrain #Here the change needs to be made if you want to perform this with other values. 
tail -n +101 shuffled >$filelistval #You need to change this value to 1 higher hten you set in the head. 

rm shuffled

# Define the input file, target directory, and output directory
input_file= $filelisttrain
target_directory= $outputdir
output_directory= ~/data/train_7_output

# Read each line in the input file
while IFS= read -r filename; do
  # Check if both .txt and .png files exist with the given filename
  if [ -f "$target_directory/$filename.txt" ] && [ -f "$target_directory/$filename.png" ]; then
    # Copy the files to the output directory
    cp "$target_directory/$filename.txt" "$output_directory"
    cp "$target_directory/$filename.png" "$output_directory"
    echo "Copied files: $filename.txt and $filename.png"
  fi
done < "$input_file"

