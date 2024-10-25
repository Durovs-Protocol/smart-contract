import axios from 'axios'
import * as crypto from 'crypto'

const url = 'https://api.bybit.com';

const apiKey = process.env.BYBIT_API_KEY!!
const secret = process.env.BYBIT_API_SECRET!!
const recvWindow = 5000;
const timestamp = Date.now().toString();

function generateSignature(parameters: string, secret: string): string {
    return crypto.createHmac('sha256', secret).update(timestamp + apiKey + recvWindow + parameters).digest('hex');
}

async function http_request(endpoint: string, method: string, data: string, Info: string) {
    let sign = generateSignature(data, secret);
    let fullendpoint: string;

    if (method === "POST") {
        fullendpoint = url + endpoint;
    } else {
        fullendpoint = url + endpoint + "?" + data;
        data = "";
    }

    let headers: object = {
        'X-BAPI-SIGN-TYPE': '2',
        'X-BAPI-SIGN': sign,
        'X-BAPI-API-KEY': apiKey,
        'X-BAPI-TIMESTAMP': timestamp,
        'X-BAPI-RECV-WINDOW': recvWindow.toString()
    };

    if (method === "POST") {
		Object.assign(headers, {'Content-Type': 'application/json; charset=utf-8'})
    }

    let config = {
        method: method,
        url: fullendpoint,
        headers: headers,
        data: data
    };

    console.log(Info + " Calling....");
    await axios(config)
        .then(function (response) {
            console.log(JSON.stringify(response.data));
        })
        .catch(function (error) {
            console.log(error.response.data);
        });
}

export async function getTicker(): Promise<void> {

    let endpoint = "/v5/market/tickers";
    
	let data = 'category=linear&symbol=TONUSDT';
    await http_request(endpoint, "GET", data, "Create");
}
