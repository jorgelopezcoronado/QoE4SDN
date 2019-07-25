setenv("GNUTERM","qt"); %to correctly display graphs

function [maxAccuracy, gamma, C, RBFK] = getBestSVMParams(trainlabels, trainfeatures)
	maxAccuracy = 0;
	gama = 0;
	C= 0;
	RBFK = true;
	for i=-5:15
		for j=-15:3
			display(sprintf("Kernel: %s C: 2^%d G: 2^%d", "RBKF", i, j));
			model = svmtrain(trainlabels, trainfeatures, sprintf("-s 0 -t 2 -c %f -g %f -v 5 -q", 2^i, 2^j));
			if model >= maxAccuracy
				gamma = j;
				C = i;
				maxAccuracy = model;
			end;
		end;
	end;

	for i=-5:15 
		display(sprintf("Kernel: %s C: 2^%d G: 2^%d", "Linear", i, j));
		model = svmtrain(trainlabels, trainfeatures, sprintf("-s 0 -t 0 -c %f -g %f -v 5 -q", 2^i, 2^j));
		if model >= maxAccuracy
			gamma = j;
			C = i;
			RBFK = false;
			maxAccuracy = model;
		end;
	end;

	tempC = C;
	tempGamma = gamma;
	kernel = "RFBK";
	if (RBFK != true)
		kernel = "Linear";	
	end;

	
	for i=tempC-1:0.25:tempC+1
		for j=tempGamma -1:0.25:tempGamma+1
						display(sprintf("Kernel: %s C: 2^%d G: 2^%d", kernel, i, j));
			model = svmtrain(trainlabels, trainfeatures, sprintf("-s 0 -t %i -c %f -g %f -v 5 -q", 2*RBFK, 2^i, 2^j));
			if model > maxAccuracy
        	     		gamma = j;
               			C = i;
                		maxAccuracy = model;
	        	end;
		end;
	end;

endfunction

function scaledVector = scale(vector) %scaling to val - m / 2s, soft normalization
	%The realmin("double") is added to make not 0 the standard deviation, just in case, not to divide by 0.
	scaledVector = (double(vector) .- mean(vector)) ./ (2 * std(vector) + realmin("double"));
endfunction;

function [labels, trainset] = readData (filename)
	trainset = importdata (filename);
	[num_rows num_cols] = size(trainset);
	labels = trainset(:,num_cols);
	trainset (:,num_cols) = [];
	%consider doing some scaling?
endfunction; 

filename = 'data.csv';

[labels, features] = readData(filename);


[ac, g, c, k] = getBestSVMParams(labels, features);

display(sprintf("C=%f, gamma=%f, maxAccuracy=%f, RBFK=%i\n", c, g, ac, k));

%params = sprintf("-s 0 -t %i -c %f -g %f -q", 2*k, 2^c, 2^g);

%display(params);

%model = svmtrain(trainlabels, trainfeatures, params);

