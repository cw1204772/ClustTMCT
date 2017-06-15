# DukeMTMC Tracking Challenge Evaluation Kit

**Implementation of _"Track-clustering Error Evaluation for Track-based Multi-Camera Tracking System Employing Human Re-identification". CW. Wu, MT. Zhong, SY. Chien, YK. Chen, SW. Yang, Y. Tsao. CVPR 2017 workshop on re-identification and multi-target multi-camera tracking.[1]_**

Note that this is developed based on DukeMTMC's evaluation kit v1.00, included in the MOT challenge. For more detail regarding DukeMTMC's multi-camera tracking dataset[2], please refer to their website:

- MOT challenge: http://motchallenge.net

- DukeMTMC: http://vision.cs.duke.edu/DukeMTMC

Graet thanks to Ergys Ristani for letting us to use his code!

If you have any problems or come across any bugs, please contact cwwu@media.ee.ntu.edu.tw.


## Requirement
- MATLAB (tested on Windows only with MATLAB R2016b & 2013a)
  

## Usage

Run `demoDukeMTMCEvaluate.m` and it will compute T-MCT and MCT score for DukeMTMC's baseline results on the "val" set.

This is what you should expect for after ~30 min.:

```
-------Results-------
Test set: val
Single-all
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
74.19	 84.06	 66.39	 13.47		 11.49	 16.28

Multi-cam
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
54.76	 62.04	 49.00	 35.78		 39.40	 32.77

Cam_1
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
60.47	 91.59	 45.13	 25.00		 100.00	 14.29
Cam_2
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
78.83	 81.44	 76.39	 6.57		 4.73	 10.77
Cam_3
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
78.79	 91.55	 69.16	 12.50		 25.00	 8.33
Cam_4
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
77.65	 82.19	 73.59	 10.53		 6.67	 25.00
Cam_5
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
80.81	 85.93	 76.27	 NaN		 0.00	 0.00
Cam_6
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
70.27	 77.57	 64.23	 17.73		 14.33	 23.26
Cam_7
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
85.20	 90.14	 80.77	 11.76		 11.11	 12.50
Cam_8
IDF1  	 IDP 	 IDR 	 ClustF1	 ClustP	 ClustR
73.66	 89.18	 62.75	 9.76		 15.38	 7.14
```

For computing CLEAR measures for SCT at the same time, please execute the script `demoDukeMTMCEvaluate_with_SCT.m`. Expect about 1~2 hr. for the results if tested on "val" set (~25 min. long).

More detail can be found in our paper.

## Some Notes
- 3D world plane evaluation is not supported.
- Calucating CLEAR measures take a lot of time, so we single out the script with it incorperated in.
- Results of our ReID-MCT system will be added later.

## Reference

1. Track-clustering Error Evaluation for Track-based Multi-Camera Tracking System Employing Human Re-identification. CW. Wu, MT. Zhong, SY. Chien, YK. Chen, SW. Yang, Y. Tsao. CVPR 2017 workshop on re-identification and multi-target multi-camera tracking.[[pdf]](https://www.dropbox.com/s/mjzrtrtnqi74vp4/Track-clustering%20Error%20Evaluation_ShaoYi%2C%20Yu.pdf?dl=0)
2. Performance Measures and a Data Set for Multi-Target, Multi-Camera Tracking. E. Ristani, F. Solera, R. S. Zou, R. Cucchiara and C. Tomasi. ECCV 2016 Workshop on Benchmarking Multi-Target Tracking.[[pdf]](https://users.cs.duke.edu/~tomasi/papers/ristani/ristaniBmtt16.pdf)

## License
View LICENSE.txt.

------

**Updated by Chih-Wei Wu on June. 2017.**
