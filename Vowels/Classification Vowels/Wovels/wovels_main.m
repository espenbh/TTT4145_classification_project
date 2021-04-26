%% README
% We have 4 formants, which acts as our features.
% For each formant, 4 different modes can be used
% Fx20: vowel is held at 20% the original length
% Fx50: vowel is held at 50% the original length
% Fx80: vowel is held at 50% the original length
% Fxs: vowel is held at 100% the original length
%
% We have 12 classes, which is our vowels.
% Each wovel has 139 samples.
% These samples are distributed over 45 males, 48 women,
% 27 boys and 19 girls.

%% Clear
clc
clear all
close all

%% Import data
% Read vowdata_nohead.dat into [files, dur, F0s...] 
% formated by %s%4.1f%4.1f%4.1...
% "files" are interpreted by the rule below

[files,dur,F0s,F1s,F2s,F3s,F4s,F120,F220,F320,F150,F250,F350,F180,F280,F380] =  ...
textread('vowdata_nohead.dat',                                                  ...
'%s%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f%4.1f');

%Forms character arrays to order the data
vowel = str2mat('ae','ah','aw','eh','ei','er','ih','iy','oa','oo','uh','uw');
vowel_names = ['ae';'ah';'aw';'eh';'ei';'er';'ih';'iy';'oa';'oo';'uh';'uw'];
talker_group = str2mat('m','w','b','g');

filenames=char(files);          % convert cell array to character matrix
[nfiles,~]=size(filenames);     % Extract file size parameters

for ifile=1:nfiles  %For all data points, put their data into the right spot in the character arrays
    vowel_code(ifile) = strmatch(filenames(ifile,4:5),vowel);               %Match current datapoint with wovel number, store result in array
    talker_group_code(ifile) = strmatch(filenames(ifile,1),talker_group);   %Match current datapoint with talker group, store result in array
    talker_number(ifile) = str2num(filenames(ifile,2:3));                   %Match current datapoint with talker number, store result in array
end

%% Parameters
frequencies=[F0s,F1s,F2s,F3s,F4s,F120,F220,F320,F150,F250,F350,F180,F280,F380];
frequency_names=['F0s ';'F1s ';'F2s ';'F3s ';'F4s ';'F120';'F220';'F320';'F150';'F250';'F350';'F180';'F280';'F380'];

N_bins=20;              % Bins for histograms

N_talkers=139;          % Number of talkers
N_vowels=length(vowel); % Number of wovels

feature_mode=100;       % Decide data registration mode
N_features= 4;          % Number of features used for classification

N_training= 70;         % Number of data points per class used for training
N_test=     N_talkers-N_training;   % Number of data points per class used for testing

N = N_talkers*N_vowels; % Total number of data points

%% Choose features
%Extract features based on feature mode

features=       zeros(N_vowels*N_talkers, N_features);
feature_names=  zeros(1,N_features);

switch feature_mode
    case 20     
        features=       [F120 F220 F320];
        feature_names=  ['F120';'F220';'F320'];
    case 50     
        features=       [F150 F250 F350];
        feature_names=  ['F150';'F250';'F350'];
    case 80     
        features=       [F180 F280 F380];
        feature_names=  ['F180';'F280';'F380'];
    case 100    
        features=       [F0s F1s F2s F3s];
        feature_names=  ['F1s';'F2s';'F3s'];
end

%Remove corrupted data
%Taken out of test set
data_indeks=1;
while true
    sum(features(data_indeks, :)==0)
    if sum(features(data_indeks, :)==0)~=0
        features(data_indeks,:)
        features(data_indeks,:) = [];
        vowel_code(data_indeks) = [];
        continue
    end
    if size(features,1) > data_indeks
        data_indeks=data_indeks+1;
    else
        break
    end
end
N=size(features,1);

% Shuffle datapoints, to avoid training on men/women, and testing on
% boys/girls
new_index=randperm(N);
features=features(new_index,:);
vowel_code=vowel_code(new_index);


%% Separate training and test data

% Split data-array in two, one for testing, one for training
% Also make vowel code arrays to extract the right vowels

training_features=zeros(N_training, N_features);
training_vowel_code=zeros(1,N_training);
fill_cursor_test=0;
for n_vowels=1:N_vowels
    index_list=find(vowel_code==n_vowels);
    size_vowel_set=size(index_list,2);
    size_test_set=size_vowel_set-70;
    
    training_features((n_vowels-1)*N_training+1:        ...
    n_vowels*N_training, :) =                           ...
    features(index_list(1:N_training),:);

    test_features(fill_cursor_test+1:                ...
    fill_cursor_test+size_test_set, :) =             ...
    features(index_list(N_training+1:size_vowel_set),:);

    training_vowel_code(1,(n_vowels-1)*N_training+1:    ...
    n_vowels*N_training)=                               ...
    ones(1,N_training)*n_vowels;

    test_vowel_code(1, fill_cursor_test+1:              ...
    fill_cursor_test+size_test_set) =                ...
    ones(1,size_test_set)*n_vowels;
    
    fill_cursor_test=fill_cursor_test+size_vowel_set-70;
end

%% Histogram
% Displaying all classes and features, using all data points

% figure(1)
% for n_features=1:N_features            
%     for nw=1:N_vowels                  
%         subplot(N_features,N_vowels,N_vowels*(n_features-1)+nw);
%         current_feature=features(:,n_features);
%         hist(current_feature(find(vowel_code==nw)),N_bins);
%         xlabel(vowel_names(nw, :));
%         ylabel(feature_names(n_features, :));
%     end
% end

%% Calculate mean and covarianance 
% Using training data set

means=zeros(N_vowels, N_features);
covariances=zeros(N_vowels, N_features, N_features);


for n_features=1:N_features
    for n_vowels=1:N_vowels
        current_vowel_indeks=find(training_vowel_code==n_vowels);
        current_data=training_features(current_vowel_indeks,n_features);
        means(n_vowels, n_features) = mean(current_data);
%       disp(['Mean ', feature_names(n_features, :), ' for ', vowel_names(nw, :), ' : ',num2str(means(nw, n_features))]);
    end
end

for n_vowels=1:N_vowels
    current_vowel_indeks=find(training_vowel_code==n_vowels);
    current_data=training_features(current_vowel_indeks, :);
    covariances(n_vowels, :, :) = cov(current_data);
%    covariances(n_vowels, :, :) = cov(x)-0.01*cov(x);      % If regularization is needed
%    disp(['Covariance for ', vowel_names(n_vowels, :)])    % Displaying covariance
%    disp(cov(x)-0.01*cov(x))
end

%% Calculate single Gaussian with equation (training)
%Caluclate single Gaussian distribution
%Calculating for all classes
x=sym('x', [N_features 1]);
single_gaussian=sym('x',[N_vowels 1]);

for n_vowels=1:N_vowels
    sigma=reshape(covariances(n_vowels, :, :), [N_features, N_features]);
    mu=means(n_vowels, :)';
    single_gaussian(n_vowels)= 1/sqrt((2*pi)^N_features*det(sigma))*exp(-1/2*((x-mu)'*inv(sigma)*(x-mu)));
end

%% Calculating GMM with fitgmdist (training)
GMMs=cell(N_vowels, 1);
for n_vowels=1:N_vowels
    current_data_1 = training_features((n_vowels-1)*N_training+1:n_vowels*N_training, 1:N_features);
    %current_data_2 = training_features(find(training_vowel_code==n_vowels),1:N_features)
    current_data_2 = training_features(find(training_vowel_code==n_vowels),:);
    GMMs{n_vowels}=fitgmdist(current_data_2, 3, 'RegularizationValue', 0.00001);
end

%% Finding confusion matrix by evaluating full Gaussian equations (testing)
% confuse_matrix=zeros(N_vowels, N_vowels);
% for n_test=1:N_test*N_vowels
%     current_data=test_features(n_test, 1:N_features);
%     actual_class=test_features(n_test, N_features+1);
%     current_all_probs=zeros(1, N_vowels);
%     for n_vowels=1:N_vowels
%         current_gaussian=single_gaussian(n_vowels);
%         current_all_probs(1,n_vowels)=subs(current_gaussian,[x(1), x(2), x(3)],current_data);
%     end
%         [~, current_best_class_fit]=max(current_all_probs);
%         confuse_matrix(current_best_class_fit, actual_class)=...
%         confuse_matrix(current_best_class_fit, actual_class)+1;
% end

%% Finding confusion matrix by mvnpdf evaluation from mean and covariance at each datapoint (testing)
% confuse_matrix=zeros(N_vowels, N_vowels);
% for n_vowels_outer=1:N_vowels
%     current_vowel_indeks=find(test_vowel_code==n_vowels_outer);
%     size_test_set=size(current_vowel_indeks, 2);
%     for i = 1:size_test_set
%         current_indeks=current_vowel_indeks(i);
%         current_data=test_features(current_indeks,:);
%         current_all_probs=zeros(1, N_vowels);
%         for n_vowels_inner=1:N_vowels
%             sigma=reshape(covariances(n_vowels_inner,:,:), [N_features,N_features]);
%             mu=means(n_vowels_inner, :);
%             current_all_probs(1,n_vowels_inner)=mvnpdf(current_data, mu, sigma);
%         end
%         [~, current_best_class_fit]=max(current_all_probs);
%         confuse_matrix(current_best_class_fit, n_vowels_outer)=...
%         confuse_matrix(current_best_class_fit, n_vowels_outer)+1;
%     end
% end

%% Finding confusion matrix by evaluating gmdistribution objects
confuse_matrix=zeros(N_vowels, N_vowels);
for n_vowels_outer=1:N_vowels
    current_vowel_indeks=find(test_vowel_code==n_vowels_outer);
    size_test_set=size(current_vowel_indeks, 2);
    for i = 1:size_test_set
        current_indeks=current_vowel_indeks(i);
        current_data=test_features(current_indeks,:);
        current_all_probs=zeros(1, N_vowels);
        for n_vowels_inner=1:N_vowels
            current_all_probs(1,n_vowels_inner)=pdf(GMMs{n_vowels_inner}, current_data);
        end
        [~, current_best_class_fit]=max(current_all_probs);
        confuse_matrix(current_best_class_fit, n_vowels_outer)=...
        confuse_matrix(current_best_class_fit, n_vowels_outer)+1;
    end
end

%% Evaluating the error rate of the confusion matrix
correct=0;
error=0;
for i=1:N_vowels
    for j=1:N_vowels
        if i==j
            correct=correct+confuse_matrix(i,j);
        else
            error=error+confuse_matrix(i,j);
        end
    end
end
hitrate=correct/(correct+error);
errorrate=error/(error+correct);

%% Plot

figure(2)
%3D scatter with 3 features and all classes
% subplot(2,2,1)
% for n_vowels=1:N_vowels
%     scatter3(features((n_vowels-1)*N_talkers+1:n_vowels*N_talkers,1), features((n_vowels-1)*N_talkers+1:n_vowels*N_talkers,2), features((n_vowels-1)*N_talkers+1:n_vowels*N_talkers, 3))
%     hold on
% end

%3D scatter with 3 features, class 1 and mean for class 1
subplot(2,2,1)
    vowel_1_indeks=find(vowel_code==1);
    scatter3(features(vowel_1_indeks,1), features(vowel_1_indeks,2), features(vowel_1_indeks, 3))
    hold on
    scatter3(means(1,1), means(1,2), means(1,3))
    

% 
% xlabel('feature_names(1, :)')
% ylabel('feature_names(2, :)')
% zlabel('feature_names(3, :)')
% legend('ae','ah','aw','eh','er','ei','ih','iy','oa','oo','uh','uw')

% % 3D scatter plot for first class
% subplot(2,2,2)
% scatter3(features(1:N_talkers,1), features(1:N_talkers,2), features(1:N_talkers, 3))
% hold on
% scatter3(means(1,1), means(1,2), means(1,3))
% xlabel('F1s')
% ylabel('F2s')
% zlabel('F3s')

% Single Gaussian 3D plot for first class
% subplot(2,2,3)
% f=single_gaussian(1);
% f_handle=@(x1, x2, x3) f;
% fimplicit3(f, [-10000 10000 -10000 10000 -10000 10000])
% xlabel('F1s')
% ylabel('F2s')
% zlabel('F3s')

subplot(2,2,2)
x0=0;
y0=0;
z0=0;
gmPDF = @(x,y,z) arrayfun(@(x0,y0,z0) pdf(GMMs{1},[x0 y0,z0]),x,y, z);
fimplicit3(gmPDF,[-10000 10000 -10000 10000 -10000 10000])

%% Remove outliers F0
% Working on copy => non destructive
% x = F0s(find(talker_group_code==1));
% mx = mean(x);
% disp('Mean F0 for males:')
% disp(mx);
% 
% sd2         = std(x) * 2;
% ind_higher  = find(x > mx+sd2);
% ind_lower   = find(x < mx - sd2);
% ind         = intersect(ind_higher, ind_lower);
% x(ind)      = [];
% mx          = mean(x);
% disp('Mean F0 for males (outliers removed): ')
% disp(mx);

function [processed_data] = improved_find(feature_array, key_array, key, N_features)
    hits=key_array==key;
    j=1;
    processed_data=zeros(sum(hits),N_features);
    size(hits,2)
    for i=1:size(hits,2)
        if hits(i)
            processed_data(j,:)=feature_array(i,:);
            j=j+1;
        end
    end
    %processed_data = feature_array(find(key_array==key),1:N_features);
end
