%--------------------------------------------------------------------------
%arctangent - this function defines an arctangent function that maps to the
%entire unit circle
%s/o to josh wang 
%--------------------------------------------------------------------------
function orientation = arctangent(numerator, denominator)
	if denominator == 0
		result = pi/2;
		if numerator < 0
			result = result*(-1);
		elseif numerator == 0
			result = NaN;
		end
	else
		result = atan(numerator/denominator);
		if denominator < 0
			if result > 0
				result = result - pi;
			else
				result = result + pi;
			end
		end
	end
	orientation = result;
end

