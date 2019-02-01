function calibrate_eyelink(config)   % modified from eyecal_gka

import brains.calibrate.sharedWorkspace;
import brains.calibrate.escapeHandler;
import brains.calibrate.sleepWithKbCheck;

KbName('UnifyKeyNames' );

fullRect = config.SCREEN.rect;

targShape = 50;
targShape = [ -targShape, -targShape; targShape, targShape ];
adjust_x = 0;

img_path = fullfile( fileparts(which('brains.calibrate.EYECALWin')), 'images' );
Pictures=1; %Enter 1 to show Monkey Pictures, Enter 0 for original squares
NumMonkeys=5; %Number of monkeys to show per trial/fixation point

nCalPts = 5;
dummymode = 0; % Abort if false input
% Define some basic constants:
const.monkeyScreen = 0;
const.nScreens = 1;
const.interTrial = 1; %seconds
const.bgColor = [0 0 0];

if ~EyelinkInit(dummymode) %Initialize Eyelink
    fprintf('Eyelink Init aborted.\n');
    cleanup;
    return;
end
if Eyelink('IsConnected')~=1 && ~dummymode %Verify connection to Eyelink
    cleanup;
    return;
end

[window, wRect] = Screen( 'OpenWindow', const.monkeyScreen, const.bgColor, fullRect );%#ok<*NASGU>

const.screenCenter = round([mean(wRect([1 3])) mean(wRect([2 4]))]);
startEyelinkCal(wRect, nCalPts); % Open communications with Eyelink and put it into calibration mode


KbName('UnifyKeyNames');
keyHandlers(1).key = 'ESCAPE'; % Terminate the task
keyHandlers(1).func = @escapeHandler;  % keyHandlers(1).func = @(x,y,z)(<cmd>) or
keyHandlers(1).wake = true;            % keyHandlers(1).func = @Name Of Function
keyHandlers(2).key = 'j';
%keyHandlers(2).func = @()(fprintf(serialthing,'%s','2'));  % or keyHandlers(2).func = {@J1, 100}; ... using empty func, (), is slightly fater

% Screen('CopyWindow',blankScreen,window,wRect,wRect); % Sync with the screen
Screen('Flip',window);

% Create a "shared workspace" to store data that needs to be accessed by multiple functions, but isn't appropriate for passing as arguments:
sharedWorkspace EYECALWin -clear;
sharedWorkspace('EYECALWin', 'keepGoing', true);

trialNum = 0;

disp('eyecal_gka will display targets in the positions Eyelink expects.');
disp('Simple accept fixation on the Eyelink system, and on the next');
disp('trial, the target will appear in the next location.');
disp('Once you have accepted the entire calibration, the script will exit.');
disp('Or, press escape to abort early.');


%% BEGIN SESSION
while sharedWorkspace('EYECALWin','keepGoing') %global workspace saves values outside of the function
    trialNum = trialNum+1;
    % Beep:
    %%sound(sin(1:.2:400));
    %% Square targets
    if Pictures==0,
        for i=1:2 % Draw the initial fixation target: Just for blinks
            targShape  = [-80 -80; 80  80];
            [dummy, targX, targY] = Eyelink('TargetCheck');
            targRect = shiftPoints(targShape, [targX targY])';
            targRect = targRect(:)';
            COLORS = [255 255 255];
            Screen('FillRect', window, COLORS, targRect);
            Screen('Flip', window);
            WaitSecs(0.1);
            COLORS = [255 0 255];
            Screen('FillRect', window, COLORS, targRect);
            Screen('Flip', window);
            WaitSecs(0.1);
            COLORS = [255 255 0];
            Screen('FillRect', window, COLORS, targRect);
            Screen('Flip', window);
            WaitSecs(0.1);
            COLORS = [0 255 255];
            Screen('FillRect', window, COLORS, targRect);
            Screen('Flip', window);
            WaitSecs(0.1);
        end
        %% Single Monkey pictures
    elseif Pictures==1,
        try
            a=randperm(10);
            imgfile{1}='m1.jpg'; %Load images into memory as cell array
            imgfile{2}='m2.jpg';
            imgfile{3}='m3.jpg';
            imgfile{4}='m4.jpg';
            imgfile{5}='m5.jpg';
            imgfile{6}='m6.jpg';
            imgfile{7}='m7.jpg';
            imgfile{8}='m8.jpg';
            imgfile{9}='m9.jpg';
            imgfile{10}='m10.jpg';
            imgfile = cellfun( @(x) fullfile(img_path, x), imgfile, 'un', false );
            d=1; %multiplier
%             targShape  = [-50 -50; 50  50].*d;
            %targShape  = [-100 -100; 100  100].*d;
            %             targShape  = [-52 -52; 52  52];
            [dummy, targX, targY] = Eyelink('TargetCheck');
            targRect = shiftPoints(targShape, [targX targY])';
            targRect = targRect(:)';
            targRect([1, 3]) = targRect([1, 3]) - adjust_x;
            
%             disp( targRect );
            for b=1:NumMonkeys, %Number of monkeys to show per trial               
            imload=imread(imgfile{a(b)},'jpg');
            Screen('PutImage',window,imload,targRect);
            Screen('Flip', window);
            WaitSecs(0.5);
            end
        catch err
            throw( err );
%             Screen('CloseAll');
%             disp('Picture Error');
        end
    end
    if Eyelink('CurrentMode')~=10
        break;
    end
    %     % Beep:
    %     %%sound(sin(1:.2:400));
    %     % Wait 1 second:
     sleepWithKbCheck(2,keyHandlers);
     sleepWithKbCheck(1,keyHandlers);
    if ~sharedWorkspace('EYECALWin','keepGoing');
        break;
    end       
   
    Screen('Flip', window);
    % Wait the intertrial interval:
    sleepWithKbCheck(const.interTrial,keyHandlers);
    
    if ~sharedWorkspace('EYECALWin','keepGoing');
        break;
    end   
end
%Clean up the screen
Screen('Closeall');
%Eyelink('Shutdown');

% HELPER FUNCTIONS
function startEyelinkCal(winSize, nCalPts)
% Start calibration on Eyelink. winSize is the size of the stimulus window
% being used (ie, the screenRect output from Screen('OpenWindow',...));
% nCalPoints is the number of calibration points to use (should be 3, 5, or
% 9).
% Eyelink('Command', 'formatstring', [...])
Eyelink('command','screen_pixel_coords = %d %d %d %d', winSize(1), winSize(2), winSize(3), winSize(4) );
calType = ['HV' num2str(nCalPts)];
Eyelink('Command', ['calibration_type = ' calType]);
Eyelink('StartSetup');
cont = true;
% Wait until Eyelink actually enters Setup mode (otherwise the
% SendKeyButton command below can happen too quickly and won't actually put
% us in calibration mode):
while cont && Eyelink('CurrentMode')~=2
    % [keyIsDown, secs, keyCode, deltaSecs] = KbCheck([deviceNumber])
    [keyIsDown,secs,keyCode] = KbCheck;
    if keyIsDown && keyCode(KbName('escape'))
        disp('Aborted while waiting for Eyelink!');
        cont = false;
    end
end
% Magic words: Send the keypress 'c' to select "Calibrate"
Eyelink('SendKeyButton',double('c'),0,10);

function newPoints = shiftPoints(points, shift)
% Points should be N-by-2 for N points, shift should be 1-by-2
%newPoints = bsxfun(@plus,points,shift);
shift = repmat(shift, size(points,1), 1);
newPoints = points + shift;


% Cleanup routine:
function cleanup
% Shutdown Eyelink:
Eyelink('Shutdown');

% Close window:
sca;
commandwindow;
% Restore keyboard output to Matlab:
ListenChar(0);

