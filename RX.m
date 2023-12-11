% ---------- packet 
% 8 bit start sequence 
% 8 bit packet number
% 4 byte data
% 1 byte crc
% 8 bit end sequence 


%% Ricevitore

close all;
%clear;

% Specifiche Adalm Pluto
Mypluto=findPlutoRadio
idTX=append('sn:', Mypluto.SerialNum);

% Definizione Variabili
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

% Grafici Segnale Ricevuto
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



% Design del filtro a coseno rialzato

rxfilter = comm.RaisedCosineReceiveFilter( ...
  'Shape','Square root', ...
  'RolloffFactor',beta, ...
  'FilterSpanInSymbols',span, ...
  'InputSamplesPerSymbol',sps, ...
  'DecimationFactor',sps);

rx_signal=rxfilter(rxWave); 

clear readData;

readData.data = [];
readData.crcOK = [];
readData.packNumber = [];

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
[readData(1).data,readData(1).crcOK,readData(1).packNumber] = unpackMessage(frame);
index=1;


while true
    try
     c(h-64:h+64)=zeros(1,129);
     [i,h,frame]=findDelay(c,lag_start,sigdemod);
     [readData(index).data,readData(index).crcOK,readData(index).packNumber] = unpackMessage(frame);
     index = index+1;
    catch
        break
    end
     
end

tmp = readData.packNumber;
maxSeq = max(tmp);
found = 0;
indiceSeq = 1;

word = '';

while maxSeq >= indiceSeq

    found = 0;
    for i=1:(length(readData)-1)

        if indiceSeq == readData(i).packNumber
            
            word = horzcat(word,readData(i).data);
            indiceSeq = indiceSeq + 1;
            found = 1;

        end

    end

    if found ~= 1

        fprintf("Pacchetti ricevuti non validi");
        indiceSeq = indiceSeq + 1;
        % break

    end

end
% if found == 1
    word
% end

%-------Unpack raw message function---------
% Data una stringa contenente solamente il
% pacchetto su cui bisogna fare l'unpack, 
% ossia seq_start + message + parity +seq_end 


function [data, crcCheck,packetNum] = unpackMessage(rawData)

    crc8 = comm.CRCGenerator('Polynomial','z^8 + z^2 + z + 1','InitialConditions',1,'DirectMethod',true,'FinalXOR',1);
    rawData=rawData+'0';
    rawData=char(rawData);
    DecRawData = bin2dec(rawData);

    maskData = '0000000000FF0000';
    maskDataRaw = '0000FFFFFFFF0000';
    maskNumber = '00FF000000000000';
    maskCRC = '000000000000FF00';

    maskData = hexToBinaryVector(maskData);
    maskDataRaw = hexToBinaryVector(maskDataRaw);
    maskNumber = hexToBinaryVector(maskNumber);
    maskCRC = hexToBinaryVector(maskCRC);

    maskData = sprintf('%d',maskData);
    maskDataRaw = sprintf('%d',maskDataRaw);
    maskNumber = sprintf('%d',maskNumber);
    maskCRC = sprintf('%d',maskCRC);

    maskData = bin2dec(maskData);
    maskDataRaw = bin2dec(maskDataRaw);
    maskNumber = bin2dec(maskNumber);
    maskCRC = bin2dec(maskCRC);

    tmp = DecRawData;

    for i=1:4  
        str(5-i) = bitshift(bitand(tmp,maskData),-16);
        tmp = bitshift(tmp,-8);
    end

    data = horzcat(char(str(1)),char(str(2)),char(str(3)),char(str(4)));

    packetNum = bitshift(bitand(DecRawData,maskNumber),-48);

    crc = bitshift(bitand(DecRawData,maskCRC),-8);

    rawData = bitshift(bitand(DecRawData,maskDataRaw),-16);


    codeword = crc8(de2bi(rawData).');
    crcCalc = codeword(end-8+1:end);
    bin2dec(sprintf('%d',crcCalc));
    crcCheck = isequal(crcCalc,crc);
    
end

function [i,h,frame]=findDelay(c,lag_start,sigdemod)

        seq_start=[1,1,0,1,0,1,0,1];
        [m,h] = max(c);
        i = lag_start(h);
        % plot(lag_start,c,[i i],[-0.5 1],'r:')
        text(i+100,0.5,['Lag: ' int2str(i)])
        ylabel('c')
        axis tight
        title('Cross-Correlation')
        %s1=sigdemod(i+1:end);
        if i>=(10000-64)  %se il campione è a fine cattura
            i=0;
        end
        frame = sigdemod(i+1:i+64);
        % figure;
        % % plot(frame,'x')
        % hold on
        % % plot(seq_start,'go')
        % xlim([0,20]);
        % hold off
end

   
