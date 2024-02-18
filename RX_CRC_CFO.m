%% Ricevitore

% ---------- packet 
% 16 bit start sequence 
% 8 bit packet number
% 4 byte data
% 1 byte crc
% 8 bit end sequence 


close all;
load preamble.mat
%clear;

% Specifiche Adalm Pluto
Mypluto=findPlutoRadio
idTX=append('sn:', Mypluto.SerialNum);

% Definizione Variabili
SamplingRate=1e6;
T_symbol = 1/SamplingRate;   % Tempo di simbolo
fc=2.475e9;
lung_sig = 2000;

cmax=0;
offset=0;

Nsearch = 20;

%sequenze conosciute
%seq_start=[1,1,0,1,0,1,0,1];
barker = comm.BarkerCode("Length",13,"SamplesPerFrame",16);
seq_start=barker().';
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
     'FrequencyCorrection',100);

 tic;   
[rxWave,rx_meta]=capture(rxPluto,80000);
toc;
t5=0:1:length(rxWave)-1;
figure,
title('RxWave');
plot(t5,real(rxWave),t5,imag(rxWave));
rxWave=rxWave/mean(abs(rxWave));

% I campioni raccolti sono ora disponibili in rxWave

%% Grafici Segnale Ricevuto
% this will plot the absolute value of the samples

figure
n1 = (0:length(rxWave)-1)/(lung_sig*sps);
plot(n1,rxWave);
title('Segnale Ricevuto')
grid on;
title('Segnale Ricevuto');
xlabel('Numero Trasmissioni');
ylabel('Valori');
axis("padded");

pause

scatterplot(rxWave);
pause
M=2;

constdiagram = comm.ConstellationDiagram( ...
    'ReferenceConstellation',pammod(0:M-1,M), ...
    'ChannelNames',{'Before convergence','After convergence'}, ...
    'ShowLegend',true, ...
    'SamplesPerSymbol',sps, ...
    'SymbolsToDisplaySource','Property', ...
    'SymbolsToDisplay',10000, ...
    'XLimits',[-1.5 1.5], ...
    'YLimits',[-1.5 1.5]);
coarseSync = comm.CoarseFrequencyCompensator( ...
    'Modulation','PAM', ...
    'FrequencyResolution',1, ...
    'SampleRate', 1e6,...
    'SamplesPerSymbol',sps);

fineSync = comm.CarrierSynchronizer( ...
    'DampingFactor',0.7, ...
    'NormalizedLoopBandwidth',0.0005, ...
    'SamplesPerSymbol',sps, ...
    'Modulation','PAM');
[syncCoarse,ritardo] = coarseSync(rxWave);
rxSyncSig = fineSync(syncCoarse);
rxSyncSig=rxSyncSig/mean(abs(rxSyncSig));
constdiagram([rxSyncSig(1:10000) rxSyncSig(70001:80000)])
rxSyncSig=rxSyncSig(70001:end);
%preamble=txNorm_c(1:sps*length(seq_start));
%[cplus,lag_start] = xcorr(pamdemod(rxSyncSig,2),pamdemod(barker_code);
[cplus,lag_start] = xcorr(rxSyncSig,preamble);
figure
plot(abs(cplus))
[peak,idx_shift]=max(abs(cplus));  % Trovo il picco della xcorr
if idx_shift>15000
    tmp=cplus;
    tmp(15000:end)=0;
    [peak,idx_shift]=max(abs(tmp));
end 
sample_shift=idx_shift-length(rxSyncSig)+1; %Questo è lo shift da applicare



% Qui controllate se ricevete dritto o girato di 180°
% L'unico modo per "raddrizzarlo" automaticamente
% sarebbe usare una sequenza di training
% Fate un check se vi viene bit error rate vicino a 1 o vicino a zero
% oppure controllate lo start bit che dovrebbe essere 1, se vi viene zero
% girate tutto (questo però è rischioso con BER alti)
a=rxSyncSig(sample_shift:end); %prendo giusto il pezzo da dove inizia
figure,
plot(real(a)) % -a perchè mi viene girata di 180°
hold on, grid on,
plot(real(preamble))



% Design del filtro a coseno rialzato
rxfilter = comm.RaisedCosineReceiveFilter( ...
    'Shape','Square root', ...
    'RolloffFactor',beta, ...
    'FilterSpanInSymbols',span, ...
    'InputSamplesPerSymbol',sps, ...
    'DecimationFactor',sps,...
    'Gain',10,...
    DecimationOffset=offset);
%^ Per evitare di usare l'offset qui ci si può allineare prima
% con la cross correlazione


% Il meno è per via del fatto che viene girato di 180°
rxFiltSig=rxfilter(rxSyncSig(sample_shift:end)); 
[~,b]=biterr(pamdemod(rxFiltSig((span+1):(span+16)),2),pamdemod(seq_start,2).');
if b>0.5
    rxFiltSig=-rxFiltSig;
end


rxFiltSig=rxFiltSig/mean(abs(rxFiltSig));

% Check sull'allineamento del segnale (con buon SNR si vede chiaramente)
figure
plot(real(rxFiltSig((span+1):end)))
hold on, grid on,
plot(real(sig_c));


 
 constDiagram = comm.ConstellationDiagram( ...
     'ReferenceConstellation',pammod(0:M-1,M), ...
    'ChannelNames',{'Sequenza Filtrata'}, ...
    'ShowLegend',true, ...    
     'XLimits',[-1.5 1.5], ...
     'YLimits',[-1.5 1.5]);


constDiagram(rxFiltSig)
sigdemod=pamdemod(rxFiltSig(span+1:end),2).';
clear readData; 
readData = struct; 

readData.packNumber = [];      
readData.data = [];
readData.crcOK = [];
readData.i=[];
readData.flag=[];
frame=sigdemod(1:72);
sigdemod_f=sigdemod;
sigdemod_f(1:72)=zeros(1,72);
i=1;
for index=1:floor((length(sigdemod)/72)-1)

    readData(index).i=i;
    [readData(index).packNumber, readData(index).data, readData(index).crcOK] = unpackMessage(frame);
    readData(index).flag=0;
    [i,sigdemod_f,frame]=findDelay(seq_start,sigdemod_f);
    if frame==0
         [i,sigdemod_f,frame]=findDelay(seq_start,sigdemod_f);
    end
   

end
% for i=0:72:length(sigdemod)-72
%     
% frame=sigdemod(1+i:72+i).';
% index=1+i/72;
% [readData(index).packNumber, readData(index).data, readData(index).crcOK] = unpackMessage(frame);
% end

%trova numero pacchetti totale 
Npack = readData(1).packNumber; 
for index=2:floor((length(sigdemod)/72)-1)
    
    if (readData(index).crcOK == 1)
        
        if (readData(index).packNumber>Npack)
             Npack = readData(index).packNumber;
        end      
    end
end

in=1;
index = 1;
word = '';
while index<=Npack
    
    while in<=floor((length(sigdemod)/72)-1)

        if (readData(in).crcOK == 1 & readData(in).packNumber == index)
                word = [ word readData(in).data]; %concatena tutte le parole in base al loro indice 
                readData(in).flag=1;
                index= index + 1;
                in=1;
                  
        end
        in =in +1;

    end
      
end

fprintf('Hai ricevuto:\n %s', word)
%%EVM

counter=0;
for n=1:length(readData)
    if readData(n).flag==1
     counter=counter+1;
     A=real(rxFiltSig(span+2+readData(n).i:span+readData(n).i+73));
     B=imag(rxFiltSig(span+2+readData(n).i:span+readData(n).i+73));
     dist1(counter,1:72)=sqrt((1-A).^2+B.^2);
     dist_1(counter,1:72)=sqrt((-1-A).^2+B.^2);
    end
end
evm=min(dist1,dist_1);
evm_medio=mean(reshape(evm.',1,Npack*72))





% cros(h:h+63)=0;
% 
% 
% 
% 
% 
% 
% 
% 
% figure (20)
% plot(i_cros,cros)
% 
% pause
% 
% %clear readData; 
% readData = struct; 
% 
% readData.packNumber = [];      
% readData.data = [];
% readData.crcOK = [];
% 
% 
% [i,h,frame]=findDelay(cros,i_cros,sigdemod);
% [readData(1).packNumber, readData(1).data, readData(1).crcOK] = unpackMessage(frame);
% 
% cros(h:h+63)=0;
% 
% 
% for index=2:Nsearch
%       %azzera cross per pacchetti successivi 
%      [i,h,frame]=findDelay(cros,i_cros,sigdemod);
% 
%      [readData(index).packNumber, readData(index).data, readData(index).crcOK] = unpackMessage(frame);
%      cros(h:h+63)=0;
% end
% 
%            
% %trova numero pacchetti totale 
% for index=(1:Nsearch)
%     
%     if (readData(index).crcOK == 1)
%         Npack = readData(index).packNumber; 
%         
%         if (readData(index).packNumber>Npack)
%              Npack = readData(index).packetNumber;
%         end      
%     end
% end
% 
% in=1;
% index = 1;
% word = '';
% 
% while (index<=Npack)
%     
%     while (in<=Nsearch)
% 
%         if (readData(in).crcOK == 1 & readData(in).packNumber == index)
%                 word = [ word readData(in).data]; %concatena tutte le parole in base al loro indice 
%                 
%                 index= index + 1;
%                 in=1;
%                   
%         end
%         in =in +1;
% 
%     end
%       
% end
% 
% fprintf('Hai ricevuto:\n %s', word)
% 
% 
%% Funzione che spacchetta messaggio
% installa data aquisition toolbox

% Data una stringa contenente solamente il
% pacchetto su cui bisogna fare l'unpack, 
% ossia seq_start + message + parity +seq_end 

%[readData(1).packNumber, readData(1).data, readData(1).crcOK] = unpackMessage(frame);
function [packetNum, data, crcCheck] = unpackMessage(rawData)
    
    packetNum = rawData(17:24);

    char1 = rawData(25:32);
    char2 = rawData(33:40);
    char3 = rawData(41:48);
    char4 = rawData(49:56);

    dati= rawData(25:56);

     char1= char1 +'0';  
     char1 =char(char1);
     char1=bin2dec(char1);
     char1= char(char1);

      char2= char2 +'0';  
     char2 =char(char2);
     char2=bin2dec(char2);
     char2= char(char2);

      char3= char3 +'0';  
     char3 =char(char3);
     char3=bin2dec(char3);
     char3= char(char3);

      char4= char4 +'0';  
     char4 =char(char4);
     char4=bin2dec(char4);
     char4= char(char4);
    
    data = [char1 char2 char3 char4];

    crc_data = rawData(57:64);
    
    base_crc = [packetNum dati];
    
    crc8 = comm.CRCGenerator('Polynomial','z^8 + z^2 + z + 1');

    t = crc8(double(base_crc.'));
    crc = t(end-8+1:end).';
    
    crcCheck = isequal(crc_data,crc);

    packetNum = packetNum +'0';  
    packetNum =char(packetNum);
    packetNum=bin2dec(packetNum);


end
% 
% 
% [i,h,frame]=findDelay(cros,seq_start,sigdemod);
%%
function [i,sigdemod,frame]=findDelay(seq_start,sigdemod)
        [c,c_lag]=xcorr(sigdemod,seq_start);
        [m,h] = max(c);
        i = c_lag(h);
        if i<length(sigdemod)-72
        
%         figure
%         plot(c_lag,c,[i i],[-0.5 1],'r:')
%         text(i+100,0.5,['Lag: ' int2str(i)])
%         ylabel('c')
%         axis tight
%         title('Cross-Correlation')
        %s1=sigdemod(i+1:end);
       
        frame = sigdemod(i+1:i+72);
        else 
           frame=zeros(1,72);
        end
         sigdemod(i+1:i+16)=zeros(1,16);
        % figure;
        % % plot(frame,'x')
        % hold on
        % % plot(seq_start,'go')
        % xlim([0,20]);
        % hold off
end