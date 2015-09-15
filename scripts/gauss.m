1;

function retval = gauss1d (x, sigma)
	retval = (1/(2*pi*sigma**2))*e**(-(x**2)/(2*sigma**2));
endfunction

function retval = gauss2d (x, y, sigma)
	retval = (1/(2*pi*sigma**2))*e**(-(x**2 + y**2)/(2*sigma**2));
endfunction

function retval = gaussMatrix (r, sigma)
	n = 2*r+1;
	retval = zeros(n, n);
	for y = 1:n
		for x = 1:n
			retval(y, x) = gauss2d(x-1-r, y-1-r, sigma);
		endfor
	endfor
endfunction
