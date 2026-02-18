
const alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "Æ", "Ø", "Å"]
function generateTable(key)
{
    const table = []
    for (const letter of key)
    {
        const row = []
        const start_index = ALPHABET.indexOf(letter)
        for (let i = 0; i < ALPHABET.length; i++)
        {
            
            row.push(ALPHABET[(start_index + i) % ALPHABET.length])
        }
        table.push(row)
    }
    return table;
}
function encrypt_vigenere(message, key)
{
    var encrypted = "";
    var row_index = 0
    const table = generateTable(key)
    for (let i = 0; i < message.length; i++)
    {
        const letter = message[i].toUpperCase()
        const index = ALPHABET.indexOf(letter)
        if (index === -1) {
            encrypted += letter;
            continue;
        } else {
            const row = table[row_index]
            encrypted += row[index];
        }
        if (row_index+1 < table.length)
            row_index++
        else
            row_index = 0
        
    }
    return encrypted
}
function decrypt_vigenere(message, key)
{
    var decrypted = "";
    var row_index = 0
    const table = generateTable(key)
    for (let i = 0; i < message.length; i++)
    {
        const letter = message[i].toUpperCase()
        const row = table[row_index]
        const index = row.indexOf(letter)
        if (index === -1) {
            decrypted += letter;
            continue;
        } else {
            decrypted += ALPHABET[index];
        }
        if (row_index+1 < table.length)
            row_index++
        else
            row_index = 0
        
    }
    return decrypted;
}

const key = "THISISVIGNERE"
const table = generateTable(key)
let line = "";
for (const letter of ALPHABET)
{
    line += letter+" ";
}
line += "\n";
for (const row of table)
{
    for (const letter of row)
    {
        line += letter+" "
    }
    line += "\n";
}
console.log(line)
var message = "ANGRIB VED DAGGRY"
var enc = encrypt_vigenere(message, key)
console.log(enc)
console.log(decrypt_vigenere(enc, key))