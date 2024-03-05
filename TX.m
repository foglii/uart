% ---------- packet 
% 8 bit start sequence 
% 8 bit packet number
% 4 byte data
% 1 byte crc
% 8 bit end sequence 


% Trasmettitore

close all;
clear;

% Specifiche Adalm Pluto
Mypluto=findPlutoRadio
idTX=append('sn:', Mypluto.SerialNum);


% Definizione Parametri
SamplingRate=1e6; % Frequenza di campionamento (Hz)
fc=2.475e9;
Nsimboli=1000;
lung_sig = 2000;
T_symbol = 1/SamplingRate; % Tempo di simbolo

% Filtro
beta= 0.5; % Fattore di roll-off del filtro
span = 6; % Lunghezza in simboli del filtro
sps = 8;  % Campionamenti per simbolo (oversampling factor)

% Messaggio
crc8 = comm.CRCGenerator('Polynomial','z^8 + z^2 + z + 1','InitialConditions',1,'DirectMethod',true,'FinalXOR',1);
packetStruct.numberBin = [];
packetStruct.dataRaw = [];
packetStruct.dataBin = [];
packetStruct.crc = [];
symbols=zeros(1,Nsimboli);
seq_start=[1,1,0,1,0,1,0,1];
seq_end=[1,1,1,0,0,0,1,1];


data_tx= 'Albero Birillo'; %stringa che vogliamo trasmettere


for  i=1:(ceil(length(data_tx) / 4))
    
    packetStruct(i).numberBin = reshape(dec2bin(i, 8)-'0',1,8);
    if (((i-1)*4)+4) < length(data_tx) 
        packetStruct(i).dataRaw = extractBetween(data_tx,(i-1)*4 +1 , ((i-1)*4)+4); 
    else
        packetStruct(i).dataRaw = data_tx(((i-1)*4 +1):end)
        for z=0: (3 - (length(data_tx) - ((i-1)*4)))
            packetStruct(i).dataRaw = horzcat(packetStruct(i).dataRaw,' ');
        end
    end
    packetStruct(i).dataBin = reshape((dec2bin(char(packetStruct(i).dataRaw), 8)-'0').',1,[]);
    codeword = crc8(packetStruct(i).dataBin.')
    packetStruct(i).crc = codeword(end-8+1:end).';
    codeword = codeword(end-8+1:end);
    packetStruct(i).crcNum = bin2dec(sprintf('%d',codeword));
    i



end

message = horzcat(seq_start,packetStruct(1).numberBin,packetStruct(1).dataBin,packetStruct(1).crc,seq_end);
message = horzcat(message,zeros(1,250-length(message))); %zero padding

for i=2:(ceil(length(data_tx) / 4))

  messageTmp = horzcat(seq_start,packetStruct(i).numberBin,packetStruct(i).dataBin,packetStruct(i).crc,seq_end);
  messageTmp = horzcat(messageTmp,zeros(1,250-length(messageTmp)));
  message = horzcat(message,messageTmp); %concatena 

end
%trasforma decimale in binario 
%in questo modo rimane una matrice di char quindi tolgo il valore di zero a
%ogni casella per tornare ai double 1 e 0

%da matrice leght data x 8 diventa matrice 1 x (leght data x 8)

%calcolo del parity bit
% sum=0;
% for i=1:length(binArray)
%         if binArray(i)==1 %conta gli uno
%         sum=sum+1;
%         end
% end
% if mod(sum,2)==0 %mod resto della divisione sum/2 per def di parity
%    parity=0;
% else parity=1;
% end 


symbols=message.'; %cosi rimane vettore colonna

% seq_start = sprintf('%d',seq_start);
% seq_end = sprintf('%d',seq_end);
% mes = sprintf('%d',mes);

% Creazione segnale PAM
sig=pammod(symbols,2);
sig=(sig+1)/2; %rendiamo la modulazione unipodale
sig_c=complex(sig);

figure
stem(sig_c,'filled')
title('Segnale')
xlabel('Simboli')
ylabel('Valore')
axis("padded");
grid on

pause

% Design del filtro a coseno rialzato

txfilter=comm.RaisedCosineTransmitFilter(...
  Shape='Square root', ...
  RolloffFactor=beta, ...
  FilterSpanInSymbols=span, ...
  OutputSamplesPerSymbol=sps)

% normalizzazione per avere a 1 il massimo del filtro 
b = coeffs(txfilter);
txfilter.Gain = 1/max(b.Numerator);

figure; % disegno filtro
impz(txfilter.coeffs.Numerator);
grid on 

%applico filtro
tx_signal=txfilter([zeros(Nsimboli/2,1);sig_c;zeros(Nsimboli/2,1)]);

%Risposta in Frequenza del filtro

%il numero di campioni deve essere più lunga del segnale 
% vedo la potenze di due più vicina-> potenza 2 nextpow2
esp = nextpow2(length(tx_signal));
Nfft = 2^esp;
f_ax=(-Nfft/2:Nfft/2-1)/Nfft*SamplingRate;

X=fft(txfilter.coeffs.Numerator,Nfft);
X=fftshift(X);

figure
plot(f_ax,db(abs(X).^2))
xlabel("Frequenze")
ylabel("Quadrato del Modulo in dB")
title('Risposta in Frequenza del Filtro')
grid on 

pause

%correzione delay tx
tx_signal= tx_signal((span*sps/2)+1:end);

figure
t3=[0:1:length(tx_signal)-1];
plot(t3,tx_signal);
axis("padded");
title('Segnale Tx Filtrato');
xlabel('Campioni');
ylabel('Valori');

pause

% Grafico Segnale e Segnale filtrato
%variabile di supporto per grafico è segnale filtrato senza padding di
%zeri
tx_sig=txfilter(sig_c);
tx_sig=tx_sig((span*sps/2)+1:end);

figure
t= 1000*(0:length(sig_c)-1)*(sps/SamplingRate); 
%vettore dei tempi campionato a passo di simbolo in millisecondi
stem(t,sig_c,'rx');
hold on

to = 1000*(0:(length(tx_sig)-1))/SamplingRate;
%vettore dei tempi campionato a frequenza di campionamento in millisecondi
plot(to,tx_sig, 'b-'); 

axis("padded");
title('Segnale Generato e Filtrato');
xlabel('Tempo in ms');
ylabel('Valori');

hold off;

% Trasmissione tramite Adalm Pluto 
txNorm=tx_signal/max(abs(tx_signal));
txNorm_c=complex(txNorm);

txPluto = sdrtx('Pluto',...
       'RadioID',idTX,...
       'CenterFrequency',fc,...
       'Gain',-3, ... %must be between -89 and 0
       'BasebandSampleRate',SamplingRate);

transmitRepeat(txPluto,txNorm_c);
%100k simb per secondo