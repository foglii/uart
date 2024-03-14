%% Trasmettitore 4 PAM

close all;
clear;

% Specifiche Adalm Pluto
Mypluto=findPlutoRadio
idTX=append('sn:', Mypluto.SerialNum);

%% Definizione Parametri
SamplingRate=1e6; % Frequenza di campionamento (Hz)
fc=2.475e9;
Nsimboli=1000;
lung_sig = 2000;
T_symbol = 1/SamplingRate; % Tempo di simbolo 

% Filtro
beta= 0.2; % Fattore di roll-off del filtro
span =1; % Lunghezza in simboli del filtro
sps = 16;  % Campionamenti per simbolo (oversampling factor)

% Messaggio 
symbols=zeros(1,Nsimboli);
barker = comm.BarkerCode("Length",7,"SamplesPerFrame",7);
barker_code = barker().';
%seq_start=[1,1,0,1,0,1,0,1];
%seq_end=[1,1,1,0,0,0,1,1];

data_tx='hi'; %stringa che vogliamo trasmettere
binArray=dec2bin(data_tx,8)-'0';  %trasforma decimale in binario 
%in questo modo rimane una matrice di char quindi tolgo il valore di zero a
%ogni casella per tornare ai double 1 e 0

binArray=binArray.'; %trasposta

binArray=reshape(binArray,1,8*length(data_tx)); 
%da matrice leght data x 8 diventa matrice 1 x (length data x 8)

%calcolo del parity bit
sum=0;
for i=1:length(binArray)
        if binArray(i)==1 %conta gli uno
        sum=sum+1;
        end
end
if mod(sum,2)==0 %mod resto della divisione sum/2 per def di parity
   parity=0;
else parity=1;
end 
message=horzcat((barker_code+1)/2,binArray,parity);
count=1;
binArray4Pam=zeros(1,ceil(length(message)/2));
for k=1:2:length(message)-1
    binArray4Pam(count)=message(k)*2+message(k+1);
    count=count+1;
end
%symbols=horzcat(message,zeros(1,1000-(length(message))))
symbols=binArray4Pam;

%symbols=horzcat(message,zeros(1,1000-(length(message)+barker.Length))); %zero padding
symbols=symbols.'; %cosi rimane vettore colonna

% seq_start = sprintf('%d',seq_start);
% seq_end = sprintf('%d',seq_end);
% mes = sprintf('%d',mes);
%% Creazione segnale PAM
sig=qammod(symbols,4);
%sig=vertcat(barker_code.',sig);
%sig=(sig+1)/2; %rendiamo la modulazione unipodale
sig_c=complex(sig);

figure
stem(sig_c,'filled')
title('Segnale')
xlabel('Simboli')
ylabel('Valore')
axis("padded");
grid on

pause

%% Design del filtro a coseno rialzato

txfilter=comm.RaisedCosineTransmitFilter(...
  Shape='Square root', ...
  RolloffFactor=beta, ...
  FilterSpanInSymbols=span, ...
  OutputSamplesPerSymbol=sps);

% normalizzazione per avere a 1 il massimo del filtro 
b = coeffs(txfilter);
txfilter.Gain = 1/max(b.Numerator);

figure; % disegno filtro
impz(txfilter.coeffs.Numerator);
grid on 

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

%% Grafico Segnale e Segnale filtrato
%variabile di supporto per grafico è segnale filtrato senza padding di
%zeri
%tx_sig=txfilter(sig_c);
tx_sig=tx_signal((span*sps/2)+1:end);
 
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

%% Trasmissione tramite Adalm Pluto 
txNorm=tx_signal/mean(abs(tx_signal));
txNorm_c=complex(txNorm);

txPluto = sdrtx('Pluto',...
       'RadioID',idTX,...
       'CenterFrequency',fc,...
       'Gain',-3, ... %must be between -89 and 0
       'BasebandSampleRate',SamplingRate);

transmitRepeat(txPluto,txNorm_c);

