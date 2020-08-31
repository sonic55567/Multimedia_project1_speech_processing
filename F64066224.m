% read the audio
[y, fs]=audioread('voice.wav');
y = y / max(abs(y));

% (1) waveform
time=(1:length(y))/fs;
subplot(6,1,1);
plot(time, y);
title('Waveform');

% (2) energy contour
% ��@short-time processing�Awindow duration�]�w��20ms�Aoverlap�]�w��window duration���@�b
% �ϥ�rectangular window(��������)�A�õL�t�~�ϥ�hamming window�������
duration = 20/1000*fs;                  % �]�wframe size(windows duration)��20ms (960�ӳ��)
overlap = duration/2;                   % �]�woverlap��frame size���@�b
for i=1:length(y)/(duration-overlap) -1
   for j=1:duration
        a(j,i) = y(j+overlap*(i-1));
   end
end   
n = size(a, 2);                         % ��X�@���F�X��frame
energy = zeros(n, 1);           
energy2 = zeros(n, 1);
for i=1:n
	frame = a(:,i);
	energy(i)=sum(frame.^2);           % Short-time energy (�����)
end
for i=1:n
	frame = a(:,i);
	energy2(i)=sum(abs(frame));          % Average magnitude (�����)
end

time2 = ((0:n-1)*(duration-overlap)+overlap)/fs;     % �`���((frame-overlap)*frame�Ӽ� + �@��overlap) / �ļ��W�v

% �N�ϵe�X(��حp��覡)
subplot(6,1,2);                         
plot(time2, energy, '.-');
title('Energy contour');
subplot(6,1,3);
plot(time2, energy2, '.-');
title('Average magnitude');

% (3) zero-crossing rate contour
sgn_a = a;                              % �ŧi�t�@�x�}sgn_a�Ӧs��sgn�᪺��
n2 = size(a, 1);                        % n2���C��frame���X�ӳ��

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

% �a�J�����G|sgn[x(n)]-sgn[x(n-1)]|*w(n),  w(n) = 1/2N
sgn_a_minus = sgn_a;                    % �ŧisgn_a_minus�x�}�����U�����p��
for i=1:n
   for j=2:n2
      sgn_a_minus(j, i) = (abs(sgn_a(j, i)-sgn_a(j-1, i)));
   end
end
sgn_a_minus = sgn_a_minus/(2*duration);      % ���Ww(n)

% ��sigma
zc_rate = zeros(n, 1);
for i=1:n
    frame = sgn_a_minus(:, i);
    zc_rate(i) = sum(frame);
end

% �N�ϵe�X
subplot(6,1,4);
plot(time2, zc_rate, '.-');
title('Zero-crossing rate');

% (4) end point detection
% �M�J�����p��ITL, ITU, IZCT
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

% ���ھ�ITL, ITU�Penergy����A���_�l�I
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

% ���_�l�I��A��zero crossing rate�PIZCT����A�ץ��𭵳���
startFrame = max(N1-25,1);
endFrame = N1;
backCheck = 0;
for i = startFrame:endFrame
    if zc_rate(i) >= IZCT
        backCheck = backCheck + 1;
    end
end

% �p�W�LIZCT�T���A�h�NN1���e���ʦܶW�LIZCT���Ĥ@���I
if backCheck >= 3
    for i = startFrame:endFrame
        if zc_rate(i) >= IZCT
            N1 = i;
            break;
        end
    end
end

% �M�䵲���I�P�M��_�l�I��k�ۦP
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

% �p�W�LIZCT�T���A�h�NN2���Ჾ�ʦܶW�LIZCT���̫�@���I
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
 
% �N��i�ιϵe�X�A�ñN��쪺�_�l�I�P�����I�ά��u�ХܥX��
subplot(6,1,5);
plot(time, y);
hold on;
line(time(N1+1) * [1,1],[-1, 1],'color', 'r', 'LineWidth', 1);
line(time(N2) * [1,1],[-1, 1],'color', 'r', 'LineWidth', 1);
title('End Point Detection');
hold off;

% (5) pitch contour
% ���N�쥻�i�ΰ�center clipping
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

% �ŧiacf�ΨӦs�����W�۬�����ƫ᪺���G
pitch = zeros(493, 1);
acf = zeros(duration, 493);
a_pitch = zeros(duration, 493);

% ���s���Τ@���i�Ψæs�ba_pitch�����U�p��
for i=1:length(y)/(duration-overlap) -1
   for j=1:duration
        a_pitch(j,i) = y(j+overlap*(i-1));
   end
end    

% �a�Jautocorrelation function
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

% �ŧiIndMin�ӴM��C��window�����i���A�ѲĤ@�Ӫi����@�_�I�A�M��̤j�ȧY��pitch���g��(�Ĥ@�ӳ��ۭ��ȳ̤j)
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
    pitch(i) = fs/(index2-index1);                  % ���g����Y�i�p�⭵���W�v
end

% �����p��ɥX�{�����T
for i=1:length(pitch)
    if pitch(i)>500
        pitch(i) = 0;
    end
end

% �N�ϵe�X
subplot(6,1,6);
plot(time2, pitch, '.-');
title('Pitch contour');
xlabel('Time (sec)');