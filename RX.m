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
lung_sig = 2000;

beta= 0.5; % Fattore di roll-off del filtro
span = 6; % Lunghezza in simboli del filtro
sps = 8;  % Campioni per simbolo (oversampling factor)
% Ricevitore PLuto
rxPluto = sdrrx('Pluto','RadioID',...
    "usb:0",'CenterFrequency',fc,...
    'GainSource','AGC Fast Attack',...
     'Gain',40,...
     'OutputDataType','single',...
     'BasebandSampleRate',SamplingRate,...
     'ShowAdvancedProperties',1,...
     'FrequencyCorrection',100);

   
 tic;   
[rxWave,rx_meta]=capture(rxPluto,80000);
toc;

% I campioni raccolti sono ora disponibili in rxWave

%% Grafici Segnale Ricevuto
% this will plot the absolute value of the samples

figure(1)
n1 = (0:length(rxWave)-1)/(lung_sig*sps);
plot(n1,rxWave);
title('Segnale Ricevuto')
grid on;
title('Segnale Ricevuto');
xlabel('Numero Trasmissioni');
ylabel('Valori');
axis("padded");



figure(2);
n1 = (0:length(rxWave)-1)/(lung_sig*sps);
plot(n1,abs(rxWave));
grid on;
title('Modulo del Segnale Ricevuto');
xlabel('Numero di Trasmissioni');
ylabel('Valori');
axis("padded");

scatterplot(rxWave);



%% Design del filtro a coseno rialzato

rxfilter = comm.RaisedCosineReceiveFilter( ...
  'Shape','Square root', ...
  'RolloffFactor',beta, ...
  'FilterSpanInSymbols',span, ...
  'InputSamplesPerSymbol',sps, ...
  'DecimationFactor',sps);

rx_signal=rxfilter(abs(rxWave)); 

%correzione delay rx
%rx_signal= rx_signal((span*sps/2)+1:end);

figure (4);
t5=0:1:length(rx_signal)-1;
plot(t5,rx_signal);
title('Segnale Filtrato');
xlabel('')
rxNorm=abs(rx_signal)/max(abs(rx_signal));
%trovo il primo valore della sequenza
seq_start=[1,1,0,1,0,1,0,1];
seq_end=[1,1,1,0,0,0,1,1,];
for k=1:length(rxNorm)
    if rxNorm(k)>0.5
        sigdemod(k)=1;
    else sigdemod(k)=0;
    end
end
[c,lag_start] = xcorr(sigdemod,seq_start);
%c=c/max(c);
figure;
stem(lag_start,c)
[i,h,frame]=findDelay(c,lag_start,sigdemod);
[data,dataOK] = unpackMessage(frame);
index=1;
while index<6 && dataOK==0
     fprintf('parity check N.%d not passed\n',index);
     c(h-33:h+33)=zeros(1,67);
     [i,h,frame]=findDelay(c,lag_start,sigdemod);
     [data, dataOK] = unpackMessage(frame);
     index=index+1;
end
if dataOK==1
      fprintf('passed parity check N.%d\n',index);
else fprintf('exceeded possible tries\n');
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
    mask = '1FFFF00';       %se 16 bit
    mask = hexToBinaryVector(mask);
    mask = sprintf('%d',mask);
    mask = bin2dec(mask);
    %Removing seq_start and seq_end
    DecRawData = bitand(DecRawData,mask);
    DecRawData = bitshift(DecRawData,-8);
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
    for i = 1 : (length(rawData)-17)
        sum = sum + mod(DecRawData,2);
        DecRawData = bitshift(DecRawData,-1);
    end

    parityCheck = (mod(sum,2) == parityBit);
    
end

function [i,h,frame]=findDelay(c,lag_start,sigdemod)

        seq_start=[1,1,0,1,0,1,0,1];
        [m,h] = max(c);
        i = lag_start(h);
        plot(lag_start,c,[i i],[-0.5 1],'r:')
        text(i+100,0.5,['Lag: ' int2str(i)])
        ylabel('c')
        axis tight
        title('Cross-Correlation')
        %s1=sigdemod(i+1:end);
        frame = sigdemod(i+1:i+33);
        figure;
        plot(frame,'x')
        hold on
        plot(seq_start,'go')
        xlim([0,20]);
        hold off
end

   
