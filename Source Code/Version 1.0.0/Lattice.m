classdef Lattice < LinkedList
    properties (SetAccess = protected)
		CrossSection	string						= []
		l_sample		(1,1)	{mustBeNonnegative}	= 0
		w_sample		(1,1)	{mustBeNonnegative}	= 0	
		t_sample		(1,1)	{mustBeNonnegative}	= 0
		num_layers		(1,1)	{mustBeInteger}		= 0
		Frequency									= []
		TransferMatrix								= []
		SAC											= []
    end
    
    methods
        function sample = Lattice(c_section,freq)
			if nargin > 0
				sample.CrossSection = c_section;
				sample.Frequency = freq;
			end
		end
		
		function insertLayer(sample,layer,idx)
			if isempty(sample.Head)
				sample.insert(layer,1);
				sample.CrossSection = layer.CrossSection;
				sample.l_sample = layer.l_layer;
				sample.w_sample = layer.w_layer;
				sample.t_sample = layer.t_layer;
			else
				if sample.l_sample ~= layer.l_layer || sample.w_sample ~= layer.w_layer || ...
				   sample.CrossSection ~= layer.CrossSection
					error('Dimensions do not match.');
				else
					sample.insert(layer,idx);
				end
			end
			sample.updateThickness(0);
		end
		
		function removeLayer(sample,idx)
			sample.remove(idx);
			sample.updateThickness(0);
		end
		
		function changeParam(sample,cs,l,w)
			sample.CrossSection = cs;
			sample.l_sample = l;
			sample.w_sample = w;
			cur = sample.Head;
			while ~isempty(cur)
				cur.Data.changeParam(cs,l,w);
				cur = cur.Next;
			end
		end
		
		function updateThickness(sample,partUpdate)
			sample.num_layers = sample.Length;
			sample.t_sample = 0;
			cur = sample.Head;
			while ~isempty(cur)
				layer = cur.Data;
				layer.updateT(partUpdate);
				sample.t_sample = sample.t_sample + layer.t_layer;
				cur = cur.Next;
			end
		end
		
		function changeFreq(sample,newFreq)
			sample.Frequency = newFreq;
			sample.TransferMatrix = [];
			sample.SAC = [];
		end
		
		function reverseLatt(sample)
			sample.reverse();
			sample.updateThickness(0);
		end
		
		function cp = copyLatt(sample)
			cp = Lattice(sample.CrossSection,sample.Frequency);
			cur = sample.Head; count = 0;
			while ~isempty(cur)
				layer_cp = copyLayer(cur.Data);
				count = count + 1;
				cp.insertLayer(layer_cp,count);
				cur = cur.Next;
			end
		end
		
		% Calculate the transfer matrix for the sample given frequency range.
		function calcTMM(sample)
			sample.TransferMatrix = cell(length(sample.Frequency),1);
			
			layer = sample.Head;
			while ~isempty(layer)
				freq = sample.Frequency;
				TMM = layer.Data.calcTMM(sample.Frequency);
				if layer.Index == 1
					sample.TransferMatrix = TMM;
				else
					for nf = 1:length(freq)
						sample.TransferMatrix{nf} = sample.TransferMatrix{nf} * TMM{nf};
					end
				end
				layer = layer.Next;
			end
		end
		
		% Calculate absorption coefficient for the sample.
		function calcSAC(sample)
			% Air parameters
			rho0 = 1.225; % Air density, kg/m3
			c0 = 343; % Sound speed, m/s
			Z0 = complex(rho0*c0); % Air impedance
			
			freq = sample.Frequency;
			sample.SAC = zeros(length(freq),1);
			for nf = 1:length(freq)
				mat_whole = sample.TransferMatrix{nf};
				V_final = mat_whole(2,1)/mat_whole(1,1); %A and C in the final matrix.
				R = (1-Z0*V_final)/(1+Z0*V_final);
				sample.SAC(nf,:) = 1-abs(R)^2;
			end
		end
		
		% Displays lattice and its constituent layers.
		function disp(list)
            disp('Lattice containing:');
            disp('Cross Section:      %s\n',list.CrossSection);
            disp('Sample Diameter:    %d\n',list.l_sample);
            disp('Number of Layers:   %d\n',list.num_layers);
			disp('\n');
			item = list.Head; count = 1;
            while ~isempty(item)
                disp('Layer Number:       %d\n',count);
				item.disp();
                item = item.Next; count = count + 1;
            end
        end
    end
end