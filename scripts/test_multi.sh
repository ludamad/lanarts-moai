cd ..
for i in 1 ; do
    IP='localhost' CLIENT=1 konsole --noclose -e /home/adomurad/sources/moai-game/run.sh
done
SERVER=1 konsole --noclose -e /home/adomurad/sources/moai-game/run.sh
