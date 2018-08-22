function []=hypermaze(ARDUINO)
%
%FORCE USER TO TYPE IN EXPRIMENT NAME AND RAT BEFORE STARTING
%
%Program for running automated maze - spatial context task, cue task
%Pablo Martin - Shapiro Lab
%Mount Sinai School of Medicine
%
%Instructions:
%
%1)Type in experiment name (e.g.DREADS-hippocampus, it will work with spaces
%but it might be better to avoid them, use underscore or dash instead)
%2)Type name of rat
%3)Type some notes (Infusion, training, 2nd of reversal, etc)
%
%Click one of the buttons on the right to begin!
%
%1) Start Session will begin the serial reversal task program
%2) Test Session will allow you to get acquainted with the program 
%3) Quit will ... quit
%4) Rat Progress - Allows you to monitor in a graph format how each
%individual rat is progressing. You must type rat and experiment before!
%
%
%Any questions or bug-issues contact: pablo.martin@mssm.edu
%
%                     __         __
%                    (  ) _ - _ (  )
%                     ~~         ~~
%                      (  0   0  )
%     -----------ooO----(       )----Ooo------------
%                        (     )
%                         (   )
%                         ~~O~~    Rat Behavior Program
%
%
%

clear sound
close all
%DECLARING GLOBAL VARIABLES
global Session_Folder
global ROOT
global files_funct

%global variables: for input defined information
global experiment
global exp_RAT
global Notes
global Training_Sel
global no_trials

%internal variables of maze
global trial_end
global block
global premature_quit
global buffer
global buffer_no_conv
global jj
global speedy_rat
global forage

%acquiring Root Directory
ROOT=pwd;  
addpath(genpath(ROOT)) 
files_funct='/home/pablo/MATLAB/behavior/MAZE_functions';


%%
%===========================================================================
%                       GUI SET-UP
%=========================================================================== 

f = figure('Position',[160,500,500,160],'Color',[0.5 0.5 0.6]);
set(f, 'menubar', 'none'); button_color=[1 1 1];
set(gcf,'numbertitle','off','name','Rat Behavior Program - Shapiro Lab')


%Text Labels
uicontrol('Style', 'text',...
           'String', 'Experiment',...
           'Position', [10 130 80 20],...
           'BackgroundColor',button_color);  
       
uicontrol('Style', 'text',...
           'String', 'Rat Name',...
           'Position', [10 100 80 20],...
           'BackgroundColor',button_color);
       
uicontrol('Style', 'text',...
           'String', 'Notes',...
           'Position', [10 70 80 20],...
           'BackgroundColor',button_color);

uicontrol('Style', 'text',...
           'String', '# Trials',...
           'Position', [10 40 80 20],...
           'BackgroundColor',button_color);
       
uicontrol('Style', 'text',...
           'String', 'Regime',...
           'Position', [10 10 80 20],...
           'BackgroundColor',button_color);
       

%Input controls
uicontrol('Style', 'edit',...
           'String', ' ',...
           'Position', [100 130 250 20],...
           'BackgroundColor',button_color,...
           'Callback', @experiment_input);

uicontrol('Style', 'edit',...
           'String', ' ',...
           'Position', [100 100 250 20],...
           'BackgroundColor',button_color,...
           'Callback', @rat_input);
       
uicontrol('Style', 'edit',...
           'String', ' ',...
           'Position', [100 70 250 20],...
           'BackgroundColor',button_color,...
           'Callback', @note_function);

uicontrol('Style', 'edit',...
           'String', ' ',...
           'Position', [100 40 250 20],...
           'BackgroundColor',button_color,...
           'Callback', @trial_input);
       
uicontrol('Style', 'popup',...
           'String', {'E','W','blink','solid','E and W','blink and solid',...
           'E/W/E','blink/solid/blink','W/E/blink/solid (4 blocks)','W/E/blink/solid (8 blocks)','W/E/blink/solid (12 blocks)','full task','forage'},...
           'Position', [95 10 260 20],...
           'Callback', @training_choice);   
                  
 
       
%START/QUIT buttons
uicontrol('Style','pushbutton',...
           'String','Start Session','Position',[365,80,110,60],...
           'BackgroundColor',button_color,'Callback',{@start_session_function});
       
uicontrol('Style','pushbutton',...
           'String','Quit','Position',[365,10,110,60],...
           'BackgroundColor',button_color,'Callback',{@total_quit});
         

%===========================================================================
%                       EXPERIMENT INPUT FUNCTIONS 
%                  cooresponding functions for buttons
%=========================================================================== 
  
function note_function(sObj,~)
     Notes = get(sObj,'String');   
end 

function total_quit(~,~)
    cd(ROOT)
    close all
end
       
function experiment_input(sObj,~) 
  cd(ROOT)
  experiment = strtrim(get(sObj,'String'));
  %checking if experiment folder exists, if not, it creates directory
    cd('DATA');dexists=0;dirDATA=dir(pwd);
    for dl=1:length(dirDATA)
        if strcmpi(dirDATA(dl).name,experiment)
          dexists=1;
        end
    end
    if dexists==0
         mkdir(experiment);
    end
    cd(ROOT)
end    
    
function rat_input(sObj,~)          
  exp_RAT = strtrim(get(sObj,'String'));
  cd(ROOT);cd(['DATA/' experiment])
  %checking if rat exists, if not, it creates directory
    rexists=0; temp_dir=dir();
    for rl=1:length(temp_dir)
        if strcmpi(temp_dir(rl).name,exp_RAT)
          rexists=1;
        end
    end
    if rexists==0
         mkdir(exp_RAT);
         cd(exp_RAT)
         
         start_seq=randi(8,100,1);
         while sum(diff(start_seq)==0)>0
             start_seq=randi(8,100,1);
         end
         platform_start=randi(2,100,1);%1=E, 2=W
         day_counter=[1 ;zeros(99,1)];
         initial_conditions=[day_counter start_seq platform_start];
         save('Start_SEQ.mat','initial_conditions')
    end
    Session_Folder=strcat(ROOT,'/DATA/',experiment,'/',exp_RAT);
    cd(ROOT)
end     
 
function trial_input(sObj,~) 
  no_trials = str2num(strtrim(get(sObj,'String')));
end    

function training_choice(sObj,~)
   Training_Sel= get(sObj,'Value');
end


%%
%===========================================================================
%                       INITIZIALIZING ARDUINO CHANNELS
%===========================================================================
       
%DO NOT USE D20/D21

%beams - ANALOG channels
% A2 -EP
% A3 -WP
% A8 -NE
% A9 -SE
% A10 -N
% A11 -S
% A12 -SW
% A13 -NW
% A14 -W
% A15 -E

%motor W
ARDUINO.pinMode(2,'output');
ARDUINO.pinMode(3,'output');
ARDUINO.pinMode(8,'output');
ARDUINO.pinMode(9,'output');

%motor E    
ARDUINO.pinMode(4,'output');
ARDUINO.pinMode(5,'output');
ARDUINO.pinMode(11,'output');
ARDUINO.pinMode(12,'output');

%platform sensors
ARDUINO.pinMode(6,'input');%WP 
ARDUINO.pinMode(7,'input');%EP

%Overhead 3W LEDs
ARDUINO.pinMode(10,'output');

%TTL channel - TX3
ARDUINO.pinMode(18,'output');

% pumps
ARDUINO.pinMode(30,'output'); %W
ARDUINO.pinMode(31,'output'); %E

%blinker LEDs
ARDUINO.pinMode(34,'output'); %W
ARDUINO.pinMode(35,'output'); %E

%EL Wire
ARDUINO.pinMode(38,'output');%SE
ARDUINO.pinMode(40,'output');%outer S
ARDUINO.pinMode(42,'output');%NE
ARDUINO.pinMode(44,'output');%outer N
ARDUINO.pinMode(46,'output');%SW
ARDUINO.pinMode(48,'output');%NW

%%
%Completely Optional
%%STARTING SEQUENCE 

ARDUINO.analogWrite(10,0);
ARDUINO.digitalWrite(34,1);
ARDUINO.digitalWrite(35,1);

ELW_seq=[40 44 48 38 46 42 ];
for el=1:length(ELW_seq)
ARDUINO.digitalWrite(ELW_seq(el),1);
pause(0.2)
ARDUINO.digitalWrite(ELW_seq(el),0);
end





%%
%FUNCTION THAT RUNS SERIAL REVERSAL TASK ++++++++++++++++++++++++++++++++++
function start_session_function(~,~)


%loading day information
cd(Session_Folder)
%creating folder for temporary files
temp_save_file_folder=strcat('temp files-',date);    
mkdir(temp_save_file_folder);  

initial_conditions=load('Start_SEQ.mat'); 
initial_conditions=initial_conditions.initial_conditions;
day=find(initial_conditions(:,1),1);
forage=0;

%loading our randomized sequence bank
cd(ROOT)
cd(files_funct)
SB120=load('FSEQ_BANK_120.mat');
SB120=SB120.SB120;
cd(ROOT)
% with the following rules:
% start arm: 0 is south,            1 is north
% task     : 0 is spatial,          1 is cue/body turn
% goal     : 0 is sine->E/blink     1 is noise->W/solid
% choice   : 0 is incorrect         1 is correct

%randomly obtaining relevant information with appropriate starting sequence
session_sequences=create_session_seqs(initial_conditions(day,2),SB120);
session_sequences=session_sequences(1:no_trials,:);

%start arms should always be random
start_arms=session_sequences(:,1);
starting_platform=initial_conditions(day,3);

if starting_platform==1
    platform_string='E';
elseif starting_platform==2
    platform_string='W';
end

%loading IR buffer
%column 1=normal, 2=EL, 3=overhead
buffer=load('MAZE_functions/Buffer_3_cond.mat');
buffer=buffer.tri_buffer;
buffer=cat(1,squeeze(max(buffer(:,:,:),[],2)));
buffer=buffer(:,[3 2 1]);
buffer_no_conv=[1:10;2 3 8 9 10 11 12 13 14 15];


%depending on training programme vs. task
if Training_Sel==1 || Training_Sel==2 || Training_Sel==5 || Training_Sel==7
    task_no=zeros(no_trials,1);
elseif Training_Sel==3 || Training_Sel==4 || Training_Sel==6 || Training_Sel==8
    task_no=ones(no_trials,1);
elseif Training_Sel==9
    task_no=reversal_generator(no_trials,4);
elseif  Training_Sel==10
    task_no=reversal_generator(no_trials,8);
elseif Training_Sel==11
    task_no=reversal_generator(no_trials,12);
elseif Training_Sel==12
    task_no=session_sequences(1:no_trials,2);
elseif Training_Sel==13
    task_no=session_sequences(1:no_trials,2);
end


%depending on training programme vs. task
if Training_Sel==1 ||  Training_Sel==3 
    goal_no=zeros(no_trials,1);
elseif Training_Sel==2 || Training_Sel==4
    goal_no=ones(no_trials,1);
elseif Training_Sel==5 || Training_Sel==6
    goal_no=reversal_generator(no_trials,2);
elseif Training_Sel==7 || Training_Sel==8
    goal_no=reversal_generator(no_trials,3);
elseif Training_Sel==9
    temp=reversal_generator(no_trials,4);
    goal_no=[temp(1:no_trials/2,1) ; flipud(temp(no_trials/2+1:end,1))];
elseif Training_Sel==10
    temp=reversal_generator(no_trials,8);
    goal_no=[temp(1:no_trials/2,1) ; flipud(temp(no_trials/2+1:end,1))];
elseif Training_Sel==11
    temp=reversal_generator(no_trials,12);
    goal_no=[temp(1:no_trials/2,1) ; flipud(temp(no_trials/2+1:end,1))];
elseif Training_Sel==12
    goal_no=session_sequences(1:no_trials,3);
elseif Training_Sel==13
    goal_no=session_sequences(1:no_trials,3);
    forage=1;
end


%filling in the block
block=nan(no_trials,9);
block(:,1)=start_arms;
block(:,2)=task_no;
block(:,3)=goal_no;

for motor=1:2
    if motor==2
        pwr_a = 3;
        pwr_b = 9;
        dir_a = 2;
        dir_b = 8;
    elseif motor==1
        pwr_a = 5;
        pwr_b = 12;
        dir_a = 4;
        dir_b = 11;
    end

    ARDUINO.digitalWrite(pwr_a,0);
    ARDUINO.digitalWrite(pwr_b,0);
    ARDUINO.digitalWrite(dir_a,0);
    ARDUINO.digitalWrite(dir_b,0);
end
    
%waiting for user to calibrate platform
close all       
S.f = figure('Position',[360,200,300,100]);         
set(S.f, 'menubar', 'none');
set(gcf,'numbertitle','off','name','Turn Platforms to Closed Position')
uicontrol('Style','pushbutton',...
           'String','OK, Done','FontSize',28,'Position',[150,10,130,80],...
           'Callback',{@total_quit});

uiwait();


%informing the user which platform to start on
close all       
S.f = figure('Position',[360,200,300,100]);         
set(S.f, 'menubar', 'none');
set(gcf,'numbertitle','off','name','Place rat in platform: ')
uicontrol('Style','pushbutton',...
           'String','OK, Done','FontSize',28,'Position',[150,10,130,80],...
           'Callback',{@total_quit});
uicontrol('Style', 'text',...
           'String', platform_string,...
          'FontSize',28,'Position', [10 10 130 80]);  
uiwait();



close all       
S.f = figure('Position',[360,200,1180,740]);         
set(S.f, 'menubar', 'none');
set(gcf,'numbertitle','off','name','Rat Behavior Program - Shapiro Lab')

S.quit = uicontrol('style','push',...
 'units','pix',...
 'position',[10 690 50 40],...
 'string','Quit',...
 'fontsize',15,'BackgroundColor',[0.7 0.5 0.6],...
  'Callback', @quit_session);

S.southarm = uicontrol('style','text',...
 'units','pix',...
 'position',[70 70 1020 40],...
 'string','',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);
S.northarm = uicontrol('style','text',...
 'units','pix',...
 'position',[70 620 1020 40],...
 'string','',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);
S.westarm = uicontrol('style','text',...
 'units','pix',...
 'position',[70 70 40 550],...
 'string','',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);
S.eastarm = uicontrol('style','text',...
 'units','pix',...
 'position',[1050 70 40 550],...
 'string','',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);
S.centralV = uicontrol('style','text',...
 'units','pix',...
 'position',[560 70 40 550],...
 'string','',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);
S.centralH = uicontrol('style','text',...
 'units','pix',...
 'position',[70 345 1020 40],...
 'string','',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);
S.Eplat = uicontrol('style','text',...
 'units','pix',...
 'position',[1010 305 120 120],...
 'string','E',...
 'fontsize',16,'BackgroundColor',[0.5 0.5 0.6]);
S.Wplat = uicontrol('style','text',...
 'units','pix',...
 'position',[30 305 120 120],...
 'string','W',...
 'fontsize',16,'BackgroundColor',[0.5 0.5 0.6]);

%Beam positions in the GUI maze
%1 EP, 2 WP, 3 NW, 4, NE, 5 SW, 6 SE, 7 S, 8 N, 9 W, 10 E
rat_positions=[1050 345 40 40;70 345 40 40;70 620 40 40;1050 620 40 40;70 70 40 40;...
               1050 70 40 40;560 110 40 40; 560 580 40 40;410 345 40 40;750 345 40 40];

S.RAT = uicontrol('style','text',...
 'units','pix',...
 'position',rat_positions(starting_platform,:),...
 'string','RAT',...
 'fontsize',13,'BackgroundColor',[1 0 0]); 


premature_quit=0;
feeder_pause=[30 0.12;31 0.07;30 0.26;31 0.17];
if forage==1
    ARDUINO.digitalWrite(30,1);pause(1.5);ARDUINO.digitalWrite(30,0);
    ARDUINO.digitalWrite(31,1);pause(1.5);ARDUINO.digitalWrite(31,0);
end
%%
%TRIALS ================*******************========================
for jj=1:no_trials
if premature_quit==0
speedy_rat=0;
faulty_trial=0;

%print trial # and task type
if block(jj,2)==0
    task_string='Spatial';
elseif block(jj,2)==1 
    task_string='LED Approach';
end

S.trial = uicontrol('style','text',...
 'units','pix',...
 'position',[70 710 120 20],...
 'string',['  Trial  ',num2str(jj)],...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);
S.task = uicontrol('style','text',...
 'units','pix',...
 'position',[70 680 120 20],...
 'string',task_string,...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);     
S.phase = uicontrol('style','text',...
 'units','pix',...
 'position',[200 710 120 20],...
 'string','Phase 1',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);   


beam_breaks=struct('phase',[],'broken',[]);
%determine which IR beam to look at
beam_breaks(1).phase=[relevant_phase_beam(starting_platform,start_arms(jj),1)];
beam_breaks(1).broken=0;
beam_breaks(2).phase=[relevant_phase_beam(starting_platform,start_arms(jj),2)];
beam_breaks(2).broken=0;
beam_breaks(3).phase=[relevant_phase_beam(starting_platform,start_arms(jj),3)];
beam_breaks(3).broken=0;
beam_breaks(4).phase=[2 3];
beam_breaks(4).broken=0;

beam_stream=cat(2,beam_breaks.phase);
       
%opening platforms for start of trial
if starting_platform==1 && block(jj,1)==0
    platform(ARDUINO,2,1,3,0,0);
    platform(ARDUINO,1,1,2,0,0);
    %generateTTL(ARDUINO,1)
elseif starting_platform==1 && block(jj,1)==1
    platform(ARDUINO,2,1,3,0,0);
    platform(ARDUINO,1,1,4,0,0);
    %generateTTL(ARDUINO,1)
elseif starting_platform==2 && block(jj,1)==0
    platform(ARDUINO,1,1,3,0,0);
    platform(ARDUINO,2,1,2,0,0);
    %generateTTL(ARDUINO,1)
elseif starting_platform==2 && block(jj,1)==1
    platform(ARDUINO,1,1,3,0,0);
    platform(ARDUINO,2,1,4,0,0);
    %generateTTL(ARDUINO,1)
end
    

tic

freq=200;%Hz
lambda=1/freq; 

%randomly selecting which platform is blinking
random_blink=randi(2,1);
if random_blink==1    
   blinking_platform=1;       
else 
   blinking_platform=2;
end    
arduino_channel_blinking=[35 34];        
%PHASE 1
led_count=1;
led_freq=10;
while beam_breaks(1).broken==0 && premature_quit==0 && faulty_trial==0
  %  pause(lambda)
    if random_blink==1       
            ARDUINO.digitalWrite(34,0); %W
            ARDUINO.digitalWrite(35,mod(floor(led_count/led_freq),2)); %E
            led_count=led_count+1;
    else 
            ARDUINO.digitalWrite(35,0); %E
            ARDUINO.digitalWrite(34,mod(floor(led_count/led_freq),2)); %W
            led_count=led_count+1;
    end
    for i=1:length(beam_stream)-2
        if ARDUINO.analogRead(beam_stream(i)) > buffer(buffer_no_conv(1,find(buffer_no_conv(2,:)==beam_stream(i))),1)*1.2

            
            if sum(beam_breaks(1).phase==beam_stream(i))==1
            %generateTTL(ARDUINO,n);
            beam_breaks(1).broken=1;
            block(jj,7)=toc;

             %update RAT GUI  
            set(S.RAT,'Visible','off')
            S.RAT = uicontrol('style','text',...
                     'units','pix','position',...
                     rat_positions(arduinoIR2GUI_IR(beam_breaks(1).phase),:),...
                     'string','RAT',...
                     'fontsize',13,'BackgroundColor',[1 0 0]); 

            if task_no(jj)==0
                ARDUINO.digitalWrite(38,1);%SE
                ARDUINO.digitalWrite(40,1);%outer S
                ARDUINO.digitalWrite(42,1);%NE
                ARDUINO.digitalWrite(44,1);%outer N
                ARDUINO.digitalWrite(46,1);%SW
                ARDUINO.digitalWrite(48,1);%NW
            elseif task_no(jj)==1
                ARDUINO.analogWrite(10,200);
            end
            %opening remaining platform
                if starting_platform==1 && block(jj,1)==0

                    platform(ARDUINO,1,2,3,arduino_channel_blinking(random_blink),11);
                    %generateTTL(ARDUINO,1)
                elseif starting_platform==1 && block(jj,1)==1

                    platform(ARDUINO,1,4,3,arduino_channel_blinking(random_blink),10);
                    %generateTTL(ARDUINO,1)
                elseif starting_platform==2 && block(jj,1)==0

                    platform(ARDUINO,2,2,3,arduino_channel_blinking(random_blink),11);
                    %generateTTL(ARDUINO,1)
                elseif starting_platform==2 && block(jj,1)==1

                    platform(ARDUINO,2,4,3,arduino_channel_blinking(random_blink),10);
                    %generateTTL(ARDUINO,1)
                end
            else
                faulty_trial=1;
                if starting_platform==1 && block(jj,1)==0

                    platform(ARDUINO,1,2,3,arduino_channel_blinking(random_blink),0);
                    %generateTTL(ARDUINO,1)
                elseif starting_platform==1 && block(jj,1)==1

                    platform(ARDUINO,1,4,3,arduino_channel_blinking(random_blink),0);
                    %generateTTL(ARDUINO,1)
                elseif starting_platform==2 && block(jj,1)==0

                    platform(ARDUINO,2,2,3,arduino_channel_blinking(random_blink),0);
                    %generateTTL(ARDUINO,1)
                elseif starting_platform==2 && block(jj,1)==1

                    platform(ARDUINO,2,4,3,arduino_channel_blinking(random_blink),0);
                    %generateTTL(ARDUINO,1)
                end
                ARDUINO.digitalWrite(34,1); %W
                ARDUINO.digitalWrite(35,1); %W
                
                S.faulty = uicontrol('style','text',...
                         'units','pix',...
                         'position',[400 410 160 60],...
                         'string','FAULTY TRIAL',...
                         'fontsize',16,'BackgroundColor',[0.2 0.5 0.6]);   
                
            end
        end
    end
end
S.phase = uicontrol('style','text',...
 'units','pix',...
 'position',[200 710 120 20],...
 'string','Phase 2',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);

%PHASE 2 
led_count=1;
while (beam_breaks(2).broken==0 && premature_quit==0) && speedy_rat==0 && faulty_trial==0
    
    %pause(lambda)
    if random_blink==1 
            ARDUINO.digitalWrite(34,0); %W
            ARDUINO.digitalWrite(35,mod(floor(led_count/led_freq),2)); %E
            led_count=led_count+1;
    else
            ARDUINO.digitalWrite(35,0); %E
            ARDUINO.digitalWrite(34,mod(floor(led_count/led_freq),2)); %W
            led_count=led_count+1;
    end
    for i=2:length(beam_stream)
        if ARDUINO.analogRead(beam_stream(i)) > buffer(buffer_no_conv(1,find(buffer_no_conv(2,:)==beam_stream(i))),block(jj,2)+2)*1.2
            if sum(beam_breaks(2).phase==beam_stream(i))==1
                
            %generateTTL(ARDUINO,n);
            beam_breaks(2).broken=1;
            block(jj,8)=toc;

            if block(jj,3)==0
                generate_noise('sine')
            elseif block(jj,3)==1
                generate_noise('noise')
            end
        
            %update RAT GUI
            set(S.RAT,'Visible','off')
            S.RAT = uicontrol('style','text',...
                     'units','pix','position',...
                     rat_positions(arduinoIR2GUI_IR(beam_breaks(2).phase),:),...
                     'string','RAT',...
                     'fontsize',13,'BackgroundColor',[1 0 0]); 
            else
                faulty_trial=1;
                if task_no(jj)==0
                    ARDUINO.digitalWrite(38,0);%SE
                    ARDUINO.digitalWrite(40,0);%outer S
                    ARDUINO.digitalWrite(42,0);%NE
                    ARDUINO.digitalWrite(44,0);%outer N
                    ARDUINO.digitalWrite(46,0);%SW
                    ARDUINO.digitalWrite(48,0);%NW
                elseif task_no(jj)==1
                    ARDUINO.analogWrite(10,0);
                end
                ARDUINO.digitalWrite(34,1); %W
                ARDUINO.digitalWrite(35,1); %W
                S.faulty = uicontrol('style','text',...
                         'units','pix',...
                         'position',[400 410 160 60],...
                         'string','FAULTY TRIAL',...
                         'fontsize',16,'BackgroundColor',[0.2 0.5 0.6]);   
                
            end
        
       end
    end
end

S.phase = uicontrol('style','text',...
 'units','pix',...
 'position',[200 710 120 20],...
 'string','Phase 3',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);


%PHASE 3
led_count=1;
while beam_breaks(3).broken==0 && premature_quit==0 && faulty_trial==0
    %pause(lambda)
    if random_blink==1       
            ARDUINO.digitalWrite(34,0); %W
            ARDUINO.digitalWrite(35,mod(floor(led_count/led_freq),2)); %E
            led_count=led_count+1;
    else 
            ARDUINO.digitalWrite(35,0); %E
            ARDUINO.digitalWrite(34,mod(floor(led_count/led_freq),2)); %W
            led_count=led_count+1;
    end
    for i=3:length(beam_stream)
       if ARDUINO.analogRead(beam_stream(i)) > buffer(buffer_no_conv(1,find(buffer_no_conv(2,:)==beam_stream(i))),block(jj,2)+2)*1.2
           if sum(beam_breaks(3).phase==beam_stream(i))==1
                
           
            %generateTTL(ARDUINO,n);
            beam_breaks(3).broken=1;
            block(jj,9)=toc;
            if beam_stream(i)==14
                block(jj,5)=1;
            elseif beam_stream(i)==15
                block(jj,5)=0;
            end
            set(S.RAT,'Visible','off')
            S.RAT = uicontrol('style','text',...
                 'units','pix','position',...
                 rat_positions(arduinoIR2GUI_IR(beam_stream(i)),:),...
                 'string','RAT',...
                 'fontsize',13,'BackgroundColor',[1 0 0]); 
            
            
               if beam_stream(i)==10 || beam_stream(i)==11
                   start_arm_response=1;
               else
                   start_arm_response=0;
               end
           else               
                faulty_trial=1;
                ARDUINO.digitalWrite(34,1); %W
                ARDUINO.digitalWrite(35,1); %W
                S.faulty = uicontrol('style','text',...
                         'units','pix',...
                         'position',[400 410 160 60],...
                         'string','FAULTY TRIAL',...
                         'fontsize',16,'BackgroundColor',[0.2 0.5 0.6]); 
           end
        end
    end
end


S.phase = uicontrol('style','text',...
 'units','pix',...
 'position',[200 710 120 20],...
 'string','Phase 4',...
 'fontsize',16,'BackgroundColor',[0.7 0.5 0.6]);

%PHASE 4
while beam_breaks(4).broken==0 && premature_quit==0
   % pause(lambda)
     if random_blink==1 && faulty_trial==0  
            ARDUINO.digitalWrite(34,0); %W
            ARDUINO.digitalWrite(35,mod(floor(led_count/led_freq),2)); %E
            led_count=led_count+1;
    elseif random_blink==2 && faulty_trial==0
            ARDUINO.digitalWrite(35,0); %E
            ARDUINO.digitalWrite(34,mod(floor(led_count/led_freq),2)); %W
            led_count=led_count+1;
    end
    
    
    for ch=1:length(beam_breaks(4).phase)
        if ARDUINO.analogRead(beam_breaks(4).phase(ch)) > buffer(buffer_no_conv(1,find(buffer_no_conv(2,:)==beam_breaks(4).phase(ch))),block(jj,2)+2)*1.2

            %generateTTL(ARDUINO,n);
            beam_breaks(4).broken=1;
            block(jj,10)=toc;
            
            
             
            %close relevant platform(s)
            if beam_breaks(4).phase(ch)==3%E
               platform(ARDUINO,1,3,1,arduino_channel_blinking(random_blink),0);
                           
            elseif beam_breaks(4).phase(ch)==2
               platform(ARDUINO,2,3,1,arduino_channel_blinking(random_blink),0);       
               
            end
            
            %update RAT GUI
            set(S.RAT,'Visible','off')
            S.RAT = uicontrol('style','text',...
                 'units','pix','position',...
                 rat_positions(arduinoIR2GUI_IR(beam_breaks(4).phase(ch)),:),...
                 'string','RAT',...
                 'fontsize',13,'BackgroundColor',[1 0 0]); 
             
            trial_end=1;
            %turning off cues
            clear sound
            if task_no(jj)==0
                ARDUINO.digitalWrite(38,0);%SE
                ARDUINO.digitalWrite(40,0);%outer S
                ARDUINO.digitalWrite(42,0);%NE
                ARDUINO.digitalWrite(44,0);%outer N
                ARDUINO.digitalWrite(46,0);%SW
                ARDUINO.digitalWrite(48,0);%NW
            elseif task_no(jj)==1
                ARDUINO.analogWrite(10,0);
            end
                ARDUINO.digitalWrite(34,1); %W
                ARDUINO.digitalWrite(35,1); %W
                
            feeder_delay=0;
            %SPATIAL TASK
            if faulty_trial==1
            set(S.faulty,'Visible','off')
                block(jj,6)=1;
                block(jj,4)=0;
                if beam_breaks(4).phase(ch)==3
                    starting_platform=1;
                elseif beam_breaks(4).phase(ch)==2
                    starting_platform=2;
                end
                    
            else
                block(jj,6)=0;
                if forage==0
                    if block(jj,2)==0
                        if beam_breaks(4).phase(ch)==3 && block(jj,3)==0            
                            pause(feeder_delay)
                            if start_arm_response==0
                                block(jj,4)=1; %correct choice!
                                %deliver reward
                                ARDUINO.digitalWrite(31,1);
                                pause(feeder_pause(2,2));
                                ARDUINO.digitalWrite(31,0)
                            else
                                block(jj,4)=2; %start arm
                            end

                            %generateTTL(ARDUINO,n);10
                            starting_platform=1;

                        elseif beam_breaks(4).phase(ch)==3 && block(jj,3)==1  

                            pause(feeder_delay)
                            if start_arm_response==0
                                block(jj,4)=0; %wrong choice :(
                            else
                                block(jj,4)=2; %start arm
                            end
                            %generateTTL(ARDUINO,n);
                            starting_platform=1;

                        elseif beam_breaks(4).phase(ch)==2 && block(jj,3)==1%W
                            pause(feeder_delay)
                            if start_arm_response==0

                                block(jj,4)=1; %correct choice!
                                %deliver reward

                                ARDUINO.digitalWrite(30,1);
                                pause(0.2);
                                ARDUINO.digitalWrite(30,0)
                            else
                                block(jj,4)=2; %start arm
                            end

                            %generateTTL(ARDUINO,n);
                            starting_platform=2;

                        elseif beam_breaks(4).phase(ch)==2 && block(jj,3)==0%W                  

                            pause(feeder_delay)
                            if start_arm_response==0
                                block(jj,4)=0; %wrong choice :(
                            else
                                block(jj,4)=2; %start arm
                            end
                            %generateTTL(ARDUINO,n);
                            starting_platform=2;

                        end

                    %CUE APPROACH TASK
                    elseif block(jj,2)==1
                        if beam_breaks(4).phase(ch)==3 && block(jj,3)==0 && blinking_platform==1            

                            block(jj,4)=1; %correct choice!
                            %deliver reward
                            pause(feeder_delay)
                            ARDUINO.digitalWrite(31,1);
                            pause(0.07);
                            ARDUINO.digitalWrite(31,0)
                            %generateTTL(ARDUINO,n);   
                            starting_platform=1;


                        elseif beam_breaks(4).phase(ch)==3 && block(jj,3)==0 && blinking_platform==2

                            pause(0.5)
                            %generateTTL(ARDUINO,n);
                            block(jj,4)=0; %wrong choice :(
                            starting_platform=1;

                        elseif beam_breaks(4).phase(ch)==3 && block(jj,3)==1 && blinking_platform==2   

                            block(jj,4)=1; %correct choice!
                            %deliver reward
                            pause(feeder_delay)
                            ARDUINO.digitalWrite(31,1);
                            pause(0.07);
                            ARDUINO.digitalWrite(31,0)  
                            %generateTTL(ARDUINO,n);
                            starting_platform=1;

                        elseif beam_breaks(4).phase(ch)==3 && block(jj,3)==1 && blinking_platform==1    

                            pause(0.5)
                            %generateTTL(ARDUINO,n);
                            block(jj,4)=0; %wrong choice :(
                            starting_platform=1;



                        elseif beam_breaks(4).phase(ch)==2 && block(jj,3)==0 && blinking_platform==1 %W

                            pause(0.5)
                            %generateTTL(ARDUINO,n);
                            block(jj,4)=0; %wrong choice :(
                            starting_platform=2;

                        elseif beam_breaks(4).phase(ch)==2 && block(jj,3)==0 && blinking_platform==2 %W   

                            block(jj,4)=1; %correct choice!
                            %deliver reward
                            pause(feeder_delay)
                            ARDUINO.digitalWrite(30,1);
                            pause(0.2);
                            ARDUINO.digitalWrite(30,0)                   
                            %generateTTL(ARDUINO,n);
                            starting_platform=2;

                        elseif beam_breaks(4).phase(ch)==2 && block(jj,3)==1 && blinking_platform==1   

                            block(jj,4)=1; %correct choice!
                            pause(feeder_delay)
                            %deliver reward
                            ARDUINO.digitalWrite(30,1);
                            pause(0.2);
                            ARDUINO.digitalWrite(30,0)
                            %generateTTL(ARDUINO,n);
                            starting_platform=2;

                        elseif beam_breaks(4).phase(ch)==2 && block(jj,3)==1 && blinking_platform==2   

                            pause(0.5)
                            %generateTTL(ARDUINO,n);
                            block(jj,4)=0; %wrong choice :(
                            starting_platform=2;
                        end

                    end
                else
                    if beam_breaks(4).phase(ch)==3   
                            pause(feeder_delay)
                            block(jj,4)=100; %forage!
                            %deliver reward
                            ARDUINO.digitalWrite(31,1);
                            pause(feeder_pause(4,2));
                            ARDUINO.digitalWrite(31,0)
                            starting_platform=1;

                    elseif beam_breaks(4).phase(ch)==2

                            pause(feeder_delay)
                            block(jj,4)=100; %forage!
                            %deliver reward
                            ARDUINO.digitalWrite(30,1);
                            pause(feeder_pause(3,2));
                            ARDUINO.digitalWrite(30,0) 
                            starting_platform=2;

                    end



                end
            end
             %close other platform
            if beam_breaks(4).phase(ch)==3%E           
               platform(ARDUINO,2,3,1,0,0);         
            elseif beam_breaks(4).phase(ch)==2
               platform(ARDUINO,1,3,1,0,0);             
            end


        end
    end
end




%saving temp files

    cd(Session_Folder)
    trial_temp_save=strcat('temp files-trial',num2str(jj),'-',date);
    cd(temp_save_file_folder)
    save(trial_temp_save,'block')
    cd(ROOT)
    if forage==0
        pause(10)
    elseif forage==1
        pause(30)
    end
else
    break
end

end
%=========END OF TRIALS ================******END OF TRIALS****===========
if premature_quit==0
save_session()
cd(ROOT)
end
end%END OF SESSION FUNCTION - END OF SESSION FUNCTION

%%
%===========================================================================
%                       AUXILIARY FUNCTIONS
%===========================================================================


%save dialog function
function save_session(varargin)
    
clear sound
ARDUINO.digitalWrite(34,1); %W
ARDUINO.digitalWrite(35,1); %W 

ARDUINO.digitalWrite(38,0);%SE
ARDUINO.digitalWrite(40,0);%outer S
ARDUINO.digitalWrite(42,0);%NE
ARDUINO.digitalWrite(44,0);%outer N
ARDUINO.digitalWrite(46,0);%SW
ARDUINO.digitalWrite(48,0);%NW

ARDUINO.analogWrite(10,0);



close all
D.f = figure('Position',[460,400,280,110])  ;    
set(D.f, 'menubar', 'none');
set(gcf,'numbertitle','off','name','Save Session - Shapiro Lab')
D.message = uicontrol('style','text',...
             'units','pix',...
             'position',[10 60 260 40],...
             'string','Would you like to save the session?',...
             'fontsize',15);

D.yes = uicontrol('style','push',...
             'units','pix',...
             'position',[10 10 125 40],...
             'string','Yes',...
             'fontsize',15,...
              'Callback', @yes);
D.quit = uicontrol('style','push',...
             'units','pix',...
             'position',[145 10 125 40],...
             'string','No',...
             'fontsize',15,...
              'Callback', @no);
end


%actually saves the data
function yes(varargin)
    
    final_correct=sum(block(:,4)==1)/sum(isnan(block(:,4))==0);
    fprintf('Raw score for the session: %i \n',final_correct)
    regime={'E','W','blink','solid','E and W','blink and solid',...
           'E/W/E','blink/solid/blink','W/E/blink/solid (4 blocks)',...
           'W/E/blink/solid (8 blocks)','W/E/blink/solid (12 blocks)','full task','forage'};

    data=struct();
    data.block=block;
    data.FC=final_correct;
    if ~isempty(Notes)
    data.notes=Notes;
    end
    data.regime=regime{Training_Sel};
    
    cd(Session_Folder)
    save(strrep(strcat('experiment:',experiment,'-rat: ',exp_RAT,'-date: ',date,'=',num2str(now)),'.','-'),'data')
    close all
    cd(ROOT)

end


%closes out the program
function no(varargin)
    close all
   
end
%quits the session
function quit_session(varargin)
premature_quit=1;
save_session()
cd(ROOT)
end 
%generates sound cues
function generate_noise(which)
    toneFreq = 300; 
    nSeconds = 300; 

    if strcmp(which,'sine')
        sound(sin(linspace(0, nSeconds*toneFreq*2*pi, round(nSeconds*1000))), 1000);  
    elseif strcmp(which,'noise')
        sound(rand(1,12000000), 100000);
    end
end
%traces out relevant trial trajectory
function analog_channel=relevant_phase_beam(plat,start_arm,phase)
  if phase==1
        if plat==1 && start_arm==1
           analog_channel=8;
       elseif plat==1 && start_arm==0
           analog_channel=9;
       elseif plat==2 && start_arm==1
           analog_channel=13;
       elseif plat==2 && start_arm==0
           analog_channel=12;
        end
  end
  if phase==2
     if start_arm==0
         analog_channel=11;
     elseif start_arm==1
         analog_channel=10;
     end
  end
  if phase==3
      if start_arm==0
          analog_channel=[10 14 15];
      elseif start_arm==1
          analog_channel=[11 14 15];
      end      
  end
end
%channel converter function for ease
function k=arduinoIR2GUI_IR(achan)
   converter=[3 2 8 9 10 11 12 13 14 15;...
              1 2 4 6 8 7 5 3 9 10];
   k=converter(2,find(converter(1,:)==achan));
end
%randomly selects start,task, and goal sequences
function SS=create_session_seqs(is,SB120)
    first_trial_seq=[0 0 0;0 0 1;0 1 1;0 1 0;...
                     1 0 0;1 0 1;1 1 1;1 1 0];
    today_first_seq=first_trial_seq(is,:);
    k=nan(1,3);
    for i=1:length(k)
        temp=find(SB120(1,:)==today_first_seq(i));
        k(1,i)=temp(randi(length(temp),1));
    end
    SS=SB120(:,k);

end


function rseq=reversal_generator(no_trials,no_rev)


rseq=nan(no_trials,1);
start_seq=randi(2,1)-1;

for i=1:no_rev
    rseq(1+(i-1)*floor(no_trials/no_rev):i*floor(no_trials/no_rev),1)=...
        ones(floor(no_trials/no_rev),1)*mod(start_seq+i,2);
end

if rem(no_trials,no_rev)~=0
    rseq(isnan(rseq))=[];
end
end

function []=generateTTL(A,n)
%n is what pulse you want














A.pinMode(14,'output')
a=0.003;b=0.023;

seq1=[a a a a b b b b a a a a b b b b];
seq2=[a a b b a a b b a a b b a a b b];
seq3=[a b a b a b a b a b a b a b a b];
seq4=[a a a a a a a a b b b b b b b b];

A.digitalWrite(14,1);pause(0.0001);A.digitalWrite(14,0);
pause(seq1(n))
 A.digitalWrite(14,1);pause(0.0001);A.digitalWrite(14,0);
 pause(seq2(n))
  A.digitalWrite(14,1);pause(0.0001);A.digitalWrite(14,0);
   pause(seq3(n))
  A.digitalWrite(14,1);pause(0.0001);A.digitalWrite(14,0);
    pause(seq4(n))
   A.digitalWrite(14,1);pause(0.0001);A.digitalWrite(14,0);
end

function Iw=platform(A,M,Iw,n,led,S)
%platform(A,M,n,Iw)
%-> A is arduino object
%-> M is motor # 1=E 2=W
%-> n is position you want: 1=closed, 2=south, 3=East/West, 4=north
%-> Iw is current position of platform
%-> must calibrate, start session in closed position
% -> led is blinking LED
%-> S is sensor to check

%determing speed of Motors
speed='fast';
%calculating number of turns
mvt=n-Iw;



%determining direction of movement
dir=[-1 1];
if abs(mvt)==2
    direction=dir(randi(2,1));
    speed='fast';
    wobble=1;
elseif abs(mvt)>0 && abs(mvt)~=2
    mvt=1; wobble=1;
    if Iw==1 && n==2
        direction=-1;
    elseif Iw==1 && n==4
        direction=1;
    elseif Iw==2 && n==1
        direction=1;
    elseif Iw==2 && n==3
        direction=-1;
    elseif Iw==3 && n==2
        direction=1;
    elseif Iw==3 && n==4
        direction=-1;
    elseif Iw==4 && n==3
        direction=1;
    elseif Iw==4 && n==1
        direction=-1;
    end
elseif abs(mvt)==0
        direction=-1;
end
%determining which sensor to read from
if M==1
    sensor=7;
elseif M==2
    sensor=6;
end


c=1;
for i=1:abs(mvt)
beam_break=0;
    %jump start
    mystepper(A,M,speed,40*direction)
    while beam_break<1
        if led~=0
          A.digitalWrite(led,mod(c,2));c=c+1;
        end
       
       if S~=0
           if (ARDUINO.analogRead(S) > buffer(buffer_no_conv(1,find(buffer_no_conv(2,:)==S)),block(jj,2)+2)*1.2) && speedy_rat==0
              block(jj,7)=toc;

              if block(jj,3)==0
                generate_noise('sine')
              elseif block(jj,3)==1
                generate_noise('noise')
              end
              speedy_rat=1;
           end
       end  
        
          mystepper(A,M,speed,20*direction)   
          if A.digitalRead(sensor)==0
              beam_break=beam_break+wobble;
          end
    end

end

%assigning new current position
Iw=n;



end







end%END OF BEHAVIOR PROGRAM FOR AUTOMATED MAZE - SHAPIRO LAB - PABLO MARTIN





