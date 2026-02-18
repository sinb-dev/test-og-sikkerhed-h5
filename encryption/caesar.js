const ALPHABET = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "Æ", "Ø", "Å"]
const ROTATION = 10
function encrypt(message, rotation)
{
    var encrypted = "";
    for (const letter of message.toUpperCase())
    {
        const index = ALPHABET.indexOf(letter)
        if (index === -1) {
            encrypted += letter;
        } else {
            var new_index = index + rotation
            if (new_index >= ALPHABET.length) 
                new_index -= ALPHABET.length
                
            encrypted += ALPHABET[new_index];
        }
    }
    return encrypted
}
function decrypt(message, rotation)
{
    var decrypted = "";
    for (const letter of message.toUpperCase())
    {
        const index = ALPHABET.indexOf(letter)
        if (index === -1) {
            decrypted += letter;
        } else {
            var new_index = index - rotation
            if (new_index < 0) new_index += ALPHABET.length
                
            decrypted += ALPHABET[new_index];
        }
            
    }
    return decrypted;
}
var message = "AHvad er det mindst talte sprog i verden?"
var enc = encrypt(message, ROTATION)
console.log(enc)
console.log(encrypt("Tegnsprog", 17))

//console.log(decrypt(enc))