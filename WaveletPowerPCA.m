%this function takes as input directories of different experiments, reads
%in the previously processed .mat files and then preforms pca on them. 
%
%Inputs:
%typeNames -a cell array with names (in strings) of the type of each
%experiment
%numWells - a vector containing the number of wells in each experiment -
%must be the length of varargin or the program will throw an error
%The function can take any number of directories as an input.
function [pcaCoefs, score, latent, TSquare, varExplained, mu]...
    =  WaveletPowerPCA (typeNames, numWells, varargin)

%determine how many types you have and which entry is which type
[typeVector, uniqueIndex, repeatIndex] = unique(typeNames);
numTypes = length(typeVector);
%determine how many experiments you are looking at 
numExperiments =  length(varargin);

if length(varargin)~= length(numWells)
    error('Number of Wells Must Match the Number Of Input Experiments');
end

if length (numWells)~=length(typeNames)
    error ('Must Provide Number of Wells For Each Type')
end 

%variables
%define the bounds that you want to be comparing for pca
timeStart = 150;%in minutes
timeEnd = 250;%in minutes
%how many time points to sample from - sample every 1/timeSkip. This is in
%units of frames
timeSkip = 5;
%where to look for stuff to compare
perStart = 4;%in minutes
perEnd = 15;%in minutes
perSkip = 5;%how many points to sample from-not meaningful units, just
%every 5th period measurement

plateName = 'Plate*';
dataName = 'wellDataAngular*';
%requisite significance for principal components
sigLevel = .95;
%number of permutations for significance testing
numPermutations = 99;
%number of components to apply significance tests to
sigComponents = 100;

w = waitbar (0);

%go through the given folder and make a directory of all of the saved .MAT
%files
fileDir = cell(1, numExperiments);

%create storage for where all of your files are
for i = 1:numExperiments
    fileDir{i} = dir ([varargin{i} filesep plateName]);
    dataDir{i} = struct([]);
    for j = 1:length(fileDir{i})
        dataDir{i} = vertcat (dataDir{i}, dir([varargin{i} filesep ...
            fileDir{i}(j).name filesep dataName]));
    end
end


%declare empty array for measurements
measurementStorage = [];
counter = 0;
numMeasurements = zeros (1, numExperiments);
%loop through each data file for the first type and read it in

%loop through your experiments 
for experiment = 1 : numExperiments
    %loop though all of the data sets within that experiment
    for i = 1: length(dataDir{experiment})
        %load in the given MAT file
        %update waitbar
        waitbar (i/sum(numWells), w);
        
        %note 7-26-15 - this is a bit inelegant but should work for now
        %try all the folders that it could be in
        for j = 1: length (fileDir{experiment})
            try
                %basically, if it works, then you found it! if not, keep
                %going until you do find it
                temp = load ([varargin{experiment} filesep ...
                    fileDir{experiment}(j).name filesep ...
                    dataDir{experiment}(i).name]);
                wellData = temp.wellData;
                break
            catch 
                if j == length(fileDir{experiment})
                   error ('File Not Found!') 
                else 
                    continue
                end
            end 
            
        end
        
        
        %for the first file only get your time and period index information
        if i ==1 && experiment==1
            
            %convert measurements in minutes to indexes in the matrix of 
            %power coordinates
            perIndex = find (wellData.period > perStart &...
                wellData.period <perEnd);
            perIndex = perIndex (1: perSkip:length(perIndex));
            timeIndex = find (wellData.times >timeStart &...
                wellData.times <timeEnd);
            timeIndex = timeIndex (1: timeSkip:length(timeIndex));
            
        end
        
        %within each data file loop through and fill your matrix for PCA
        for k = 1: length (wellData.waveData)
            %loop through each power spectra and concatenate into 1 row 
            %vector
            temp = wellData.waveData(k);
            temp = temp.power;
            temp = temp(perIndex, timeIndex)';
            %fill matrix for pca
            measurementStorage(counter+1, :) = temp(:)';
            counter = counter +1 ;
        end
        clear wellData;
    end
   
    numMeasurements(experiment) = counter - ...
        sum (numMeasurements(1:experiment-1));
end

%do the pca

[pcaCoefs, score, latent, TSquare, varExplained, mu] = ...
    pca(measurementStorage);
%plot  variance explained
figure;
subplot (1,2,1)
plot (1: length(varExplained), varExplained);
xlabel ('Principal Component Number');
ylabel('Percent of Variance Explained');
set (gca, 'FontSize', 16)

%plot cumulative variance explained
subplot (1,2,2)
for i = 1: length(varExplained)
   plot (i, sum (varExplained (1:i)));
   hold on
end
xlabel ('Principal Component Number');
ylabel ('Cumulative Variance Explained');
set (gca, 'FontSize', 16);


%preform permutation tests for significance of pca

%declare storage matrix for varExplained values - each of the rows
%represents a permutation while each column represents the amount of
%variance explained by the ith principal component in that permutation
permutationVarExplained = zeros ( numPermutations, sigComponents);

%loop through the alotted number of times and pull out the significance of
%the first principle components

for i  = 1: numPermutations
    permutationVarExplained (i,:) = PcaPermutationTest ...
        (measurementStorage, sigComponents);
end 

%sort the variance explained matrix and then cut off at the significance
%value for each one

permutationVarExplained = sort (permutationVarExplained,1);
%find the index corresponding to the value that is closest to your
%significance threshold
[~, sigIndex] = min (abs ( permutationVarExplained - ...
    ones (size (permutationVarExplained, 1), 1) * ...
    varExplained(1:size (permutationVarExplained,2))'));
%convert index to significance level
varSigLevel = sigIndex./ numPermutations;
%visualize the significance level of the principle components
figure; bar (varSigLevel);
xlabel ('Principal Component Number')
ylabel ('Significance Level')
title ('Significance of Principal Components Via Permutations')

%display the significant principle components
sigComponents = find (varSigLevel> sigLevel);
disp (sigComponents);

[clusterID, centroids] = kmeans (score (:,1:max(sigComponents)), numTypes);

%associate with each experiment the cluster identifications
%associated with every point in that experiment
strainClusterId = cell (1, length(numMeasurements))
for i =1: length(numMeasurements)
    if i ==1
        strainClusterId{i} = clusterID (1:numMeasurements(i))
    else
        cumMeasurements = sum (numMeasurements(1:i-1));
        strainClusterId{i} = clusterID(cumMeasurements+1:...
            cumMeasurements+numMeasurements(i));
    end
end 

%plot clusters along 1st 2 principle components
figure;
cumMeasurements = 1;
colors = { 'r', 'g','k', 'b', 'y'};
for i = 1: length(numMeasurements)
    plot(score(cumMeasurements:cumMeasurements+numMeasurements(i)-1, 1),...
        score (cumMeasurements:cumMeasurements + ...
        numMeasurements(i)-1,2), [colors{repeatIndex(i)} '.'])
    hold on
    cumMeasurements = cumMeasurements + numMeasurements(i);
end

xlabel ('First Principal Component');
ylabel ('Second Principal Component');
set (gca, 'FontSize', 16);

legendString = cell([1, numTypes]);
for i = 1: numTypes
    legendString{i} = ['Isolate ', typeNames{uniqueIndex(i)}];
end
plot (centroids(:,1), centroids (:,2), 'kx', ...
    'MarkerSize', 15, 'LineWidth', 3)
legend(legendString);


%reconstruct centroids

centroidPowers = cell(1, numTypes);
for i = 1: numTypes
    temp = pcaCoefs( :, 1:size(centroids,2))* centroids(i,:)';
    centroidPowers{i} = reshape(temp,[length(timeIndex),length(perIndex)]);
end

%show all centroids 
for i = 1: numTypes
   figure;
   imagesc (centroidPowers{i});
   title(['Centroid of Isolate ', typeNames{i}])
end


%show the first 4 principle components
figure;
subplot(2,2,1);
imagesc(reshape(pcaCoefs(:,1), [length(timeIndex), length(perIndex)]));
title ('1st Principle Component')

subplot(2,2,2);
imagesc(reshape(pcaCoefs(:,2), [length(timeIndex), length(perIndex)]));
title ('2nd Principle Component')

subplot(2,2,3);
imagesc(reshape(pcaCoefs(:,3), [length(timeIndex), length(perIndex)]));
title ('3rd Principle Component')

subplot(2,2,4);
imagesc(reshape(pcaCoefs(:,4), [length(timeIndex), length(perIndex)]));
title ('4th Principle Component')

%get information on the distribution of types within each genotype

%declare 
strainClusterHist = cell(1,numTypes);
%loop through the cluster identifications for each type
for i = 1: numTypes
   %get the distribution of clusters for that genotype
   strainClusterHist{i} = hist(vertcat(strainClusterId{repeatIndex==i}),...
       numTypes);
   %show all histograms for all genotypes
   figure;
   hist(vertcat(strainClusterId{repeatIndex==i}), numTypes);
   xlabel('Cluster ID (Arbitrary)')
   ylabel('Number of Signals Sorted into Cluster')
   title(['Distribution of Cluster Assignments for ', typeVector{i}])
end


%--------------------------------------------------------------------------
%subfunctions


%PcaPermutationTest - this function randomly permutes the columns of the
%meaurement matrix for each row and then returns the first sigComponents 
%(user input) principal components
%--------------------------------------------------------------------------
    function [varExplained] = PcaPermutationTest...
            (measurementStorage, sigComponents)
        %declare matrix to hold the permutation
        permutation = zeros (size (measurementStorage));
        
        %loop through rows and randomly permute each one
        for rows = 1: size (measurementStorage, 1)
            randIdx = randperm (size(measurementStorage, 2));
            permutation (rows, :) = measurementStorage (rows, randIdx);
        end
        
        %preform pca and only keep the explained variance for the first
        %sigComponents primary components
        [~,~,~,~,varExplained] = pca (permutation);
        varExplained = varExplained (1: sigComponents);
    end
end 