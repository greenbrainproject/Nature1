%% data pre-processing script for Nature1 (working title) - 17.10.2017, EEGLAB 14.1.1
eeglab

for subjID = [1:32] %% loop
    
%%Load data file    
EEG = pop_loadset('filename',['S' num2str(subjID) '.set'],'filepath','"insert your filepath"');

    
    
%% trimming the edges of the recording
EEG  = pop_eegtrim( EEG, 1000, 1000 , 'post',  1000, 'pre',  1000 );

%% Data downsamling
EEG = pop_resample(EEG, 256);

%% Data filtering
EEG = pop_eegfiltnew(EEG, 0.1, [], 16500, 0, [], 0);
EEG.oldchanlc = EEG.chanlocs

% %   Import channel info
EEG=pop_chanedit(EEG, 'load',{'C:\Users\user\Desktop\66electr.ced' 'filetype' 'autodetect'});


%% Create backup EEG variable before removing eye electrodes
originalEEG = EEG; 

%% Remove eye electrodes
EEG = pop_select( EEG,'nochannel',{'HEOG' 'VEOG'});

%% Create EEG variable after eye electrodes being removed - for later interpolation of electrodes that are removed by cleanrawdata
EEG.oldchanlc2 = EEG.chanlocs


%% Remove line noise using CleanLine
     EEG = pop_cleanline(EEG, 'bandwidth', 2,'chanlist', [1:EEG.nbchan], 'computepower', 0, 'linefreqs', [50 100 150 200 250],...
       'normSpectrum', 0, 'p', 0.01, 'pad', 2, 'plotfigures', 0, 'scanforlines', 1, 'sigtype', 'Channels', 'tau', 100,...
     'verb', 1, 'winsize', 4, 'winstep', 4);

%% Clean continous data
EEG = clean_rawdata(EEG, 5, [0.25 0.75], 0.85, 5, 20, 0.25);


%% Re-reference the data to average
EEG.nbchan = EEG.nbchan+1;
EEG.data(end+1,:) = zeros(1, EEG.pnts);
EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
EEG = pop_reref(EEG, []);
EEG = pop_select( EEG,'nochannel',{'initialReference'});

%% Data epoching
EEG = pop_epoch( EEG, {  '50'  '51'  '52'  '53' }, [-0.6         1.2], 'newname', ' resampled epochs', 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-600  0]);

%% Reject bad trials
EEG = pop_rejkurt(EEG,1,[1:EEG.nbchan] ,5,5,1,1);
EEG = eeg_checkset( EEG );

%% Run Indipendent Components Analysis (ICA) 
EEG = pop_runica(EEG, 'extended',1,'interupt','on');
 
%% Individuate bad ICs using ADJUST
[art, horiz, vert, blink, disc,...
          soglia_DV, diff_var, soglia_K, med2_K, meanK, soglia_SED, med2_SED, SED, soglia_SAD, med2_SAD, SAD, ...
    soglia_GDSF, med2_GDSF, GDSF, soglia_V, med2_V, nuovaV, soglia_D, maxdin]=ADJUST (EEG,'out')

%% Remove bad ICs
EEG = pop_subcomp( EEG, [art], 0);
      
%% Interpolate removed channels
 EEG = pop_interp(EEG, EEG.oldchanlc2, 'spherical')

%% Save pre-processed data
EEG = pop_saveset( EEG, 'filename',['S' num2str(subjID) 'preprocessed.set'],'filepath','"insert output filepath"');

%% clear Workspace
clear all
close all
end
