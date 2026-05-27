using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace megadoctor {

    internal class Edlink {

        public const string StdioPath = "-";

        Process p = null;
        Stream stdin = null;
        Stream stdout = null;
        Stream stderr = null;
        readonly Encoding Encoder = new UTF8Encoding(false);

        string error_msg = null;

        public static Edlink Connect() {

            Edlink link = new Edlink();

            var psi = new ProcessStartInfo {

                FileName = "edlink.exe",
                Arguments = ".stdio .link --protocol-id 0x05",//seek only mega-ed carts (protocol-id 0x05)
                UseShellExecute = false,
                RedirectStandardInput = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            link.p = Process.Start(psi);
            link.stdin = link.p.StandardOutput.BaseStream;
            link.stdout = link.p.StandardInput.BaseStream;
            link.stderr = link.p.StandardError.BaseStream;


            return link;
        }

        public string ReadError() {

            if (error_msg != null) {
                return error_msg;
            }

            try {
                WriteLine("exit");
            } catch (Exception) { }

            error_msg = p.StandardError.ReadToEnd();
            return error_msg;
            /*
            string resp = "";

            MemoryStream ms = new MemoryStream();

           // while (stderr.CanRead) {
                resp += ReadLine(stderr);
            //}

            return resp;*/
        }

        public void Stop() {

            p.Kill();
        }

        public string ReadLine() {
            return ReadLine(stdin);
        }

        public string ReadLine(Stream s) {
            //return stdin_txt.ReadLine();

            MemoryStream ms = new MemoryStream();

            while (true) {

                int b = s.ReadByte();

                if (b == -1) {
                    throw new Exception("EOF");
                }

                if (b == '\n') {
                    break;
                }

                if (b >= ' ') {
                    ms.WriteByte((byte)b);
                }
            }

            //return Encoder.GetString(ms.ToArray()).TrimStart('\uFEFF').Trim();
            return Encoder.GetString(ms.ToArray()).Trim();
        }

        public void WriteLine(string txt) {

            byte[] buff = Encoder.GetBytes(txt + "\n");
            StdouWrite(buff, 0, buff.Length);
        }

        public byte[] Read(string path) {

            int len = GetInt(ReadLine());
            byte[] buff = new byte[len];

            for (int i = 0; i < len;) {
                int block = stdin.Read(buff, 0, buff.Length - i);
                if (block < 0) {
                    throw new Exception("EOF");
                }
                i += block;
            }

            return buff;
        }

        public string ReadText(string path) {

            byte[] buff = Read(path);
            return Encoder.GetString(buff);//.Trim()
        }

        public byte[] ReadFile() {



            int len = GetInt(ReadLine());
            byte[] buff = new byte[len];

            for (int i = 0; i < len;) {
                int block = stdin.Read(buff, 0, buff.Length - i);
                if (block < 0) {
                    throw new Exception("EOF");
                }
                i += block;
            }

            return buff;

        }

        public void WriteFile(byte[] buff, int offset, int len) {

            WriteLine(len.ToString());
            StdouWrite(buff, offset, len);
        }
        public void WriteFile(byte[] buff) {

            WriteFile(buff, 0, buff.Length);
        }

        public void WriteFile(string txt) {

            byte[] buff = Encoding.UTF8.GetBytes(txt);
            WriteFile(buff);
        }

        void StdouWrite(byte[] buff, int offset, int len) {

            stdout.Write(buff, offset, len);
            stdout.Flush();
        }

        int GetInt(string val) {

            if (val.ToLower().StartsWith("0x")) {
                return int.Parse(val.Substring(2), NumberStyles.HexNumber);
            } else {
                return int.Parse(val);
            }
        }
    }
}
