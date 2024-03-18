%% Trasmettitore

% ---------- packet 
% 16 bit start sequence 
% 8 bit packet number
% 4 byte data 
% 1 byte crc
% 8 bit end sequence 

% Specifiche Adalm Pluto

function [txPluto] = TX(dataToSend, reset)
Mypluto=findPlutoRadio;
idTX=append('sn:', Mypluto.SerialNum);

%data_tx = dataTosSend;
% Definizione Parametri
SamplingRate=1e6; % Frequenza di campionamento (Hz)
fc=2.475e9;

% Filtro
beta= 0.5; % Fattore di roll-off del filtro
span = 7; % Lunghezza in simboli del filtro
sps = 8;  % Campionamenti per simbolo (oversampling factor)

% Messaggio
crc8 = comm.CRCGenerator('Polynomial','z^8 + z^2 + z + 1');
%sequenza con bassa correlazione fuori dal picco
barker = comm.BarkerCode("Length",13,"SamplesPerFrame",16);
seq_start = pamdemod(barker().',2);
seq_end=[1,1,1,0,0,0,1,1];

%forma pacchetto come array di struct
packet_struct = struct; 
packet_struct.numberBin = [];
packet_struct.dataRaw = [];
packet_struct.dataBin = [];
packet_struct.crc = [];
%packet_struct.crcNum = [];


%data_tx = 'Lorem ipsum dolor sit amet, consectetur adipisci elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur. Quis aute iure reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint obcaecat cupiditat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.' %stringa che vogliamo trasmettere
dataToSend = strjoin(dataToSend,'');
dataToSend = reshape(string(dataToSend) ,1 , []); % convert matrix to row vector

data_tx = string(dataToSend(1));
for i = 2:1:size(dataToSend)
data_tx = strcat(data_tx,string(dataToSend(i)));
end

data_tx = char(data_tx);
data_tx = data_tx(1:min(1530,length(data_tx)));


if mod(length(data_tx),6)~=0
    data_tx=pad(data_tx,(length(data_tx)+6-mod(length(data_tx),6)))
end

if reset == 0
for  i=1:(ceil(length(data_tx) / 6))
    
    packet_struct(i).numberBin = reshape(dec2bin(i, 8)-'0',[1,8]);
    
    if ((i*6)<length(data_tx)) 
        packet_struct(i).dataRaw = extractBetween(data_tx,(i-1)*6 +1,(i*6)); 
        packet_struct(i).dataBin = reshape((dec2bin(char(packet_struct(i).dataRaw), 8)-'0').',1,[]);

    else
        packet_struct(i).dataRaw = data_tx(((i-1)*6 +1):end);
        packet_struct(i).dataBin = reshape((dec2bin(char(packet_struct(i).dataRaw), 8)-'0').',1,[]);
        
    end


    base_crc = [packet_struct(i).numberBin packet_struct(i).dataBin];

    codeword = crc8(base_crc.');
    packet_struct(i).crc = codeword(end-8+1:end).';
   
   % packet_struct(i).crcNum = bin2dec(sprintf('%d',codeword(end-8+1:end)));

end

message = [seq_start packet_struct(1).numberBin packet_struct(1).dataBin packet_struct(1).crc seq_end];

for i=2:(ceil(length(data_tx) / 6))

    messageTmp = [seq_start packet_struct(i).numberBin packet_struct(i).dataBin packet_struct(i).crc seq_end];
    message = [message messageTmp]; %concatena 

end

elseif reset == 1
    clear packet_struct;
    packet_struct(1).numberBin = reshape(dec2bin(0, 8)-'0',[1,8]);
    packet_struct(1).dataRaw = data_tx; 
    packet_struct(1).dataBin = reshape((dec2bin(char(packet_struct(1).dataRaw), 8)-'0').',1,[]);
    base_crc = [packet_struct(1).numberBin packet_struct(1).dataBin];

    codeword = crc8(base_crc.');
    packet_struct(1).crc = codeword(end-8+1:end).';
    message = [seq_start packet_struct(1).numberBin packet_struct(1).dataBin packet_struct(1).crc seq_end];
end


symbols=message.'; %cosi rimane vettore colonna

% Creazione segnale PAM
sig=pammod(symbols,2);
%sig=vertcat(sig,zeros(4,1));
sig_c=complex(sig);



% Design del filtro a coseno rialzato

txfilter=comm.RaisedCosineTransmitFilter(...
  Shape='Square root', ...
  RolloffFactor=beta, ...
  FilterSpanInSymbols=span, ...
  OutputSamplesPerSymbol=sps);

% normalizzazione per avere a 1 il massimo del filtro 
b = coeffs(txfilter);
txfilter.Gain = 1/max(b.Numerator);

%applico filtro
tx_signal=txfilter(sig_c);

%Risposta in Frequenza del filtro

%il numero di campioni deve essere più lunga del segnale 
% vedo la potenze di due più vicina-> potenza 2 nextpow2
esp = nextpow2(length(tx_signal));
Nfft = 2^esp;
f_ax=(-Nfft/2:Nfft/2-1)/Nfft*SamplingRate;

X=fft(txfilter.coeffs.Numerator,Nfft);
X=fftshift(X);


% Grafico Segnale e Segnale filtrato
%variabile di supporto per grafico è segnale filtrato senza padding di
%zeri
tx_sig=txfilter(sig_c);
tx_sig=vertcat(tx_sig((span*sps/2)+1:end),tx_sig(1:(span*sps/2)));

t= 1000*(0:length(sig_c)-1)*(sps/SamplingRate); 

to = 1000*(0:(length(tx_sig)-1))/SamplingRate;
%vettore dei tempi campionato a frequenza di campionamento in millisecondi

% Trasmissione tramite Adalm Pluto 
txNorm=tx_sig/max(abs(tx_sig));
txNorm_c=complex(txNorm);

txPluto = sdrtx('Pluto',...
       'RadioID',idTX,...
       'CenterFrequency',fc,...
       'Gain',-3, ... %must be between -89 and 0
       'BasebandSampleRate',SamplingRate);

transmitRepeat(txPluto,txNorm_c);
end
%%