
data='hello';
binArray=dec2bin(data,7)-'0'
binArray=binArray.';
binArray=reshape(binArray,1,7*length(data));
seq_start=[1,0,1,0,1,0,1,0,1,0];
seq_end=[1,1,1,0,0,0,1,1,1,0];
%se numero dispari di 1, parity bit=1
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
   
frame.start=seq_start;
frame.data=binArray;
frame.parity=parity;
frame.stop=seq_end;

frame_array=horzcat(seq_start,binArray,parity,seq_end);

%elaborazione
sigdemod=frame_array;
[c,lags] = xcorr(sigdemod,seq_start);
c=c/max(c);
figure;
stem(lags,c)
i=0;
while c(i-lags(1))~=1
    i=i+1;
end 
%i indice di inizio seq_start
[d,lags] = xcorr(sigdemod,seq_end);
d=d/max(d);
figure;
stem(lags,d)
j=i;
while d(j-lags(1))~=1
    j=j+1;
end 
%j indice di inizio seq_end
framerx.start=sigdemod(i:i+9);
framerx.parity=sigdemod(j-1);
framerx.data=sigdemod(i+10:j-2);
framerx.end=sigdemod(j:j+9);
%parity check al receiver
for i=1:length(framerx.data)
        if framerx.data(i)==1
        sum=sum+1;
        end
end
if framerx.parity==mod(sum,2)
  fprintf('passed parity check\n');
else fprintf('first parity check not passed\n')
    %codice che va a cercare nella ripetizione successiva su rxwave 
    % e ripete il meccanismo
end 

%ora serve dividere framerx.data in segmenti da 7,convertirli in char
% e riportarli in decimale


%framerx.data=framerx.data.';
%rows=length(framerx.data)/7;
%datarx=framerx.data;
%datarx=datarx+'0';
%datarx=char(datarx);
%strcat(datarx)
% datarx=zeros(1,rows);
% data1='0000000';
% for f=1:rows
%     for k=(1+7*(f-1)):(7+7*(f-1))
%         exp=7-mod(k,7);
%         datarx(f)=datarx(f)+framerx.data(k)*10^exp;
%     end
% end
% %for k=1:rows
%     b = num2str(datarx(1));
%     %data1=[data1;b];
% %end
%   
%     
