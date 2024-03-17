%% Ricevitore

% ---------- packet
% 16 bit start sequence
% 8 bit packet number
% 4 byte data
% 1 byte crc
% 8 bit end sequence

function receive(app)
load preamble.mat

%preamble=txNorm_c(1:sps*length(seq_start));
%clear;
%%
% Specifiche Adalm Pluto
Mypluto=findPlutoRadio;
idTX=append('sn:', Mypluto.SerialNum);

% Definizione Variabili
SamplingRate=1e6;
fc=2.475e9;
lung_sig = 88;

try
%sequenze conosciute
barker = comm.BarkerCode("Length",13,"SamplesPerFrame",16);
seq_start=barker().';
seq_end=[1,1,1,0,0,0,1,1,];

beta= 0.5; % Fattore di roll-off del filtro
span = 7; % Lunghezza in simboli del filtro
sps = 8;  % Campioni per simbolo (oversampling factor)

% Ricevitore PLuto
rxPluto = sdrrx('Pluto','RadioID',...
    idTX,'CenterFrequency',fc,...
    'GainSource','AGC Fast Attack',...
    'Gain',40,...
    'OutputDataType','single',...
    'BasebandSampleRate',SamplingRate);

tic;

rxWave=capture(rxPluto,80000);

toc;


rxWave=rxWave/mean(abs(rxWave));

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
%prendo l'ultima parte del segnale, perchè più sincronizzata
rxSyncSig=rxSyncSig(60001:end);

%ci allineiamo pre filtraggio tramite correlazione con un preambolo
[cros,lag_start] = xcorr(rxSyncSig,preamble);

[peak,idx_shift]=max(abs(cros));  % Trovo il picco della xcorr

if idx_shift>30000 || idx_shift<20000 %scelta di un picco nella prima metà della trasmissione
    tmp=cros;
    tmp(30000:end)=0;
    tmp(1:20000)=0;
    [peak,idx_shift]=max(abs(tmp));
end
sample_shift=idx_shift-length(rxSyncSig)+1;
%Questo è lo shift da applicare


% Design del filtro a coseno rialzato
rxfilter = comm.RaisedCosineReceiveFilter( ...
    'Shape','Square root', ...
    'RolloffFactor',beta, ...
    'FilterSpanInSymbols',span, ...
    'InputSamplesPerSymbol',sps, ...
    'DecimationFactor',sps,...
    'Gain',10);


%controllo se ricevo girato di 180° con il preambolo e poi correggo
%plot della parte iniziale
a=rxSyncSig(sample_shift:sample_shift+length(preamble));


%rxFiltSig=rxfilter(rxSyncSig(sample_shift+(span*sps/2)-1:end)); %correggo ritardo filtro
rxFiltSig=rxfilter(rxSyncSig(sample_shift-(span*sps/2)-1:end));
rxFiltSig=rxFiltSig(span+1:end);
[~,b]=biterr(pamdemod(rxFiltSig(1:16),2),pamdemod(seq_start,2).');
if b>0.5
    rxFiltSig=-rxFiltSig;
end



rxFiltSig=rxFiltSig/mean(abs(rxFiltSig));

%Check sull'allineamento del segnale (con buon SNR si vede chiaramente)
sigdemod=pamdemod(rxFiltSig.',2);
% sigdemod=pamdemod(rxFiltSig(span+1:end),2).';


%% Spacchettamento
clear readData;

sbagliato = false;
readData = struct;
readData.packNumber = [];
readData.data = [];
readData.crcOK = [];
readData.endOK=[];
readData.delay=[];
readData.scelto=[];

frame=sigdemod(1:lung_sig);
sigdemod_f=sigdemod;
sigdemod_f(1:lung_sig)=zeros(1,lung_sig);

delay=1;
for index=1:floor((length(sigdemod)/lung_sig)-1)

    readData(index).delay=delay;
    [readData(index).packNumber, readData(index).data, readData(index).crcOK, readData(index).endOK] = unpackMessage(frame);
    readData(index).scelto=0;
    [delay,sigdemod_f,frame]=findDelay(seq_start,sigdemod_f);
    if frame==0
        [delay,sigdemod_f,frame]=findDelay(seq_start,sigdemod_f);
    end


end

% %trova numero pacchetti totale
% Npack = 0;
% sizeData = size(readData);
% for index=1:1: sizeData(2)
% 
%     if (readData(index).crcOK == 1 && readData(index).endOK == 1)
% 
%         if (readData(index).packNumber>Npack)
%             Npack = readData(index).packNumber;
%         end
%     end
% end
% 
% in=1;
% index = 1;
% word = '';
% while index<=Npack
% 
%     while in<=sizeData(2)
% 
%         if (readData(in).crcOK == 1 && readData(index).endOK == 1 && readData(in).packNumber == index)
%             word = [ word readData(in).data]; %concatena tutte le parole in base al loro indice
%             readData(in).scelto=1;
%             index= index + 1;
%             in=0;
% 
%         end
%         in =in +1;
% 
%     end
%     if (in>sizeData(2) && index<=Npack)
%         disp('pacchetto non ricevuto correttamente')
%         sbagliato=true;
%         break;
%     else
%         sbagliato=false;
%     end
% end
% if sbagliato==false
%     fprintf('Hai ricevuto:\n %s', word)
% end

%dataPackApp = [readData.data readData.packNumber readData.crcOK readData.endOK]
for times = 1:1:size(readData,2)
    dataPackApp(times, :) = [string(readData(times).data) , string(readData(times).packNumber) , string(readData(times).crcOK) , string(readData(times).endOK) ];
end

displayD = app.UITableRaw.DisplayData;
displayD = [displayD ; dataPackApp];
app.UITableRaw.Data = displayD;

frase = "";
indice = 0;

for f = 0:1:1530
    for c = 1:1:size(displayD,1)

        if strcmp(displayD(c , 2), string(indice)) && strcmp(displayD(c , 3) , "true") && strcmp(displayD(c , 4) , "true")
            if f == 0
                app.Messaggio.Value = '';
                app.UITableRaw.Data = {'Data Cleared', '0', 'false', 'false'};
                break
            end
            frase = strcat(frase,displayD(c , 1));
            break
        end
    end
    indice = indice + 1;
end
app.Messaggio.Value = sprintf('%s',frase);

catch
end
end


%% Funzione che spacchetta messaggio
%Dato un frame di bit ne estrae il numero del pacchetto, i dati e controlla
%la validità del contenuto

%[readData(1).packNumber, readData(1).data, readData(1).crcOK] = unpackMessage(frame);
function [packetNum, data, crcCheck, endOK] = unpackMessage(rawData)


charVec = zeros(6,8);
seq_end=[1,1,1,0,0,0,1,1,];
packetNum = 0;
data = 0;
crcCheck = 0;
endOK = 0;

if size(rawData,2) == 88

    packetNum = rawData(17:24);
    dati= rawData(25:(24 + 8*6));
    crc_data = rawData(73:80);
    endSeq = rawData((25 + 8*7):24+8*8);

    for d = 1:1:6

        charVec(d,:) = rawData(25 + (8*(d-1)): 24 + 8*d);
        charVec(d,:) = charVec(d,:) +'0';

    end

    charVec = char(charVec);
    charVec =bin2dec(charVec);
    charVec = char(charVec);

    data = charVec.';

    base_crc = [packetNum dati];

    crc8 = comm.CRCGenerator('Polynomial','z^8 + z^2 + z + 1');

    t = crc8(double(base_crc.'));
    crc = t(end-8+1:end).';

    crcCheck = isequal(crc_data,crc);

    packetNum = packetNum +'0';
    packetNum =char(packetNum);
    packetNum=bin2dec(packetNum);

    endOK = strcmp(char(seq_end),char(endSeq));

end

end


function [i,sigdemod,frame]=findDelay(seq_start,sigdemod)

lung_sig = 88;
[c,c_lag]=xcorr(sigdemod,seq_start);
[m,h] = max(c);
i = c_lag(h);

%controllo se il pacchetto è parziale
if i > 0
    if i<length(sigdemod)-lung_sig
        frame = sigdemod(i+1:i+lung_sig);
    else
        frame=zeros(1,lung_sig);
    end
    sigdemod(i+1:i+16)=zeros(1,16);
else
    frame = 0;
end

end
