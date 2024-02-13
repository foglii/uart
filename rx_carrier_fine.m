%% Ricevitore

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
seq_end=[1,1,1,0,0,0,1,1,];
beta= 0.5; % Fattore di roll-off del filtro
span = 7; % Lunghezza in simboli del filtro
sps = 8;  % Campioni per simbolo (oversampling factor)
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
rxWave=rxWave/mean(abs(rxWave));
      figure;
t5=0:1:length(rxWave)-1;
plot(t5,rxWave);
title('RxWave');
scatterplot(rxWave);
M=2;

constdiagram = comm.ConstellationDiagram( ...
    'ReferenceConstellation',pammod(0:M-1,M), ...
    'ChannelNames',{'Before convergence','After convergence'}, ...
    'ShowLegend',true, ...
    'SamplesPerSymbol',1, ...
    'SymbolsToDisplaySource','Property', ...
    'SymbolsToDisplay',1000, ...
    'XLimits',[-1.5 1.5], ...
    'YLimits',[-1.5 1.5]);
coarseSync = comm.CoarseFrequencyCompensator( ...
    'Modulation','PAM', ...
    'FrequencyResolution',1, ...
    'SampleRate', 1e6,...
    'SamplesPerSymbol',sps);

fineSync = comm.CarrierSynchronizer( ...
    'DampingFactor',0.7, ...
    'NormalizedLoopBandwidth',0.005, ...
    'SamplesPerSymbol',1, ...
    'Modulation','PAM');
[syncCoarse,ritardo] = coarseSync(rxWave);
% rxSyncSig = fineSync(syncCoarse);
% rxSyncSig=rxSyncSig/mean(abs(rxSyncSig));
% constdiagram([rxSyncSig(1:10000) rxSyncSig(70001:80000)])
% rxSyncSig=rxSyncSig(70001:end);
offset=0;
%%
while cmax~=3 && offset<sps
      % Design del filtro a coseno rialzato
      rxfilter = comm.RaisedCosineReceiveFilter( ...
      'Shape','Square root', ...
      'RolloffFactor',beta, ...
      'FilterSpanInSymbols',span, ...
      'InputSamplesPerSymbol',sps, ...
      'DecimationFactor',sps,...
      'Gain',10,...
      DecimationOffset=offset);
      rxFiltSig=rxfilter(syncCoarse); 
      rxSyncSig = fineSync(rxFiltSig); 
      rxSyncSig=rxSyncSig/mean(abs(rxSyncSig));
      constdiagram([rxSyncSig(1:1000) rxSyncSig(4001:5000)]);
      rxSyncSig2=rxSyncSig(4001:5000);
     % rxFiltSig=rxfilter(rxSyncSig); 
      %trovo il primo valore della sequenza
    %barker_code=[0,0,0,1,1,0,1];
   sigdemod = pamdemod(rxSyncSig2,2).';
 [c,lag_start] = xcorr(sigdemod,barker_code);
 d=c((1000):end);
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
[i,h,frame]=findDelay(c,lag_start,sigdemod);
[data,dataOK] = unpackMessage(frame);
index=1;
while index<5 && dataOK==0
     fprintf('parity check N.%d not passed\n',index);
     c(h-33:h+33)=zeros(1,67);
     data
     [i,h,frame]=findDelay(c,lag_start,sigdemod);
     [data, dataOK] = unpackMessage(frame);
     index=index+1;
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

function [i,h,frame]=findDelay(c,lag_start,sigdemod)
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
        frame = sigdemod((i+1):(i+24));
        figure;
        plot(frame,'x')
        hold on
        plot(barker_code,'go')
        xlim([0,20]);
        hold off
end

   



