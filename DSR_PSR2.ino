

#define W 0
#define E 1
#define S 0
#define N 1
#define GOAL 2
#define CLOSED 3

#define trackPin 7
#define ambientPin 8
#define ON 1
#define OFF 0


#if defined(__AVR_ATmega1280__) || defined(__AVR_ATmega2560__)
#define INTERNAL INTERNAL1V1
#endif


unsigned long now,startOfTrial;
const byte TTLrepository[16]={00000000,10000001,10000010,10000011,
10000100,10000101,10000110,10000111,10001000,10001001,
10001010,10001011,10001100,10001101,10001110,10001111};


static int csen = 0;
static int  s   = -1;
static int  pin = 13;

byte b;

int count[10]={0,0,0,0,0,0,0,0,0,0};
int sTreshold=100;
int correct,error,sensor,errorPhase,OUT,noRewards;
int phase,currentPosition,endOfTrial,errorTrial,checkingSensors,finished;
int c,startPlat,choice1,choice2,platSpeed;
int SA,GA1,GA2;
float t1,t2,t3,t4,t5,convert;


char sensorPath[2000]="B_";




void myDigitalWrite(int pin,int value,int plat)
{
 if (plat==1){Serial1.write(50);Serial1.write(97+pin);Serial1.write(48+value);}
 if (plat==2){Serial2.write(50);Serial2.write(97+pin);Serial2.write(48+value);}
}

//target-> S=0,N=1,G=2,C=3
void motor(int plat, int target, int correct)
{
  if (plat==1){Serial1.write(53);Serial1.write(target);Serial1.write(correct);}
  if (plat==2){Serial2.write(53);Serial2.write(target);Serial2.write(correct);}
}

void practice_motor(int plat, int platSpeed)
{
  if (plat==1){Serial1.write(56); Serial1.write(platSpeed);}
  if (plat==2){Serial2.write(56); Serial2.write(platSpeed);}
}

void feeder_LED(int plat, int onOff)
{
  if (plat==1){Serial1.write(55);Serial1.write(onOff);}
  if (plat==2){Serial2.write(55);Serial2.write(onOff);}
}

void realing_door()
{
  Serial1.write(57);Serial1.write(0);
  Serial2.write(57);Serial2.write(0);
}




void errorContext()
{
  if (errorTrial==0)
  {
  errorPhase = phase;
  errorTrial = 1;
  sensor = currentPosition;
  }
}

void  cuesOff()
{
  feeder_LED(1,0); feeder_LED(2,0);
}

void wait()
{
  while (Serial.available()==0){}
}

void feeders(int plat, int correct)
{
  if (plat==1){Serial1.write(54);Serial1.write(correct);}
  if (plat==2){Serial2.write(54);Serial2.write(correct);}
}

void TTLgen(int seq)
{
  //pin 23 (TTL[0]) is bit 7 or strobe pin
  PORTC = TTLrepository[seq];
  delay(20);
  PORTC = TTLrepository[0];
}


void timestamp(int phase, unsigned long startOfTrial)
{
  now = millis() - startOfTrial;
  convert = (float) now;
  convert = convert / 1000.0f;
  switch (phase)
  {
    case 1:
      t1=convert;
    break;
    case 2:
      t2=convert;
    break;
      case 3:
      t3=convert;
    break;
      case 4:
       t4=convert;
    break;
  }
}



int sensorRead(char sensorPath[2000])
{
        finished = 0; checkingSensors = 1; OUT = -1;
        for (int a = 0;a < 10; a++){count[a] = 0;}
        while (finished==0)
        {
          b=PINA;
          if (b<255)
          {
            switch (b)
            {
              case 254:
              count[0]++; if (count[0]>sTreshold && b!=csen)
               {csen=b;finished=1; sensorPath=strcat(sensorPath,"_6");  OUT = 6;}
              break;
              case 253:
               count[1]++; if (count[1]>sTreshold && b!=csen)
               {csen=b;finished=1; sensorPath=strcat(sensorPath,"_3"); OUT =  3;}
              break;
              case 251:
               count[2]++; if (count[2]>sTreshold && b!=csen)
               {csen=b;finished=1; sensorPath=strcat(sensorPath,"_8"); OUT =  8;}
              break;
              case 247:
               count[3]++; if (count[3]>sTreshold && b!=csen)
               {csen=b;finished=1; sensorPath=strcat(sensorPath,"_9"); OUT =  9;}
              break;
              case 239:
               count[4]++; if (count[4]>sTreshold && b!=csen)
               {csen=b;finished=1; sensorPath=strcat(sensorPath,"_4"); OUT =  4;}
              break;
              case 223:
               count[5]++; if (count[5]>sTreshold && b!=csen)
               {csen=b;finished=1; sensorPath=strcat(sensorPath,"_2"); OUT =  2;}
              break;
              case 191:
               count[6]++; if (count[6]>sTreshold && b!=csen)
               {csen=b;finished=1; sensorPath=strcat(sensorPath,"_5"); OUT =  5;}
              break;
              case 127:
               count[7]++; if (count[7]>sTreshold && b!=csen)
               {csen=b;finished=1; sensorPath=strcat(sensorPath,"_7"); OUT =  7;}
              break;
            }
          }
          if (finished==0)
          {
            if (digitalRead(38)==1){count[8]++;
            if (count[8] > sTreshold && csen!=300)
            {csen=300;finished=1;sensorPath=strcat(sensorPath,"_10");OUT = 10;}}//E
            if (digitalRead(39)==1){count[9]++;
            if (count[9] > sTreshold && csen!=400)
            {csen=400;finished=1;sensorPath=strcat(sensorPath,"_11");OUT = 11;}}//w
          }
        }
        for (int a=0;a<10;a++){count[a] = 0;}
	checkingSensors = 0;
        return OUT;
}


void setup() {

  Serial.begin(115200);
  Serial1.begin(9600);
  Serial2.begin(9600);

  //clear buffers
  //clear buffers
  Serial.flush();
  Serial1.flush();
  Serial2.flush();

  //pin22 (PA0) - pin 29 (PA7) * all INPUTS - sensors
  DDRA = B00000000;
  //pin30 (PC7) - pin 37 (PC0) * all OUTPUTS - TTLs
  DDRC = B11111111;
  //East and West platform sensors don't fit in register
  DDRD |= (0<<7); DDRG |= (0<<2);
  //make sure cues are off

  // initialize Timer1
  cli();          // disable global interrupts
  TCCR1A = 0;     // set entire TCCR1A register to 0
  TCCR1B = 0;     // same for TCCR1B
  // set compare match register to desired timer count:
  OCR1A = 500;
  // turn on CTC mode:
  TCCR1B |= (1 << WGM12);
  // Set CS10 and CS12 bits for 1024 prescaler:
  TCCR1B |= (1 << CS10) | (1 << CS12);
  // enable timer compare interrupt:
  TIMSK1 |= (1 << OCIE1A);
  // enable global interrupts:


  TCCR3A = 0;     // set entire TCCR1A register to 0
  TCCR3B = 0;     // same for TCCR1B
  // set compare match register to desired timer count:
  OCR3A = 500;
  // turn on CTC mode:
  TCCR3B |= (1 << WGM32);
  // Set CS10 and CS12 bits for 1024 prescaler:
  TCCR3B |= (1 << CS30) | (1 << CS32);
  // enable timer compare interrupt:
  TIMSK3 |= (1 << OCIE3A);
  // enable global interrupts:

  sei();
  randomSeed(analogRead(0));
  DDRH |= (1<<4) | (1<<5);

}


ISR(TIMER1_COMPA_vect)
{

}

ISR(TIMER3_COMPA_vect)
{
 if (checkingSensors == 1 && Serial.available() > 0){finished=1;}
}






void loop()
{
  if (Serial.available())
  {

    /*
     * structure of trialInfo
     *
     * start arm
     * goal arm
     * correct/incorrect
     * start arm response
     * error
     * phase during error
     * sensor that triggered the error
     * t1
     * t2
     * t3
     * t4
     *
     */

    c = Serial.read();
    switch(c)
    {
      case 33://ascii(33)='!' -> start trial byte
         cuesOff();
         realing_door();
	 wait();
         SA = Serial.read()-48;
         wait();
         GA1 = Serial.read()-48;
         wait();
         GA2 = Serial.read()-48;



         //initializing trial variables
         phase = 1;
      	 errorPhase = 0;
      	 checkingSensors = 0;
         csen = 0;
         errorTrial = 0;
      	 correct = 0;
      	 currentPosition = 0;
      	 sensor = 0;
      	 choice1 = 0;
         choice2 = 0;
         t1 = 0;
         t2 = 0;
         t3 = 0;
         t4 = 0;
         t5 = 0;

         sensorPath[0] = 0;
         strcat(sensorPath,"_B");




         //linear track timer
         startOfTrial = millis();
         //open doors for start of trial!!
         motor(startPlat, SA, 0); motor(startPlat%2 + 1, SA, 0);

         endOfTrial=0;
         while (endOfTrial==0)
         {
           //detect rat location
           currentPosition = sensorRead(sensorPath);

	   //if there is serial, i want interruptions
	   if (Serial.available() > 0)
           {c = Serial.read(); if (c == 82){break;}}

           //take action
           endOfTrial = eventTrigger(currentPosition, SA, GA1, GA2, startOfTrial);

         }




         //send trial info back to python side!
         Serial.print(choice1);
         Serial.print(choice2);
         Serial.print(errorTrial);
         Serial.print('s');
         Serial.print(sensor);
         Serial.print('s');
         Serial.print(errorPhase);
         Serial.print('t');
         Serial.print(t1);
         Serial.print('t');
         Serial.print(t2);
         Serial.print('t');
         Serial.print(t3);
         Serial.print('t');
         Serial.print(t4);
         Serial.print('F');
         Serial.print(sensorPath);
         Serial.print('G');
	 c=-1;
         break;

      case 69://ascii(69)='E' -> set motor speed
        Serial1.write(58); Serial1.write(6);
        Serial2.write(58); Serial2.write(6);
        c=-1;
      break;

      case 82://ascii(82)='R' -> disengage both motors
        myDigitalWrite(9,0,1);
        myDigitalWrite(9,0,2);
        c=-1;
      break;

      case 83://ascii(83)='S' -> give starting platform
        wait();
        startPlat = Serial.read()-64;
        feeder_LED(startPlat,1);
        //close motors
        motor(1,3,0);
        motor(2,3,0);
        c=-1;
      break;

      case 104://h - in case we want to add something
        c=-1;
      break;


      case 105://i -> motor training program
        //plat Speed -> 1 is slow, 2 is med, 3 is full Speed
        wait();
        platSpeed=Serial.read()-65;
        practice_motor(1,platSpeed);
        practice_motor(2,platSpeed);
        c = -1;
        break;

      case 106://j feeder training Program
        noRewards = Serial.read() - 64;
        c = -1;
        break;

      default: //do nothing
	c=-1;
        break;
    }
  }
}//end of loop function}






//task for within reversal contexts
int eventTrigger(int currentPosition, int SA, int GA1, int GA2, unsigned long startOfTrial)
{
  int localEndOfTrial=0;
  switch (phase)
  {
    case 1:
      switch (currentPosition)
      {
        case 2:
          if  (startPlat==2 && SA==0){}
          else{errorContext();}
          feeder_LED(1,1); feeder_LED(2,1); motor(1,2,0);motor(2,2,0); timestamp(phase,startOfTrial); phase=2;
        break;
        case 3:
          errorContext();
        break;
        case 4:
          if  (startPlat==1 && SA==0){}
          else{errorContext();}
          feeder_LED(1,1); feeder_LED(2,1); motor(1,2,0);motor(2,2,0); timestamp(phase,startOfTrial); phase=2;
        break;
        case 5:
          if  (startPlat==2 && SA==1){}
          else{errorContext();}
          feeder_LED(1,1); feeder_LED(2,1); motor(1,2,0);motor(2,2,0); timestamp(phase,startOfTrial); phase=2;
        break;
        case 6:
          if  (startPlat==1 && SA==1){}
          else{errorContext();}
          feeder_LED(1,1); feeder_LED(2,1); motor(1,2,0);motor(2,2,0); timestamp(phase,startOfTrial); phase=2;
        break;
        case 7:
          errorContext();
        break;
        case 8:
          errorContext();
        break;
        case 9:
          errorContext();
        break;
        case 10:
          if (startPlat==2){errorContext();}
        break;
        case 11:
          if (startPlat==1){errorContext();}
        break;
      }
    break;//end of phase 1

    /* +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=*/

    case 2:
      switch (currentPosition)
        {


          case 3:
                 timestamp(phase,startOfTrial); phase=3;
          break;
          case 7:
                 timestamp(phase,startOfTrial); phase=3;
          break;

          // if rat skips this sensor
          case 8:
                timestamp(phase+1,startOfTrial); phase=4; choice1=currentPosition;
          break;
          case 9:
                timestamp(phase+1,startOfTrial); phase=4; choice1=currentPosition;
          break;

        }
    break;//end of phase 2

    /* +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=*/

    case 3:
      switch (currentPosition)
        {
          case 8:
                timestamp(phase,startOfTrial); phase=4; choice1=currentPosition;
          break;
          case 9:
                timestamp(phase,startOfTrial); phase=4; choice1=currentPosition;
          break;
          case 10:
          errorContext();
          break;
          case 11:
          errorContext();
          break;
        }
    break;//end of phase 3

    /* +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=*/

  case 4:
        switch (currentPosition)
        {
         case 10:
                cuesOff();
                choice2=currentPosition;
                startPlat=1;
                correct=GA1*2;
                motor(startPlat,CLOSED,correct); motor(2,CLOSED,0);
                timestamp(phase,startOfTrial);
                localEndOfTrial=1;


          break;
          case 11:
                cuesOff();
                choice2=currentPosition;
                startPlat=2;
                correct=GA2*2;
                motor(startPlat,CLOSED,correct); motor(1,CLOSED,0);
                timestamp(phase,startOfTrial);
                localEndOfTrial=1;

            break;
        }
  break;

  }
   /* +=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=*/

  return localEndOfTrial;

}
