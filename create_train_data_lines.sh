#!/bin/bash
VERSION=1.3.1

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
inputdir=$(realpath $1/)
outputdir=$(realpath $2/)
filelist=$outputdir/training_all.txt
filelisttrain=$outputdir/training_all_train.txt
filelistval=$outputdir/training_all_val.txt
longlines=$outputdir/longlines.txt
DOCKERLOGHITOOLING=loghi/docker.loghi-tooling:$VERSION

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
echo docker run -u $(id -u ${USER}):$(id -g ${USER}) --rm -v $inputdir/:$inputdir/ -v $outputdir:$outputdir $DOCKERLOGHITOOLING \
  /src/loghi-tooling/minions/target/appassembler/bin/MinionCutFromImageBasedOnPageXMLNew -input_path $inputdir -outputbase $outputdir -channels 4 -output_type png -write_text_contents -threads $numthreads $INCLUDETEXTSTYLES -use_2013_namespace
docker run -u $(id -u ${USER}):$(id -g ${USER}) --rm -v $inputdir/:$inputdir/ -v $outputdir:$outputdir $DOCKERLOGHITOOLING \
  /src/loghi-tooling/minions/target/appassembler/bin/MinionCutFromImageBasedOnPageXMLNew -input_path $inputdir -outputbase $outputdir -channels 4 -output_type png -write_text_contents -threads $numthreads $INCLUDETEXTSTYLES -no_page_update $SKIP_UNCLEAR -use_2013_namespace

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


grep -E '.{150,}' $filelist > $longlines

shuf $longlines> shuffled
head -n 100 shuffled > $filelisttrain #Here the change needs to be made if you want to perform this with other values.
tail -n +101 shuffled >$filelistval #You need to change this value to 1 higher hten you set in the head.

rm shuffled

# Read each line in the input file
while IFS= read -r filename; do
  # Check if both .txt and .png files exist with the given filename
  if [ -f "$outputdir/$filename.txt" ] && [ -f "$outputdir/$filename.png" ]; then
    # Copy the files to the output directory
    cp "$target_directory/$filename.txt" "$outputdir"
    cp "$target_directory/$filename.png" "$outputdir"
    echo "Copied files: $filename.txt and $filename.png"
  fi
done < "$filelisttrain"