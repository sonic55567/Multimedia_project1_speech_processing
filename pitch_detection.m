% read the audio
[y, fs]=audioread('voice.wav');
y = y / max(abs(y));

% waveform
time=(1:length(y))/fs;
subplot(3,1,1);
plot(y);
hold on;
line(90240 * [1,1],[-1, 1],'color', 'r');
line(91200 * [1,1],[-1, 1],'color', 'r');
hold off;
title('Waveform');

subplot(3,1,2);
plot(y(90240:91200));
title('In the interval of 2 red lines');

% 先將原本波形做center clipping
cl = 0.3 * max(abs(y));
for i=1:length(y)
   if abs(y(i)) < cl
       y(i) = 0;
   end
   if y(i) >= cl(1)
       y(i) = y(i) - cl;
   end
   if y(i) <= -cl(1)
       y(i) = y(i) + cl;
   end
end

% 將y放大為要觀察的window
y = y(90240:91200);

% 帶入autocorrelation function
pitch = zeros(961, 1);
for i=0:(length(y)-1)
    sum1 = 0;
    for j=1:(length(y)-i)
        s = y(j) * y(j+i);
        sum1 = sum1+s;
    end
    pitch(i+1) = sum1;
end

% 將圖畫出
subplot(3,1,3);
plot(pitch);
title('Autocorrelation function');
index1 = 1;

% 尋找週期
IndMin=find(diff(sign(diff(pitch)))>0)+1;

for i= IndMin(1)+1:960
    if pitch(i) == max(pitch(IndMin(1)+1:960))
        index2 = i;
        break;
    end
end

for i= 550:650
    if pitch(i) == max(pitch(550:650))
        index3 = i;
        break;
    end
end

fprintf("index1 = %d\n", index1);
fprintf("index2 = %d\n", index2);
fprintf("index3 = %d\n", index3);
fprintf("the corresponding pitch is %d/(%d-%d) = %f Hz\n", fs, index2, index1, fs/(index2-index1));

hold on;
line(index1 * [1,1],[-20, 20],'color', 'g', 'LineWidth', 1);
line(index2 * [1,1],[-20, 20],'color', 'g', 'LineWidth', 1);
line(index3 * [1,1],[-20, 20],'color', 'g', 'LineWidth', 1);
hold off;