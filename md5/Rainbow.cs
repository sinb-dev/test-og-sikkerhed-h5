using System.Security.Cryptography;

namespace md5;

public class Rainbow
{
    static Dictionary<string, string> rainbowTable = new();
    static string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!\"@%";
    public static string GetPassword(string hashedPassword)
    {
        hashedPassword = hashedPassword.Trim();
        string[] common = ["admin", "123456", "test123", "Admin@123", "password"];
        List<string> modified = new();
        foreach (string password in common)
        {
            modified.AddRange(modify(password));
        }
        List<string> modified2ndDegree = new();
        foreach (string modifiedPassword in modified)
        {
            modified2ndDegree.Add(modifiedPassword);
            modified2ndDegree.AddRange(modify(modifiedPassword));
        }
        foreach (string password in modified2ndDegree)
        {
            rainbowTable[Hashing.GenerateMD5Hash(password)] = password;
        }

        if (rainbowTable.ContainsKey(hashedPassword))
            return rainbowTable[hashedPassword];
        return "";
    }
    static List<string> modify(string password)
    {
        List<string> modified = new();
        modified.AddRange(addCharacter(password));
        modified.AddRange(replaceCharacter(password));
        modified.AddRange(replaceVowelsWithDigits(password));
        return modified;

    }
    static List<string> addCharacter(string input)
    {
        List<string> list = new();
        foreach (char chr in chars) {
            for (int i = 0; i < input.Length; i++)
            {
                list.Add(input.Insert(i, chr.ToString()));
            }
        }
        return list;
    }
    static List<string> replaceCharacter(string input)
    {
        List<string> list = new();
        for (int i = 0; i < input.Length; i++)
        {
            foreach (char chr in chars) {
                list.Add(input.Remove(i,1).Insert(i, chr.ToString()));
            
            }
        }
        return list;
    }
    static List<string> replaceVowelsWithDigits(string input)
    {
        List<string> list = new();
        Dictionary<string,string> vowels = new() { {"a","4"},{"o", "0"}, {"i", "1"}};
        foreach ((string letter, string digit) in vowels)
        {
            input = input.Replace(letter, digit);
        }
        list.Add(input);
        return list;
    }
}