const fs = require('fs');
const readline = require('readline');

const filePath = './input_file.txt';

const pValues = [];
const sig = [];
const pArr = [];
const sArr = [];
const key = 'mayo1';
const paramDict = {
    'mayo1': {w:8,nibble:4,n:66,m:64,k:9,o:8,p_len:18,s_len:10,f:[8,0,2,8,0]},
    'mayo2': {w:8,nibble:4,n:78,m:64,k:4,o:18,p_len:18,s_len:10,f:[8,0,2,8,0]},
}
const params = paramDict[key];
const sThreshold = Math.pow(2,params.s_len);


const readFile = async () => {
  try {
    const fileStream = fs.createReadStream(filePath);

    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity, 
    });

    for await (const line of rl) {
      const parts = line.trim().split(/\s+/); 
      if (parts.length === 4) {
        const index = parseInt(parts[0], 16);
        const hex1 = parseInt(parts[1], 16);
        const hex2 = parseInt(parts[2], 16);
        const hex3 = parseInt(parts[3], 16);
        if(index<sThreshold-1) {
            sig.push(hex2);
        }
        pValues.push(hex1);
    }
}
  } catch (error) {
    console.error('Error reading file:', error);
  }
};

const writeFile = async (arr) => {
    try {
        const fileStream = fs.createReadStream(filePath);
        const rl = readline.createInterface({
            input: fileStream,
            crlfDelay: Infinity, 
        });
        const outputStream = fs.createWriteStream('./input_gen_'+key+'_file.txt');
        let l=0;
        for await (const line of rl) {
            const parts = line.trim().split(/\s+/); 
            if (parts.length === 4) {
                const index = parts[0];
                const hex1 = parts[1];
                const hex2 = parts[2];
                const hex3 = (l<32) ? arr[2*l].toString()+arr[2*l+1].toString():'00';
                outputStream.write(`${hex1} ${hex2} ${hex3}\n`);
                l++;
            }
        }
    } catch (error) {
      console.error('Error reading file:', error);
    }
};

const divNibble = (byte) => {
    const highNibble = (byte & 0xF0) >> 4;
    const lowNibble = byte & 0x0F;
    return [highNibble,lowNibble];
}

const gfMultiply = (a, b) => {
    const logs = [-1,0,1,4,2,8,5,10,3,14,9,7,6,13,11,12];
    const alogs = [1,2,4,8,3,6,12,11,5,10,7,14,15,13,9,1];
      if (a === 0 || b === 0) return 0;
      const logA = logs[a];
      const logB = logs[b];
      const resultExponent = (logA + logB) % 15;
      return alogs[resultExponent];
}

const yMod = (a) => {
    let temp = a;
    let um = temp.shift();
    temp.push(0);
    for(let i=0;i<params.f.length;i++){
        let mul = gfMultiply(um,params.f[i]);
        temp[params.m-1-i] = temp[params.m-1-i] ^ mul;
    }
    return temp;
}

const gfAdd = (a,b) => {
    let temp=[];
    for(let i=0;i<a.length;i++){
        temp.push(a[i] ^ b[i]);
    }
    return temp;
}

const partialMultiply = (a,b) => {
    let temp=0;
    for(let i=0;i<a.length;i++){
        let mul = gfMultiply(a[i],b[i]);
        temp = temp ^ mul;
    }
    return temp;
}

const arrMultiply = async () => {
    let result=Array.from({ length: params.m }, () => 0);
    for(let i=0;i<=params.k-1;i++){
        for(let j=params.k-1;j>=i;j--){
            let a=0;
            let x=[];
            let y=[];
            while(a<params.m){
                let row=0;
                let temp1=[];
                let temp2=[];
                while(row<params.n){
                    //if(a==60 && j==params.k-1 && i==0) console.log('internal',row,pArr[a*params.n+row].map(o=>o.toString(16)).join(''),'\n')//,sArr[i],sArr[j])
                    temp1.push(partialMultiply(pArr[a*params.n+row],sArr[i]));
                    temp2.push(partialMultiply(pArr[a*params.n+row],sArr[j]));
                    row++;
                }
                let u1 = partialMultiply(temp1,sArr[j]);
                let u2 = partialMultiply(temp2,sArr[i]);
                //if(j==params.k-1 && i==0) console.log('final',temp1,temp2,u1,u2,i==j?u1:u1^u2)
                x.push(i==j?u1:u1^u2);
                a++;
            }
           // if(j==params.k-1 && i==0) console.log(x);
            let yVals = [...gfAdd(yMod(x),result)];
            result = yVals;
        }
    }
    return result;
}


const resetValues = async () => {
    let temp=[];
    let i=0;
    let j=0;
    while(i<params.n*params.m*params.n/2){
        temp.push(...divNibble(pValues[i]));
        if((i+1)%(params.n/2)==0){
            pArr.push(temp);
            temp=[];
        }
        i++;
    }
    temp=[];

    while(j<sig.length){
        temp.push(...divNibble(sig[j]));
        if((j+1)%(params.n/2)==0){
            sArr.push(temp);
            temp=[];
        }
        j++;
    }
}

const main = async () => {
    let str='';
    await readFile();
    await resetValues();
    let result = await arrMultiply();
    result = result.map((ele)=>ele.toString(16));
    const startTime = performance.now();
    writeFile(result);
    console.log(result);
    const endTime = performance.now();
    console.log(`Execution time: ${endTime - startTime} milliseconds`);
}

main();