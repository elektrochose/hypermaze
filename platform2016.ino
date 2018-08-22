

#include <math.h>
#include <Servo.h>

#define feederLED1 2
#define feederLED2 3
#define feederLED3 4
#define feeder1 5
#define feeder2 6
#define motorDir 7
#define motorStep 8
#define motorSleep 9
#define motorReset 10
#define microStepSwitch 11


#define SOUTH 0
#define NORTH 1
#define GOAL 2
#define CLOSED 3


#define CLOCKWISE 1
#define COUNTERCLOCKWISE 0
#define startUp 800
#define slowDown 40

#define E 1
#define W 2

int platformId = E;
int PeakSpeed=350;
int Hz=100;
int tmpA = 2 - platformId; 
int tmpB = platformId - 1;


volatile int currPos = 3;
volatile int count, correct, s = 0;
volatile int feederOn = -1;
volatile int smallReward = 0;

long steps, onSensor, posts, target= 0;
int dir,motorSpeed,stepsTaken,spit,guillotine;
int dirTargets[4][4]={{2,tmpA,tmpA,tmpB},{tmpB,2,tmpB,tmpA},{tmpB,tmpA,2,tmpB},{tmpA,tmpB,tmpA,2}};

int skipPost[4][4]={{0,1,0,0},{1,0,0,0},{0,0,0,1},{0,0,1,0}};
int doorMotorPositions[2][2]={{180,0},  {45,140}};
int motorLock = 0;
//creating door object
Servo door;

         


void setup() {


  //disabling global interrupts
  cli();
  
  // Timer/Counter3: 16 bit timer/counter with 16MHz clock
  TCCR3A = 0;
  TCCR3B = 0;
  OCR3A = 16000000/(Hz*256) - 1;// (must be < 65536 for the 16bit counter of timer1)
  TCCR3B |= (1 << CS32) ;// 256 prescaler 
  TCCR3B |= (1 << WGM32) ;
  TIMSK3 = 0;
  TIMSK3 |= (1 << OCIE3A);
  TIFR3 |= (1 << OCF3A);


  //USED TO BE RECALIBRATION SENSOR, KEEP IT JUST IN CASE?
  // Timer/Counter4: 10 bit timer/counter with default 64MHz clock
//  TCCR4A = 0;
//  TCCR4B = 0;
//  TCCR4C = 0;
//  TCCR4D = 0;
//  TCCR4B |= (1 << DTPS41) | (1 << DTPS40); // Prescaling clock: from 64MHz to 8MHz
//  TCCR4B |= (1 << CS43) |  (1 << CS41) | (1 << CS40); // Prescaling counter/timer by 512
//  TCCR4C |= (1 << COM4D1);
//  OCR4A = 300; // 
//  TIMSK4 = 0;
//  TIMSK4 |= (1 << OCIE4A);
//  TIFR4 |= (1 << OCF4A);

  //enabling global interrupts
  sei();
  
  //setting inputs and outputs
  DDRB = B11110000;  
  DDRC = B11000000;
  DDRD = B11111011; 
  DDRE = B01000000;
  DDRF = B00000000;

  //half-enabling motor
  digitalWrite(motorReset,HIGH);
  digitalWrite(microStepSwitch,HIGH);
  


  //initializing conncections
  Serial.begin(9600);
  Serial1.begin(9600);
  while (!Serial1);
  
  Serial.flush();
  Serial1.flush();
    

   
}


void loop() {

  /* variables declaration and initialization                */
  
  static int  s   = -1;    /* state                          */
  static int  pin = 13;    /* generic pin number             */
 
  int  val =  0;           /* generic value read from serial */
  int  agv =  0;           /* generic analog value           */
  int  dgv =  0;           /* generic digital value          */

  
  /* The following instruction constantly checks if anything 
     is available on the serial port. Nothing gets executed in
     the loop if nothing is available to be read, but as soon 
     as anything becomes available, then the part coded after 
     the if statement (that is the real stuff) gets executed */

  if (Serial1.available() >0) {

    /* whatever is available from the serial is read here    */
    val = Serial1.read();
    
    /* This part basically implements a state machine that 
       reads the serial port and makes just one transition 
       to a new state, depending on both the previous state 
       and the command that is read from the serial port. 
       Some commands need additional inputs from the serial 
       port, so they need 2 or 3 state transitions (each one
       happening as soon as anything new is available from 
       the serial port) to be fully executed. After a command 
       is fully executed the state returns to its initial 
       value s=-1                                            */
    switch (s) {

      /* s=-1 means NOTHING RECEIVED YET ******************* */
      case -1:      

      if (val>47 && val<90) {s=10*(val-48);}
      

      if (s>100 && s!=340 && s!=400) {s=-1;}

      /* the break statements gets out of the switch-case, so
      /* we go back and wait for new serial data             */
      break; /* s=-1 (initial state) taken care of           */


     
      /* s=0 or 1 means CHANGE PIN MODE                      */
      
      case 0:
      /* the second received value indicates the pin 
         from abs('c')=99, pin 2, to abs('¦')=166, pin 69    */
      if (val>98 && val<167) {
        pin=val-97;                /* calculate pin          */
        s=1; /* next we will need to get 0 or 1 from serial  */
      } 
      else {
        s=-1; /* if value is not a pin then return to -1     */
      }
      break; /* s=0 taken care of                            */


      case 1:
      /* the third received value indicates the value 0 or 1 */
      if (val>47 && val<50) {
        /* set pin mode                                      */
        if (val==48) {
          pinMode(pin,INPUT);
        }
        else {
          pinMode(pin,OUTPUT);
        }
      }
      s=-1;  /* we are done with CHANGE PIN so go to -1      */
      break; /* s=1 taken care of                            */
      


      /* s=10 means DIGITAL INPUT ************************** */
      
      case 10:
      /* the second received value indicates the pin 
         from abs('c')=99, pin 2, to abs('¦')=166, pin 69    */
      if (val>98 && val<167) {
        pin=val-97;                /* calculate pin          */
        dgv=digitalRead(pin);      /* perform Digital Input  */
        Serial.println(dgv);       /* send value via serial  */
      }
      s=-1;  /* we are done with DI so next state is -1      */
      break; /* s=10 taken care of                           */

      

      /* s=20 or 21 means DIGITAL OUTPUT ******************* */
      
      case 20:
      /* the second received value indicates the pin 
         from abs('c')=99, pin 2, to abs('¦')=166, pin 69    */
      if (val>98 && val<167) {
        pin=val-97;                /* calculate pin          */
        s=21; /* next we will need to get 0 or 1 from serial */
      } 
      else {
        s=-1; /* if value is not a pin then return to -1     */
      }
      break; /* s=20 taken care of                           */

      case 21:
      /* the third received value indicates the value 0 or 1 */
      if (val>47 && val<50) {
        dgv=val-48;                /* calculate value        */
      	digitalWrite(pin,dgv);     /* perform Digital Output */
      }
      s=-1;  /* we are done with DO so next state is -1      */
      break; /* s=21 taken care of                           */


	
      /* s=30 means ANALOG INPUT *************************** */
      
      case 30:
      /* the second received value indicates the pin 
         from abs('a')=97, pin 0, to abs('p')=112, pin 15    */
      if (val>96 && val<113) {
        pin=val-97;                /* calculate pin          */
        agv=analogRead(pin);       /* perform Analog Input   */
	      Serial.println(agv);       /* send value via serial  */
      }
      s=-1;  /* we are done with AI so next state is -1      */
      break; /* s=30 taken care of                           */



      /* s=40 or 41 means ANALOG OUTPUT ******************** */
      
      case 40:
      /* the second received value indicates the pin 
         from abs('c')=99, pin 2, to abs('¦')=166, pin 69    */
      if (val>98 && val<167) {
        pin=val-97;                /* calculate pin          */
        s=41; /* next we will need to get value from serial  */
      }
      else {
        s=-1; /* if value is not a pin then return to -1     */
      }
      break; /* s=40 taken care of                           */


      case 41:
      /* the third received value indicates the analog value */
      analogWrite(pin,val);        /* perform Analog Output  */
      s=-1;  /* we are done with AO so next state is -1      */
      break; /* s=41 taken care of                           */
      
      /* s=50-or 51 means MOVE MOTORS ******************** */

      case 50:     
        target=val;
        if (target!=currPos)
        {
          guillotine = 0;          
          if (target==CLOSED && currPos==GOAL){guillotine=1;}
          if (target==GOAL && currPos==CLOSED){guillotine=2;}
          
          //determine direction
          digitalWrite(motorDir,dirTargets[currPos][target]);
  
  
          //transition state
          s=51;
        }else{s=-1;}
        
      break;
      
      case 51://rotate
        //initialize variable      
        steps = 0;
        stepsTaken = 0;
        onSensor = 0;
        posts=skipPost[currPos][target];
        
        
        //only if going to closed position do we care about reward
        if  (target==CLOSED)
        {
          if (val==0){correct=0;}      
          if (val==1){correct=1; smallReward=1;}
          if (val==2){correct=1; smallReward=0;}
          feederOn=1;    
        }
        digitalWrite(motorSleep,HIGH);
        
        while (1>0)
        {

          if (steps<startUp && onSensor==0) {motorSpeed=startUp+PeakSpeed-steps;}
          else
          {
            motorSpeed=PeakSpeed;      
            if (digitalRead(A0)==0 && onSensor==0){onSensor=1;if (posts==0){steps=0;}}
            
            if (onSensor==1 && posts>0)
            {
              if (digitalRead(A0)==1){onSensor=0;posts--;}
              
            } else if (onSensor==1 && posts==0) //if we hit a stopping point
            {           
              if (steps<slowDown){motorSpeed=PeakSpeed+steps;}//slowing down motor
              else if (steps==slowDown) {break;} //stopping motor        
            }    
           }
           if (guillotine > 0 && stepsTaken == 20)
           {door.attach(13);door.write(doorMotorPositions[platformId-1][0]);}
         
         
         //turn motor
         PORTB |= (1<<4); delayMicroseconds(motorSpeed);
         PORTB &= ~(1<<4); delayMicroseconds(motorSpeed); 
         //increase indexes
         steps++;stepsTaken++;
        }
        //return door to resting position
        if (guillotine > 0){ 
           door.write(doorMotorPositions[platformId-1][1]);delay(250);        
          door.detach();
        }     

        //update current position
        currPos=target;
        //return state machine to idle mode
        s=-1;
      break;
      
      //correct response
      case 60:
          if (val==0){correct=0;}      
          if (val==1){correct=1; smallReward=1;}
          if (val==2){correct=1; smallReward=0;}
          feederOn=1;
          s=-1;
      break;
      //turn LED on or OFF
      case 70:
          
          if (val==0){PORTD &= ~(1<<0);}
          if (val==1){PORTD |= (1<<0);}
          s=-1;
      break;
      //slowly turn platform
      case 80:
        if (val==1){motorSpeed=800;}
        if (val==2){motorSpeed=600;}
        if (val==3){motorSpeed=PeakSpeed;}
        if (val>0){
        digitalWrite(motorSleep,HIGH);
        while (val<50000){
        //turn motor
        PORTB |= (1<<4); delayMicroseconds(motorSpeed);
        PORTB &= ~(1<<4); delayMicroseconds(motorSpeed);                    
        val++;
        }
        digitalWrite(motorSleep,LOW);
        }
        s=-1;
      break;
      
      case 90://re-align doors
          door.attach(13);
          door.write(doorMotorPositions[platformId-1][1]);
          delay(250);        
          door.detach();
          s=-1;
      break;
      case 100:
          PeakSpeed=val*50;
          s=-1;
      break;


      /* ******* UNRECOGNIZED STATE, go back to s=-1 poop ******* */
      
      default:
      /* we should never get here but if we do it means we 
         are in an unexpected state so whatever is the second 
         received value we get out of here and back to s=-1  */
      
      s=-1;  /* go back to the initial state, break unneeded */



    } /* end switch on state s                               */

  } /* end if serial available                               */
  
} /* end loop statement                                      */






ISR(TIMER3_COMPA_vect)//every 10ms
{

    if (feederOn==0){count++;feederOn=-1;
        PORTC &= ~(1<<6);}
    if (feederOn==1){feederOn=0;
      if (correct==1){ PORTC |= (1<<6);}}
    
    if (count>0)
    {
      switch(count)
      {
        case 15:
          PORTD |= (correct<<1);
        break;
        case 30:
          PORTD |= (correct<<0);
          if (smallReward==0){feederOn=1;}
          else {count++;}
        break;
        case 31: 
          PORTD |= (correct<<4); 
        break;
        case 46:
          PORTD &= ~(1<<1);
        break;
        case 61:
          PORTD &= ~(1<<0);
        break;
        case 76:
          PORTD &= ~(1<<4);count=-1;
        break;     
      }
      count++;
    }//end of count>0
}

// Timer 4 for motor recalibration sensor 
ISR(TIMER4_COMPA_vect)
{
}

