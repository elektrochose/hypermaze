from __future__ import division
import random
import serial
import time
import datetime
import sys
import os
import signal
import multiprocessing
import struct
from struct import pack


#global variables
sessionFolder="";
runAvg = 0;


def start_session():


	ITI = 13;
	if overTraining == 0:
		criteria = 10; blockSize = 15;
	elif overTraining == 1:
		criteria = 45; blockSize = 45;

	blockHistory = [0] * blockSize;
	foragingCorrect = [0,0];
	timeCounter = 0;
	timeUpMessage = 0;
	trialsIntoBlock = 0;
	wakeUpTime = 480;

	global runAvg, start_time, reversalsCompleted;
	reversalsCompleted = 0;


	#selecting the initial goal
	if foraging == 0:
		goalArm = random.randint(1,2)
	elif foraging == 1:
		goalArm = 7


	if ser.inWaiting() > 0:
		tmp = str(ser.read());
		print "stuff left on buffer:";
		print tmp

	start_time = time.time()
	TT = 0
	for i in range(noTrials):


		#determines whether foraging trial gets reward
		foragingCorrect[0] = 1#int(random.randint(0,9) > 1)
		foragingCorrect[1] = 1#int(random.randint(0,9) > 1)



		if foraging==0:
			#figure out what the next goal is
			if regime=='deterministic':

				if sum(blockHistory) >= criteria:
					blockSizeWiggle = random.randint(1,3);
					if blockSizeWiggle==1:
						criteria=9;blockSize=11;
					elif blockSizeWiggle==2:
						criteria=10;blockSize=12;
					elif blockSizeWiggle==3:
						criteria=12;blockSize=15;

					blockHistory=[0]*blockSize;
					reversalsCompleted += 1;
					trialsIntoBlock = -1;
					goalArm = goalArm%2 + 1;

			elif regime=='probabilistic':

				if sum(blockHistory[-8:]) == 8 \
				or sum(blockHistory[-12:]) >= 10 \
				or sum(blockHistory) >= 12:

					blockHistory = [0]*15;
					reversalsCompleted += 1;
					trialsIntoBlock = -1;
					goalArm = goalArm%2 + 1;


		trialsIntoBlock += 1
		ser.write(pack('c','!')); #trial start byte! ASCII 33
		ser.write(pack('c',str(startArm[i])));

		if goalArm == 1:
			if regime == 'deterministic':
				ser.write(pack('c', str(1)));
				ser.write(pack('c', str(0)));
			elif regime == 'probabilistic':
				ser.write(pack('c', highPayout[i]));
				ser.write(pack('c', lowPayout[i]));

		elif goalArm == 2:
			if regime == 'deterministic':
				ser.write(pack('c', str(0)));
				ser.write(pack('c', str(1)));
			elif regime == 'probabilistic':
				ser.write(pack('c', lowPayout[i]));
				ser.write(pack('c', highPayout[i]));
		#foraging
		elif goalArm == 7:
			ser.write(pack('c', str(foragingCorrect[0])));
			ser.write(pack('c', str(foragingCorrect[1])));

		else:
			print "SOMETHING IS WRONG!!! :O"


		trial = ''
		trialDone = 0
		#waiting for a response
		timeCounter = 0
		wakeUpCall = 0
		messageSent = 0


		while trialDone == 0:


			if ser.inWaiting() > 0:

				bytesToRead = ser.inWaiting();
				tmp = ser.read(bytesToRead);
				trial = trial + tmp;

				if trial[-1] == 'Z':
					print trial
					trial = ''
				if trial[-1] == 'G':
					trialDone = 1;




			time.sleep(0.1);
			timeCounter += 0.1;
			wakeUpCall += 0.1;
			if wakeUpCall > wakeUpTime:
				print "Idle rat for %i seconds" %wakeUpTime
				wakeUpCall=0;

			if runAvg + (timeCounter/60) > timeLimit and timeUpMessage == 0:
				print "Time is up."
				timeUpMessage = 1;




		#obtain information about the trial
		choice1 = trial[0];
		choice2 = int(trial[1:3]);
		if (choice2==10 and goalArm==1) \
		or (choice2==11 and goalArm==2):
			correct = 1
		else:
			correct = 0

		if correct == 1 or goalArm == 7:
			AR = highPayout[i]
		elif correct == 0:
			AR = lowPayout[i]
		else:
			AR = 0


		for j in range(blockSize-1):
			blockHistory[j]=blockHistory[j+1];
		blockHistory[-1]=int(correct);

		error = trial[3];
		if int(error) == 1:
			print "error\n";

		sensor = trial[trial.index('s') + 1: trial.rfind('s')]
		phase = trial[trial.rfind('s') + 1: trial.rfind('s') + 2]


		#find the index of the Ts
		index1 = trial.find('t')
		index2 = trial.find('t', index1 + 1)
		index3 = trial.find('t', index2 + 1)
		index4 = trial.find('t', index3 + 1)


		#obtain the time from the string and formatting
		t1 = trial[index1 + 1: index2]
		t2 = trial[index2 + 1: index3]
		t3 = trial[index3 + 1: index4]
		t4 = trial[index4 + 1: trial.find('F')]

		#complete path the rat took during entire trial
		trialRealPath = trial[trial.find('F') + 1: trial.find('G')]

		T1=float(t1);
		T2=float(t2);
		T3=float(t3);
		T4=float(t4);
		T4=T4-T3;
		if T2==0:
			T3=T3-T1;
		else:
			T3=T3-T2;
			T2=T2-T1;


		t1=str(T1);
		t2=str(T2);
		t3=str(T3);
		t4=str(T4);

		TT+=float(t1);
		TT+=float(t2);
		TT+=float(t3);
		TT+=float(t4);
		TT+=ITI;
		runAvg=TT/60;

		if t1 != '?':
			t01 = "%03d" %float(t1)
			t1 = "%0.2f" %float(t1)
			t1 = t1[t1.index('.'):]
		else:
			t01 = "-1"
			t1 = ".0";
		if t2 != '?':
			t02 = "%03d" %float(t2)
			t2 = "%0.2f" %float(t2)
			t2 = t2[t2.index('.'):]
		else:
			t02 = "-1"
			t2 = ".0"
		if t3 != '?':
			t03 = "%03d" %float(t3)
			t3 = "%0.2f" %float(t3)
			t3 = t3[t3.index('.'):]
		else:
			t03 = "-1"
			t3 = ".0"
		if t4 != '?':
			t04 = "%03d" %float(t4)
			t4 = "%0.2f" %float(t4)
			t4 = t4[t4.index('.'):]
		else:
			t04 = "-1"
			t4 = ".0"



		#print trial information
		if regime=='deterministic':
			trialPrint = "trial:%02d/%i SA:%s GA:%s C:%s Ch1:%s Ch2:%s E:%s S:%s P:%s t1:%s t2:%s t3:%s t4:%s TT:%1.2f min" \
						  %(i + 1,
						    noTrials,
							startArm[i],
							goalArm,
							correct,
							choice1,
							choice2,
							error,
							sensor,
							phase,
							t01 + t1,
							t02 + t2,
							t03 + t3,
							t04 + t4,
							runAvg)

		elif regime == 'probabilistic':
			trialPrint = "trial:%02d/%i SA:%s GA:%s C:%s AR:%s Ch1:%s Ch2:%s  E:%s S:%s P:%s t1:%s t2:%s t3:%s t4:%s TT:%1.2f min" \
						 %(i + 1,
						   noTrials,
						   startArm[i],
						   goalArm,
						   correct,
						   AR,
						   choice1,
						   choice2,
						   error,
						   sensor,
						   phase,
						   t01 + t1,
						   t02 + t2,
						   t03 + t3,
						   t04 + t4,
						   runAvg)

		if notes == 'TRAINING' \
		or notes[0:10] == 'RETRAINING' \
		or notes == 'foraging'
		or notes == 'OVERTRAINING':
			print trialPrint
		else:
			print "trial:%02d/%i	TT:%1.2f min" %(i + 1, noTrials, runAvg)

		trialPrint = trialPrint + "\n";
		trialRealPath = trialRealPath + "\n";
		f.write(trialPrint);
		f.write(trialRealPath);

		#clear buffer
		if ser.inWaiting() > 0:
			while ser.inWaiting > 0:
				x=ser.read();
				print "leftovers"
				print x
		if runAvg > timeLimit:
			break
		#ITI
		time.sleep(ITI);

	total_quit(goalArm, 0)





def total_quit(goalArm, b):
	ser.write(pack('c','R'));

	#Calculate performance
	f.close();
	g = open(sessionFolder + '/log.txt','r');

	trialsFinished = 0;
	totalCorrect = 0;
	calendarString = '';

	for line in g:
		if line[0] == "t":
			correct = int(line[line.index('C')+2:line.index('C')+3])
			goalArm = int(line[line.index('G')+3:line.index('G')+4])
			trialsFinished += 1
			totalCorrect += correct

	if goalArm == 7:
		calendarString= "\n\nforage%imin - %i trials" %(runAvg, trialsFinished)
		trialsFinished = 0;
		print calendarString


	if ser.inWaiting() > 0:
		y=ser.inWaiting();
		print "leftover things in buffer:"
		x=ser.read(y);
		print x
		print "\n\n"

	if trialsFinished > 0:
		totalScore = float( totalCorrect / trialsFinished)
		calendarString += "%i-%0.2f-%imin-R:%i" \
					%(trialsFinished, totalScore, runAvg, reversalsCompleted)

		if notes == 'TRAINING'\
		or notes[0:10] == 'RETRAINING' \
		or notes == 'foraging' \
		or notes == 'OVERTRAINING':
			print calendarString

	sys.exit("\nBehavior program has quit.\n");
	return

#attaching function to SIGTERM (Ctrl+C)
signal.signal(signal.SIGINT, total_quit)
signal.signal(signal.SIGTERM, total_quit)




if __name__ == '__main__':


	print "\n----------------------------------------------------\n";
	print "Rat Behavior Program\nPablo Martin - Shapiro Lab"
	print "\n----------------------------------------------------\n";

	#CHANGE BY HAND !!!!!!
	goalArm = 7
	experiment = 'Cohort6';
	noTrials = 200;
	timeLimit = 20;
	prob = 85;


	#practice modes
	foraging = 1;
	overTraining = 0; #if ON, first block is much longer 20/25


	notes='foraging';
	#notes='OVERTRAINING';
	#notes='TRAINING';
	#notes='PL-saline';
	#notes='PL-muscimol';
	#notes='OFC-saline';
	#notes='OFC-muscimol';
	#notes='ipsiLeft-saline';
	#notes='ipsiRight-saline';
	#notes='ipsiLeft-muscimol';
	#notes='ipsiRight-muscimol';
	#notes='lOFCxrPL-saline';
	#notes='lOFCxrPL-muscimol';
	#notes='rOFCxlPL-saline';
	#notes='rOFCxlPL-muscimol';
	#notes='RETRAINING';
	#notes='RETRAINING2';
	#notes='RETRAINING3';
	#notes='RETRAINING4';
	#notes = 'RPL-muscimol';

	if experiment == 'Cohort2' \
	or experiment == 'Cohort4' \
	or experiment == 'Cohort6':
		regime = 'deterministic'

	elif experiment == 'Cohort3' \
	or experiment == 'Cohort5':
		regime = 'probabilistic'


	#opening a connection with papa arduino
	print "Starting connection..."
	ser=serial.Serial('/dev/ttyACM0', 115200, timeout=500)
	#allow time for connection to start
	time.sleep(0.5);
	#flush buffer
	ser.flushInput();
	print "Connected successfullly to " + ser.port


	#prompt user for input
	ratNumber = input('Enter rat name: ');
	#getting current time/date
	now=datetime.datetime.now();
	#establish folder
	home='/home/ubuntu/Behavior/data';
	ratFolder = home + '/' + experiment + '/' + str(ratNumber)
	sessionFolder = home + '/' \
					+ experiment + '/' \
				    + str(ratNumber) + '/' \
				    + str(now.day) + '_' \
				    + str(now.month) + '_' \
				    + str(now.year)

	if not os.path.isdir(ratFolder):
		print "Creating new directory for this rat";
		os.makedirs(ratFolder);

	if not os.path.isdir(sessionFolder):
		os.makedirs(sessionFolder);

	if os.path.isfile(sessionFolder + '/log.txt'):
		f=open(sessionFolder + '/log2.txt','w');
		print "\n\n * File exists already * be careful \n\n"
	else:
		f=open(sessionFolder + '/log.txt','w');


	f.write('Session Log\n');
	f.write("Saved in: " + sessionFolder + "\n");
	f.write("Experiment: " + experiment + "\n");
	f.write("Rat: " + str(ratNumber) + "\n");
	f.write("No. of trials: " + str(noTrials) + "\n");
	f.write("Regime: " + regime + "\n")
	f.write("Notes: " + notes + "\n");
	f.write("Session started at: " \
			+ time.strftime("%H:%M:%S", time.gmtime()) + "\n");



	#Assign starting platform
	ser.write(pack('c','S'));
	if random.randint(0,1) == 0:
		print "Place your rat in the WEST platform";
		ser.write(pack('c','B'));
	else:
		print "Place your rat in the EAST platform";
		ser.write(pack('c','A'));

	#set platform speed -> G (slow), -> E (fast)
	ser.write(pack('c','E'));


	#open sequence index file
	print "Loading sequences..."
	g = open('scripts/seqIndex.txt','r')
	begSeqs = []
	endSeqs = []

	#look for indexes of beginning and end of sequences
	for line in g:
		begSeqs.append(int(line[0: line.index(',')]))
		endSeqs.append(int(line[line.index(',') + 1:].rstrip()))
	g.close();

	#load the actual sequences
	nF = open('scripts/seqs4ard.txt');
	myString = nF.read();
	nF.close();

	#generate seed for random selection
	seed = random.randint(0, len(begSeqs) - 1);
	#extract random sequence
	startArm = myString[begSeqs[seed] + 2: endSeqs[seed + 1]];
	#get rid of all the commas
	startArm = startArm.translate(None, 'EB,n')
	startArm = startArm.replace("\\", "");
	#cut down to trial size
	startArm = startArm[0:noTrials];

	if prob == 80:
		PRL = open('scripts/mommaPRL2.csv','r');
	elif prob == 85:
		PRL = open('scripts/momma85PRL.csv','r');
	elif prob == 90:
		PRL = open('scripts/momma90PRL.csv','r');

	seqToday = random.randint(0,3599);
	for lineIndex, line in enumerate(PRL):
		if lineIndex == seqToday * 2:
			lowPayout = line
			lowPayout = lowPayout.replace(',', '')
		if lineIndex == seqToday * 2 + 1:
			highPayout = line
			highPayout = highPayout.replace(',', '')
	PRL.close()


	print "Sequence finished loading."
	print "\n----------------------------------------------------\n";


	start = raw_input("Start session [y/n]?");
	if start == "y":
		print "\nStarting session...";
		print "\n----------------------------------------------------\n";
		start_session();
	else:
		total_quit(goalArm, 0);
