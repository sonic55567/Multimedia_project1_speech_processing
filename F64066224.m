% read the audio
[y, fs]=audioread('voice.wav');
y = y / max(abs(y));

% (1) waveform
time=(1:length(y))/fs;
subplot(6,1,1);
plot(time, y);
title('Waveform');

% (2) energy contour
% 實作short-time processing，window duration設定為20ms，overlap設定為window duration的一半
% 使用rectangular window(直接取值)，並無另外使用hamming window等窗函數
duration = 20/1000*fs;                  % 設定frame size(windows duration)為20ms (960個單位)
overlap = duration/2;                   % 設定overlap為frame size的一半
for i=1:length(y)/(duration-overlap) -1
   for j=1:duration
        a(j,i) = y(j+overlap*(i-1));
   end
end   
n = size(a, 2);                         % 算出共切了幾個frame
energy = zeros(n, 1);           
energy2 = zeros(n, 1);
for i=1:n
	frame = a(:,i);
	energy(i)=sum(frame.^2);           % Short-time energy (平方值)
end
for i=1:n
	frame = a(:,i);
	energy2(i)=sum(abs(frame));          % Average magnitude (絕對值)
end

time2 = ((0:n-1)*(duration-overlap)+overlap)/fs;     % 總單位((frame-overlap)*frame個數 + 一個overlap) / 採樣頻率

% 將圖畫出(兩種計算方式)
subplot(6,1,2);                         
plot(time2, energy, '.-');
title('Energy contour');
subplot(6,1,3);
plot(time2, energy2, '.-');
title('Average magnitude');

% (3) zero-crossing rate contour
sgn_a = a;                              % 宣告另一矩陣sgn_a來存放做sgn後的值
n2 = size(a, 1);                        % n2為每個frame有幾個單位

% sgn[x(n)]
for i=1:n
   for j=1:n2
      if a(j, i) >= 0
          sgn_a(j, i) = 1;
      else
          sgn_a(j, i) = -1;
      end
   end
end

% 帶入公式：|sgn[x(n)]-sgn[x(n-1)]|*w(n),  w(n) = 1/2N
sgn_a_minus = sgn_a;                    % 宣告sgn_a_minus矩陣來幫助公式計算
for i=1:n
   for j=2:n2
      sgn_a_minus(j, i) = (abs(sgn_a(j, i)-sgn_a(j-1, i)));
   end
end
sgn_a_minus = sgn_a_minus/(2*duration);      % 乘上w(n)

% 做sigma
zc_rate = zeros(n, 1);
for i=1:n
    frame = sgn_a_minus(:, i);
    zc_rate(i) = sum(frame);
end

% 將圖畫出
subplot(6,1,4);
plot(time2, zc_rate, '.-');
title('Zero-crossing rate');

% (4) end point detection
% 套入公式計算ITL, ITU, IZCT
IMX = max(energy);
IMN = mean(energy(80:90));
I1 = 0.03 * (IMX-IMN) + IMN;
I2 = 4 * IMN;
ITL = 3.1*mean(energy(80:90));
ITU = 2.5 * ITL;
IZC = mean(zc_rate(1:37));
zc_rate_std = std(zc_rate(1:37));
IZCT = min(25 * 0.01, IZC + 2 * zc_rate_std);
N1 = 0;
N2 = 0;
is_found = 0;

% 先根據ITL, ITU與energy比較，找到起始點
for i = 10:length(energy)
    if energy(i) >= ITL
        for j = i:length(energy)
            if energy(j) < ITL
                break
            else
                if energy(j) >= ITU
                    if is_found == 0
                        N1 = j;
                        is_found = 1;
                    end
                    break
                end
            end
        end
    end
    if is_found == 1
        break
    end
end

% 找到起始點後，用zero crossing rate與IZCT比較，修正氣音部分
startFrame = max(N1-25,1);
endFrame = N1;
backCheck = 0;
for i = startFrame:endFrame
    if zc_rate(i) >= IZCT
        backCheck = backCheck + 1;
    end
end

% 如超過IZCT三次，則將N1往前移動至超過IZCT的第一個點
if backCheck >= 3
    for i = startFrame:endFrame
        if zc_rate(i) >= IZCT
            N1 = i;
            break;
        end
    end
end

% 尋找結束點與尋找起始點方法相同
is_found = 0;
for i = length(energy):-1:1
    if energy(i) >= ITL
        for j = i:-1:1
            if energy(j) < ITL
                break;
            else
                if energy(j) >= ITU
                    if is_found == 0
                        N2 = j;
                        is_found = 1;
                    end
                    break
                end
            end
        end
    end
    if is_found == 1
        break
    end
end
startFrame = min(length(zc_rate),N2);
endFrame = min(N2 + 25,length(zc_rate));
backCheck = 0;
for i = startFrame:endFrame
    if zc_rate(i) >= IZCT
        backCheck = backCheck + 1;
    end
end

% 如超過IZCT三次，則將N2往後移動至超過IZCT的最後一個點
if backCheck >= 3
    for i = max(1,startFrame):endFrame
        if zc_rate(i) >= IZCT
            N2 = i;
            break;
        end
    end
end

N1 = N1 * round(length(y) / length(energy));
N2 = N2 * round(length(y) / length(energy));
 
% 將原波形圖畫出，並將找到的起始點與結束點用紅線標示出來
subplot(6,1,5);
plot(time, y);
hold on;
line(time(N1+1) * [1,1],[-1, 1],'color', 'r', 'LineWidth', 1);
line(time(N2) * [1,1],[-1, 1],'color', 'r', 'LineWidth', 1);
title('End Point Detection');
hold off;

% (5) pitch contour
% 先將原本波形做center clipping
cl = 0.2 * max(abs(y));
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

% 宣告acf用來存取乘上自相關函數後的結果
pitch = zeros(493, 1);
acf = zeros(duration, 493);
a_pitch = zeros(duration, 493);

% 重新分割一次波形並存在a_pitch中幫助計算
for i=1:length(y)/(duration-overlap) -1
   for j=1:duration
        a_pitch(j,i) = y(j+overlap*(i-1));
   end
end    

% 帶入autocorrelation function
for k=1:size(a_pitch, 2)
    for i=0:(duration-1)
        sum1 = 0;
        for j=1:(duration-i)
            s = a_pitch(j, k) * a_pitch(j+i, k);
            sum1 = sum1+s;
        end
        acf(i+1, k) = sum1;
    end
end

% 宣告IndMin來尋找每個window中的波谷，由第一個波谷當作起點，尋找最大值即為pitch的週期(第一個單位相乘值最大)
IndMin = 0;

for i=1:size(acf, 2)
    index1 = 1;
    IndMin=find(diff(sign(diff(acf(:, i))))>0)+1;
    if isempty(IndMin)
        IndMin = duration;
        index2 = 48000;
    end
    for j=IndMin(1)+1:duration
        if acf(j, i) == max(acf(IndMin(1)+1:duration, i))
            index2 = j;
            break;
        end
    end
    pitch(i) = fs/(index2-index1);                  % 找到週期後即可計算音高頻率
end

% 消除計算時出現的雜訊
for i=1:length(pitch)
    if pitch(i)>500
        pitch(i) = 0;
    end
end

% 將圖畫出
subplot(6,1,6);
plot(time2, pitch, '.-');
title('Pitch contour');
xlabel('Time (sec)');