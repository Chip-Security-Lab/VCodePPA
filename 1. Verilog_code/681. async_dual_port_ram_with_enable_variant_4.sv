//SystemVerilog
// Lookup table based subtractor module
module lut_subtractor #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] a,
    input wire [DATA_WIDTH-1:0] b,
    output reg [DATA_WIDTH-1:0] diff
);
    reg [DATA_WIDTH-1:0] lut [0:255];
    
    // Initialize lookup table
    initial begin
        for (int i = 0; i < 256; i++) begin
            for (int j = 0; j < 256; j++) begin
                lut[i*256 + j] = i - j;
            end
        end
    end
    
    always @* begin
        diff = lut[{a, b}];
    end
endmodule

// Memory array submodule
module ram_array #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    input wire we_a, we_b,
    input wire en_a, en_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    wire [DATA_WIDTH-1:0] diff_a, diff_b;
    
    lut_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) sub_a (
        .a(din_a),
        .b(ram[addr_a]),
        .diff(diff_a)
    );
    
    lut_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) sub_b (
        .a(din_b),
        .b(ram[addr_b]),
        .diff(diff_b)
    );
    
    always @* begin
        if (en_a && we_a) ram[addr_a] = diff_a;
        if (en_b && we_b) ram[addr_b] = diff_b;
        dout_a = ram[addr_a];
        dout_b = ram[addr_b];
    end
endmodule

// Port A control submodule
module port_a_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire we,
    input wire en,
    output reg [ADDR_WIDTH-1:0] addr_out,
    output reg [DATA_WIDTH-1:0] din_out,
    output reg we_out,
    output reg en_out
);
    always @* begin
        addr_out = addr;
        din_out = din;
        we_out = we && en;
        en_out = en;
    end
endmodule

// Port B control submodule
module port_b_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire we,
    input wire en,
    output reg [ADDR_WIDTH-1:0] addr_out,
    output reg [DATA_WIDTH-1:0] din_out,
    output reg we_out,
    output reg en_out
);
    always @* begin
        addr_out = addr;
        din_out = din;
        we_out = we && en;
        en_out = en;
    end
endmodule

// Top-level module
module async_dual_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire en_a, en_b
);
    wire [ADDR_WIDTH-1:0] addr_a_int, addr_b_int;
    wire [DATA_WIDTH-1:0] din_a_int, din_b_int;
    wire we_a_int, we_b_int;
    wire en_a_int, en_b_int;
    
    port_a_control #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_a_ctrl (
        .addr(addr_a),
        .din(din_a),
        .we(we_a),
        .en(en_a),
        .addr_out(addr_a_int),
        .din_out(din_a_int),
        .we_out(we_a_int),
        .en_out(en_a_int)
    );
    
    port_b_control #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) port_b_ctrl (
        .addr(addr_b),
        .din(din_b),
        .we(we_b),
        .en(en_b),
        .addr_out(addr_b_int),
        .din_out(din_b_int),
        .we_out(we_b_int),
        .en_out(en_b_int)
    );
    
    ram_array #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_core (
        .addr_a(addr_a_int),
        .addr_b(addr_b_int),
        .din_a(din_a_int),
        .din_b(din_b_int),
        .we_a(we_a_int),
        .we_b(we_b_int),
        .en_a(en_a_int),
        .en_b(en_b_int),
        .dout_a(dout_a),
        .dout_b(dout_b)
    );
endmodule