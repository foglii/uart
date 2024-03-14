%% Ricevitore 4 PAM

close all;
%clear;

% Specifiche Adalm Pluto
Mypluto=findPlutoRadio
idTX=append('sn:', Mypluto.SerialNum);

%% Definizione Variabili
SamplingRate=1e6;
T_symbol = 1/SamplingRate;   % Tempo di simbolo
fc=2.475e9;
lung_sig = 1000;
cmax=0;
offset=0;
barker = comm.BarkerCode("Length",7,"SamplesPerFrame",7);
barker_code = barker().';
%seq_start=[1,1,0,1,0,1,0,1];
%seq_end=[1,1,1,0,0,0,1,1,];

beta= 0.5; % Fattore di roll-off del filtro
span = 1; % Lunghezza in simboli del filtro
sps = 16;  % Campioni per simbolo (oversampling factor)
% Ricevitore PLuto
rxPluto = sdrrx('Pluto','RadioID',...
    "usb:0",'CenterFrequency',fc,...
    'GainSource','AGC Fast Attack',...
     'Gain',40,...
     'OutputDataType','single',...
     'BasebandSampleRate',SamplingRate,...
     'ShowAdvancedProperties',1,...
     'FrequencyCorrection',0);
cmax=0;
counter=0;
while cmax~=3 && counter<3  
 tic;   
[rxWave,rx_meta]=capture(rxPluto,80000); %ogni 8000 campioni c'è una 
% ripetizione quindi sono 100 volte
toc;
rxWave=rxWave*3/mean(abs(rxWave));
      figure;
t5=0:1:length(rxWave)-1;
plot(t5,rxWave);
title('RxWave');
scatterplot(rxWave);
M=4;

constdiagram = comm.ConstellationDiagram( ...
    'ReferenceConstellation',qammod(0:3,4), ...
    'SamplesPerSymbol',sps, ...
    'SymbolsToDisplaySource','Property', ...
    'SymbolsToDisplay',10000, ...
    'XLimits',[-3.5 3.5], ...
    'YLimits',[-3.5 3.5]);
coarseSync = comm.CoarseFrequencyCompensator( ...
    'Modulation','QAM', ...
    'FrequencyResolution',1, ...
    'SampleRate', 1e6,...
    'SamplesPerSymbol',sps);
  CoarseFreqCompensator = comm.PhaseFrequencyOffset( ...
                'PhaseOffset',              0, ...
                'FrequencyOffsetSource',    'Input port', ...
                'SampleRate',       SamplingRate);

 TimingRec = comm.SymbolSynchronizer( ...
       'TimingErrorDetector',      'Gardner (non-data-aided)', ...
        'SamplesPerSymbol',         2, ...
        'DampingFactor',            0.7, ...
        'NormalizedLoopBandwidth',  0.0005,...
         'DetectorGain',             10);

fineSync = comm.CarrierSynchronizer( ...
    'DampingFactor',0.7, ...
    'NormalizedLoopBandwidth',0.0005, ...
    'SamplesPerSymbol',sps, ...
    'Modulation','QAM');
[syncCoarse,ritardo] = coarseSync(rxWave);
CoarseCompSignal=CoarseFreqCompensator(rxWave,-ritardo);
SymbolSync=TimingRec(CoarseCompSignal);
rxSyncSig = fineSync(SymbolSync);
rxSyncSig=rxSyncSig/mean(abs(rxSyncSig));
constdiagram([rxSyncSig(1:10000) rxSyncSig(30001:40000)])
rxSyncSig=rxSyncSig(30001:end);
offset=0;
while cmax~=3 && offset<sps
      % Design del filtro a coseno rialzato
      rxfilter = comm.RaisedCosineReceiveFilter( ...
      'Shape','Square root', ...
      'RolloffFactor',beta, ...
      'FilterSpanInSymbols',span, ...
      'InputSamplesPerSymbol',sps/2, ...
      'DecimationFactor',sps/2,...
      'Gain',10,...
      DecimationOffset=offset);
      rxFiltSig=rxfilter(rxSyncSig); 
      
      %trovo il primo valore della sequenza
      rxFiltSig=rxFiltSig/mean(rxFiltSig);
      
    %barker_code=[0,0,0,1,1,0,1];
   sigdemod = qamdemod(rxFiltSig,4).';
   sigdemodbin=[];
   for k=1:length(sigdemod)
       temp=decimalToBinaryVector(sigdemod(k),2);
       sigdemodbin=[sigdemodbin,temp];
   end
 [c,lag_start] = xcorr(sigdemodbin,barker_code);
 d=c((20000/sps):end);
      cmax=max(d);
      cmax=round(cmax) 

      offset=offset+1;

end
offset=offset-1;
fprintf('offset di decimazione = %d\n',offset);
if cmax~=3 
    counter=counter+1  
end
end
% while cmax<3
% [syncCoarse,ritardo] = coarseSync(rxWave);
% rxSyncSig = fineSync(syncCoarse);
% rxSyncSig=rxSyncSig/mean(abs(rxSyncSig));
% constdiagram([rxSyncSig(1:10000) rxSyncSig(70001:80000)])
% rxSyncSig=rxSyncSig(80001:end);
% rxFiltSig=rxfilter(rxSyncSig); 
% rxFiltSig=rxFiltSig/mean(rxFiltSig);
% %barker_code=[0,0,0,1,1,0,1];
% sigdemod = pamdemod(rxFiltSig,2).';
%  [c,lag_start] = xcorr(sigdemod,barker_code);
%  d=c(10000:end);
%       cmax=max(d);
%       cmax=round(cmax)
% end 
      figure (4);
t5=0:1:length(rxFiltSig)-1;
plot(t5,rxFiltSig);
title('Segnale Filtrato');
xlabel('')
figure;
stem(lag_start,c)
[i,h,frame]=findDelay(c,lag_start,sigdemodbin);
[data,dataOK] = unpackMessage(frame);
index=1;
while index<10 && dataOK==0
     fprintf('parity check N.%d not passed\n',index);
     c(h:h+24)=zeros(1,25);
     data
     if round(max(c((10000/sps):end)))==3
     [i,h,frame]=findDelay(c,lag_start,sigdemodbin);
     [data, dataOK] = unpackMessage(frame);
     index=index+1;
     else break
     end
end
if dataOK==1
      fprintf('passed parity check N.%d\n',index);
else fprintf('parity check N.%d not passed:exceeded possible tries\n',index);
end
%-------Unpack raw message function---------
% Data una stringa contenente solamente il
% pacchetto su cui bisogna fare l'unpack, 
% ossia seq_start + message + parity +seq_end 

function [data, parityCheck] = unpackMessage(rawData)
    rawData=rawData+'0';
    rawData=char(rawData);
    DecRawData = bin2dec(rawData);
    % mask = '01FF00';      %   se 8 bit 
    mask = '01FFFF';       %se 16 bit
    mask = hexToBinaryVector(mask);
    mask = sprintf('%d',mask);
    mask = bin2dec(mask);
    %Removing seq_start and seq_end
    DecRawData = bitand(DecRawData,mask);
    %DecRawData = bitshift(DecRawData,-8);
    parityBit = mod(DecRawData,2);
    DecRawData = bitshift(DecRawData,-1);
    mask1 = '00FF';
    mask2 = 'FF00';
    mask1 = hexToBinaryVector(mask1);
    mask2 = hexToBinaryVector(mask2);
    mask1 = sprintf('%d',mask1);
    mask1 = bin2dec(mask1);
    mask2 = sprintf('%d',mask2);
    mask2 = bin2dec(mask2);

    str(2) = bitand(DecRawData,mask1);   
    str(1) = bitshift(bitand(DecRawData,mask2),-8);

    data = horzcat(char(str(1)),char(str(2)));

    sum = 0;
    for i = 1 : (length(rawData)-8)
        sum = sum + mod(DecRawData,2);
        DecRawData = bitshift(DecRawData,-1);
    end

    parityCheck = (mod(sum,2) == parityBit);
    
end

function [i,h,frame]=findDelay(c,lag_start,sigdemodbin)
        barker_code=[0,0,0,1,1,0,1];
        %seq_start=[1,1,0,1,0,1,0,1];
        [m,h] = max(c);
        while h<length(c)/2
           c(h)=0;
           [m,h] = max(c);
        end
        i = lag_start(h);
        figure
        plot(lag_start,c,[i i],[-0.5 1],'r:')
        text(i+100,0.5,['Lag: ' int2str(i)])
        ylabel('c')
        axis tight
        title('Cross-Correlation')
        %s1=sigdemod(i+1:end);
        if i>=(10000-24)  %se il campione è a fine cattura
            i=0;
        end
        frame = sigdemodbin((i+1):(i+24));
        figure;
        plot(frame,'x')
        hold on
        plot(barker_code,'go')
        xlim([0,20]);
        hold off
end
