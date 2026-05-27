using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.NetworkInformation;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace megadoctor {
    internal class Program {

        static Edlink link;
        static bool cart_error = false;
        static bool mode_core = false;
        static bool mode_cart1 = false;

        static void Main(string[] args) {


            if (args.Length > 0 && args[0].ToLower().Equals("cart1")) {
                mode_cart1 = true;
            }

            try {

                Doctor();
                if (link.ReadError().Length > 0) {
                    throw new Exception("LINK ERROR!");
                }

            } catch (Exception x) {

                Console.Clear();

                Console.ForegroundColor = ConsoleColor.Red;

                string err_link = "";

                try {
                    err_link = link.ReadError();
                } catch (Exception) { }

                Console.WriteLine("");
                if (err_link.Length > 0) {
                    Console.Error.WriteLine("LINK " + err_link);
                } else {
                    Console.Error.WriteLine("ERROR: " + x.Message);
                }
                Console.ResetColor();
            }

            try {
                link.Stop();
            } catch (Exception) {
            }
        }

        static void Doctor() {

            link = Edlink.Connect();


            link.WriteLine("devinf --file -");
            string dev_inf = link.ReadText("-");
            Console.WriteLine(dev_inf);


            string fpg_path = "";
            if (dev_inf.Contains("EverDrive CORE")) {
                mode_core = true;
                fpg_path = "mega-core.rbf";
            } else {
                fpg_path = "mega-pro.rbf";
            }

            //load doctor mapper and app to the console
            link.WriteLine("reset --mode hard memwr --addr 0 --file megadoctor.md fpga --file " + fpg_path);
            link.WriteLine("memwr --addr 0 --file -");
            link.WriteFile(new byte[] { (byte)(mode_cart1 ? 1 : 0) });
            link.WriteLine("reset --mode off");

            Console.Clear();
            Console.CursorVisible = false;


            while (true) {


                Console.CursorLeft = 0;
                Console.CursorTop = 0;

                PrintDiag(link);
                Console.WriteLine("Press any key to exit...");
                Thread.Sleep(100);

                if (Console.KeyAvailable) {
                    break;
                }
            }

        }

        static void PrintDiag(Edlink link) {

            link.WriteLine("memrd --addr 0 --len 80 --file -");
            byte[] buff = link.ReadFile();

            //Console.Clear();

            int ptr = 64;
            cart_error = false;

            PrintClk("B19 CPU VCLK", (buff[ptr++] << 16) | (buff[ptr++] << 8) | buff[ptr++]);
            if (mode_core) {
                ptr += 3;
            } else {
                PrintClk("B15 VDP EDCLK", (buff[ptr++] << 16) | (buff[ptr++] << 8) | buff[ptr++]);
            }
            PrintCart("B32 CPU CART", buff[ptr + 1], buff[ptr + 2]);
            PrintCtr("B16 CPU CAS0", buff[ptr++]);
            PrintCtrRef("B17 CPU CE0", buff[ptr++], mode_cart1 ? 0x00 : 0x80);
            PrintCtr("B26 CPU ASEL", buff[ptr++]);
            PrintCtr("B28 CPU LWR", buff[ptr++]);
            PrintCtr("B29 CPU UWR", buff[ptr++]);
            PrintCtr("B18 CPU AS", buff[ptr++]);
            PrintCtr("B20 CPU DTACK", buff[ptr++]);

            PrintDataMask("CPU ADDR BUS [23:16]", buff[ptr++]);
            PrintDataMask("CPU ADDR BUS [15:8]", buff[ptr++]);
            PrintDataMask("CPU ADDR BUS [7:0]", buff[ptr++] & ~1);

            ptr = 0;
            int cpu_dm_hi = 0;
            int cpu_dm_lo = 0;

            cpu_dm_hi |= buff[ptr++] ^ 0x00;
            cpu_dm_lo |= buff[ptr++] ^ 0x00;
            cpu_dm_hi |= buff[ptr++] ^ 0xff;
            cpu_dm_lo |= buff[ptr++] ^ 0xff;
            cpu_dm_hi |= buff[ptr++] ^ 0x55;
            cpu_dm_lo |= buff[ptr++] ^ 0x55;
            cpu_dm_hi |= buff[ptr++] ^ 0xaa;
            cpu_dm_lo |= buff[ptr++] ^ 0xaa;

            PrintDataMask("CPU RAM DATA BUS [15:8]", cpu_dm_hi);
            PrintDataMask("CPU RAM DATA BUS [7:0]", cpu_dm_lo);

            Print("CPU RAM BYTE WR", buff[ptr] == 0x11 && buff[ptr + 1] == 0x22 ? "OK" : "ERR");
            ptr += 2;

            bool ram_addr_ok = true;
            for (int i = 0; i < 17; i++) {
                if (buff[ptr++] != i) {
                    ram_addr_ok = false;
                }
            }
            Print("CPU RAM ADDR BUS", ram_addr_ok ? "OK" : "ERR");
            PrintStatus("CPU RAM ARRAY", buff[ptr++]);


            int vdp_dm_hi = 0;
            int vdp_dm_lo = 0;

            vdp_dm_hi |= buff[ptr++] ^ 0x00;
            vdp_dm_lo |= buff[ptr++] ^ 0x00;
            vdp_dm_hi |= buff[ptr++] ^ 0xff;
            vdp_dm_lo |= buff[ptr++] ^ 0xff;
            vdp_dm_hi |= buff[ptr++] ^ 0x55;
            vdp_dm_lo |= buff[ptr++] ^ 0x55;
            vdp_dm_hi |= buff[ptr++] ^ 0xaa;
            vdp_dm_lo |= buff[ptr++] ^ 0xaa;

            PrintDataMask("VDP RAM DATA BUS [15:8]", vdp_dm_hi);
            PrintDataMask("VDP RAM DATA BUS [7:0]", vdp_dm_lo);
            PrintStatus("VDP RAM ARRAY", buff[ptr++]);

            int z80_dm = 0;
            z80_dm |= buff[ptr++] ^ 0x00;
            z80_dm |= buff[ptr++] ^ 0xff;
            z80_dm |= buff[ptr++] ^ 0x55;
            z80_dm |= buff[ptr++] ^ 0xaa;

            PrintDataMask("Z80 RAM DATA BUS [7:0]", z80_dm);

            ram_addr_ok = true;
            for (int i = 0; i < 14; i++) {
                if (buff[ptr++] != i) {
                    ram_addr_ok = false;
                }
            }
            Print("Z80 RAM ADDR BUS", ram_addr_ok ? "OK" : "ERR");
            PrintStatus("Z80 RAM ARRAY", buff[ptr++]);
            PrintStatus("Z80 CPU CORE", buff[ptr++]);


            Console.WriteLine("");


            /*
            int old_x = Console.CursorLeft;
            int old_y = Console.CursorTop;
            int raw_x = 42;
            int raw_y = 0;
            Console.CursorLeft = raw_x;
            Console.CursorTop = raw_y++;
            Console.WriteLine("RAW DATA:");
            for (int i = 0; i < buff.Length; i += 16) {

                Console.CursorLeft = raw_x;
                Console.CursorTop = raw_y + i / 16;
                Console.WriteLine(BitConverter.ToString(buff, i, 16));
            }
            Console.CursorLeft = old_x;
            Console.CursorTop = old_y;*/

        }

        static void PrintCart(string name, int ce0, int asel) {

            bool err = false;

            string cart_status = "???";
            if (mode_cart1) {
                if (ce0 == 0 && asel == 0x80) {
                    cart_status = "OK";
                }
            } else {
                if (ce0 == 0 && asel >= 4 && asel < 8) {
                    cart_status = "ERR";
                    err = true;
                } else if (ce0 == 0x80 && asel == 0x80) {
                    cart_status = "OK";
                }
            }
            Print(name, cart_status);

            cart_error = err;
        }
        static void PrintStatus(string name, int val) {

            string bits = Convert.ToString(val, 2).PadLeft(8, '0');

            Print(name, val == 0xA0 ? "OK" : val == 0xA1 ? "ERR" : "???");
        }

        static void PrintDataMask(string name, int val) {

            string bits = Convert.ToString(val, 2).PadLeft(8, '0');

            Print(name, val == 0 ? "OK" : "ERR", "[" + bits + "]");
        }

        static void PrintClk(string name, int val) {

            Print(name, val + " Hz");
        }

        static void PrintCtrRef(string name, byte val, int ref_val) {

            Print(name, val == ref_val ? "OK" : "ERR", val.ToString("X2"));
        }

        static void PrintCtr(string name, byte val) {

            PrintCtrRef(name, val, 0x80);
        }

        static void Print(string msg, string status) {

            Print(msg, status, "");
        }

        static void Print(string msg, string status, string val) {

            ConsoleColor old_color = Console.ForegroundColor;

            if (cart_error) {
                status = "???";
            }

            if (status.Equals("OK")) {
                Console.ForegroundColor = ConsoleColor.Green;
            }
            if (status.Equals("ERR")) {
                Console.ForegroundColor = ConsoleColor.Red;
            }
            if (status.Equals("???")) {
                Console.ForegroundColor = ConsoleColor.Yellow;
            }

            string txt = msg.PadRight(26, '.');
            txt += status.PadRight(4, ' ');

            txt += val;
            txt = txt.PadRight(40, ' ');

            Console.WriteLine(txt);

            Console.ForegroundColor = old_color;
        }
    }
}
