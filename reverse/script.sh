y=""
for i in {0..63}
do
	y=${y}$[RANDOM%2]
done
echo $y
