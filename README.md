# Multimedia_project1_speech_processing

Sample speech signal via sound card (Pronounce 多媒體系統與應用 in Chinese using continuous speech)

## Result：

F64066224.m

![image](https://github.com/sonic55567/Multimedia_project1_speech_processing/blob/master/output.jpg)

▲	Output.jpg

在energy的部分除了平方值方法外，我也試著計算Average magnitude(絕對值)，並將兩種方法做出來的結果都畫出圖，而兩種方法做出來的圖形輪廓也大致相同。
而(5) pitch的部分，雖然不是每個字都很明顯，但「多」、「媒」、「系」、「用」四個字的音高算蠻容易辨識出來的，其中「媒」與「用」兩字也可看出二聲的上揚與四聲的下降，另外我也將此段語音「多媒體系統與應用」裡的「多」字部分的波形抓出來放大觀察。

 
Pitch_detection.m

![image](https://github.com/sonic55567/Multimedia_project1_speech_processing/blob/master/output_pitch.jpg)

▲	Output_pitch.jpg

第二張圖是將第一張圖兩條紅線之間，也就是「多」字的其中一部份波形放大，第三張圖則是放大後只乘上ACF所得的結果，第三張圖中綠色的線為高點，利用兩高點之間的差值可得出週期，再與取樣頻率相除即可計算出音高為164.38Hz左右。
