export type headers = {[string]: string}

export type request = {
	Url: string;
	Method: string?;
	Headers: headers?;
	Body: string?;
}

export type response = {
	Success: boolean;
	Body: string;
	StatusCode: number;
	StatusMessage: string;
	Headers: headers?
}

return true
