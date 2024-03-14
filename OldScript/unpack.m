% ------- packet frame format --------
%
%  8 bit seq_start
%  8/16 bit data
%  8 bit seq_end
%
% ------------------------------------
clear;
close all;

seq_start=[1,0,1,0,1,0,1,0];
seq_end=[1,1,1,0,0,0,1,1];

mes = [0,0,0,1,0,0,0,0,1,0,1,0,0,0,0,1,1,1];

seq_start = sprintf('%d',seq_start);
seq_end = sprintf('%d',seq_end);
mes = sprintf('%d',mes);

message = horzcat(seq_start,mes,seq_end);

[data, dataOK] = unpackMessage(message)

%-------Unpack raw message function---------
% Data una stringa contenente solamente il
% pacchetto su cui bisogna fare l'unpack, 
% ossia seq_start + message + parity +seq_end 

function [data, parityCheck] = unpackMessage(rawData)
    DecRawData = bin2dec(rawData);
    
    str = zeros(2,1);
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

    str(1) = bitand(DecRawData,mask1);   
    str(2) = bitshift(bitand(DecRawData,mask2),-8);
    
    data = horzcat(char(str(1)),char(str(2)));


    sum = 0;
    for i = 1 : (length(rawData)- 17)
        sum = sum + mod(DecRawData,2);
        DecRawData = bitshift(DecRawData,-1);
    end

    parityCheck = (mod(sum,2) == parityBit);
    
end