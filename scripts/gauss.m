1;

function retval = gauss1d (x, sigma)
	retval = e**(-(x**2)/(2*sigma**2))/(sqrt(2*pi)*sigma);
endfunction

function retval = gauss2d (x, y, sigma)
	retval = e**(-(x**2 + y**2)/(2*sigma**2))/(2*pi*sigma**2);
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

function retval = gaussNormalizedMatrix (r, sigma)
	A = gaussMatrix(r, sigma);
	n = 2*r+1;
	remainder = (1-sum(sum(A)))/(n*n);
	A += ones(n)*remainder;
	retval = A;
endfunction
