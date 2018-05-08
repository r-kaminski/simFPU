y=""
for i in {0..31}
do
	y=${y}$[RANDOM%2]
done
echo $y
