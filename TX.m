%% Trasmettitore

close all;
clear;

% Specifiche Adalm Pluto
findPlutoRadio
idTX='usb:0';

%% Definizione Parametri
SamplingRate=1e6; % Frequenza di campionamento (Hz)
fc=2.475e9;
Nsimboli=1000;
lung_sig = 2000
T_symbol = 1/SamplingRate; % Tempo di simbolo

symbols=zeros(1,Nsimboli);
seq_start=[1,1,0,1,0,1,0,1];
seq_end=[1,1,1,0,0,0,1,1];
data='ok'; %stringa che vogliamo trasmettere
binArray=dec2bin(data,8)-'0'  %trasforma in matrice di int
binArray=binArray.';
binArray=reshape(binArray,1,8*length(data)); %da matrice a array
%calcolo del parity bit
sum=0;
for i=1:length(binArray)
        if binArray(i)==1
        sum=sum+1;
        end
end
if mod(sum,2)==0
   parity=0;
else parity=1;
end 
message=horzcat(seq_start,binArray,parity,seq_end); %concatena 

% seq_start = sprintf('%d',seq_start);
% seq_end = sprintf('%d',seq_end);
% mes = sprintf('%d',mes);

%message = horzcat(seq_start,mes,seq_end);
% binArray=dec2bin(message,8)-'0';
% binArray=binArray.';
% binArray=reshape(binArray,1,33*8);
% symbols=binArray;
symbols=horzcat(message,zeros(1,967)); %zero padding
symbols=symbols.';

% symbols(500)=1;
% symbols(497)=1;
% symbols(750)=1;

beta= 0.5; % Fattore di roll-off del filtro
span = 6; % Lunghezza in simboli del filtro
sps = 8;  % Campionamenti per simbolo (oversampling factor)


%% Creazione segnale PAM
sig=pammod(symbols,2);
sig=(sig+1)/2; %rendiamo la modulazione unipodale
sig_c=complex(sig);

figure(1)

stem(sig_c,'filled')
title('Segnale')
xlabel('Simboli')
ylabel('Valore')
axis("padded");

%% Design del filtro a coseno rialzato

txfilter=comm.RaisedCosineTransmitFilter(...
  Shape='Square root', ...
  RolloffFactor=beta, ...
  FilterSpanInSymbols=span, ...
  OutputSamplesPerSymbol=sps)

% normalizzazione per avere a 1 il massimo del filtro 
b = coeffs(txfilter);
txfilter.Gain = 1/max(b.Numerator);

figure(2); % disegno filtro
impz(txfilter.coeffs.Numerator);

%applico filtro
tx_signal=txfilter([zeros(Nsimboli/2,1);sig_c;zeros(Nsimboli/2,1)]);

%correzione delay tx
tx_signal= tx_signal((span*sps/2)+1:end);

figure(3)
t3=[0:1:length(tx_signal)-1];
plot(t3,tx_signal);
axis("padded");
title('Segnale Tx Filtrato');
xlabel('Campioni');
ylabel('Valori');

%% Grafico Segnale e Segnale filtrato
%variabile di supporto per grafico è segnale filtrato senza padding di
%zeri
tx_sig=txfilter(sig_c);
tx_sig=tx_sig((span*sps/2)+1:end);

figure(4)
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

%% Trasmissione tramite Adalm Pluto 
txNorm=tx_signal/max(abs(tx_signal));
txNorm_c=complex(txNorm);

txPluto = sdrtx('Pluto',...
       'RadioID',idTX,...
       'CenterFrequency',fc,...
       'Gain',-3, ... %must be between -89 and 0
       'BasebandSampleRate',SamplingRate);

transmitRepeat(txPluto,txNorm_c);
%100k simb per secondo
