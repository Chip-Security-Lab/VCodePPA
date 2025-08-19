//SystemVerilog
// 顶层模块
module async_dual_port_ram_with_variable_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b
);

    wire [DATA_WIDTH-1:0] din_a_2c, din_b_2c;
    wire [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    
    // 实例化补码转换模块
    complement_converter #(
        .DATA_WIDTH(DATA_WIDTH)
    ) conv_a (
        .din(din_a),
        .dout(din_a_2c)
    );
    
    complement_converter #(
        .DATA_WIDTH(DATA_WIDTH)
    ) conv_b (
        .din(din_b),
        .dout(din_b_2c)
    );
    
    // 实例化RAM存储模块
    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .RAM_DEPTH(RAM_DEPTH)
    ) ram_inst (
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a_2c),
        .din_b(din_b_2c),
        .we_a(we_a),
        .we_b(we_b),
        .dout_a(ram_data_a),
        .dout_b(ram_data_b)
    );
    
    // 实例化输出转换模块
    complement_converter #(
        .DATA_WIDTH(DATA_WIDTH)
    ) out_conv_a (
        .din(ram_data_a),
        .dout(dout_a)
    );
    
    complement_converter #(
        .DATA_WIDTH(DATA_WIDTH)
    ) out_conv_b (
        .din(ram_data_b),
        .dout(dout_b)
    );

endmodule

// 补码转换模块
module complement_converter #(
    parameter DATA_WIDTH = 8
)(
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    always @* begin
        dout = ~din + 1'b1;
    end

endmodule

// RAM核心存储模块
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    input wire we_a, we_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
    
    always @* begin
        if (we_a) ram[addr_a] = din_a;
        if (we_b) ram[addr_b] = din_b;
        dout_a = ram[addr_a];
        dout_b = ram[addr_b];
    end

endmodule