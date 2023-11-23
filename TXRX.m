close all;
clear;

%       RECOGNIZE ADALM PLUTO
MyPLutoNumber = findPlutoRadio;
sizeMyPLutoNumber = size(MyPLutoNumber);
if ~(sizeMyPLutoNumber(1) == 0) 


    %   ADALM SETTINGS
    SamplingRate = 1e6;
    fc = 2.44e9;
    idTX = append('sn:', MyPLutoNumber.SerialNum);
    %   TX
    txPluto = sdrtx('Pluto',...
       'RadioID',idTX,...
       'CenterFrequency',fc,...
       'Gain',-3, ... %must be between -89 and 0
       'BasebandSampleRate',SamplingRate);
    %   RX
    rxPluto = sdrrx('Pluto','RadioID',...
    "usb:0",'CenterFrequency',fc,...
    'GainSource','Manual',...
       'Gain',30,...
       'OutputDataType','single',...
       'BasebandSampleRate',SamplingRate);



    %   PACKET SETUP
    symbols = zeros(1000,1);
    symbols(500) = 1;
    symbols(497) = 1;
    symbols(750) = 1;
    %symbols = randi([0, 1], 1000, 1);

    %   PAM SETUP
    sig = pammod(symbols, 2);
    figure;
    sig = complex(sig);
    t = 0:1:length(sig)-1;
    plot(t,sig,'o');
    title('segnale');
    xlabel('t');


    % sig= pammod(symbols, 2)*(1+i);
    % Fs = 100000;           % Frequenza di campionamento (Hz)
    % T_symbol = 1/Fs;      % Tempo di simbolo

    %   RAISED COSINE FILTER 
    rolloff_factor = 0.25; % Fattore di roll-off del filtro
    span = 9; % Lunghezza in simboli del filtro
    sps = 8;  % Campionamenti per simbolo (oversampling factor)
    rcosine_filter = rcosdesign(rolloff_factor, span, sps,'sqrt');
    
    % plot(rcosine_filter,'.');
    % title('filtro tx');

    % Generazione di un segnale di esempio
    tx_signal = upfirdn(sig, rcosine_filter, sps);
    t3=0:1:length(tx_signal)-1;
    figure;
    plot(t3,tx_signal);
    title('segnale tx filtrato');
    xlabel('t');


    % rcosine_filter = rcosdesign(rolloff_factor, span, sps,'sqrt');
% rx_signal = upfirdn(tx_signal, rcosine_filter,1,8);
% t4=[0:1:length(rx_signal)-1];
% figure(4)
% plot(t4,rx_signal)
% title('segnale rx filtrato');
% xlabel('t')
% for i=1:length(rx_signal)-(2*span)
%     rx_signal_no_offset(i)=rx_signal(i+span);
% end
% sig_demod=pamdemod(rx_signal_no_offset,2);

    %ritardo di 9 campioni(dimensione filtro)
txNorm=complex(tx_signal/max(abs(tx_signal))); 
transmitRepeat(txPluto,txNorm);
% %100k simb per secondo


%   RX


tic;   
[rxWave,rx_meta]=capture(rxPluto,1e6);
toc;

rx_signal = upfirdn(rxWave, rcosine_filter,1,sps);
t4=[0:1:length(rxWave)-1];
figure;
plot(rx_signal,'o');


end



