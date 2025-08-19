//SystemVerilog
// RAM memory core module
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire we,
    output reg [DATA_WIDTH-1:0] dout
);
    reg [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];
    
    always @(posedge clk) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];
    end
endmodule

// Pipeline register module
module pipeline_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    always @(posedge clk or posedge rst) begin
        if (rst) dout <= 0;
        else dout <= din;
    end
endmodule

// Top-level quadrupole RAM module
module sync_quadrupole_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b, we_c, we_d,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, addr_c, addr_d,
    input wire [DATA_WIDTH-1:0] din_a, din_b, din_c, din_d,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b, dout_c, dout_d
);

    // Stage 1 pipeline registers
    wire [ADDR_WIDTH-1:0] addr_a_s1, addr_b_s1, addr_c_s1, addr_d_s1;
    wire [DATA_WIDTH-1:0] din_a_s1, din_b_s1, din_c_s1, din_d_s1;
    wire we_a_s1, we_b_s1, we_c_s1, we_d_s1;

    // Stage 2 pipeline registers
    wire [DATA_WIDTH-1:0] ram_data_a_s2, ram_data_b_s2, ram_data_c_s2, ram_data_d_s2;

    // Instantiate pipeline registers for address
    pipeline_reg #(ADDR_WIDTH) addr_reg_a (.clk(clk), .rst(rst), .din(addr_a), .dout(addr_a_s1));
    pipeline_reg #(ADDR_WIDTH) addr_reg_b (.clk(clk), .rst(rst), .din(addr_b), .dout(addr_b_s1));
    pipeline_reg #(ADDR_WIDTH) addr_reg_c (.clk(clk), .rst(rst), .din(addr_c), .dout(addr_c_s1));
    pipeline_reg #(ADDR_WIDTH) addr_reg_d (.clk(clk), .rst(rst), .din(addr_d), .dout(addr_d_s1));

    // Instantiate pipeline registers for data in
    pipeline_reg #(DATA_WIDTH) din_reg_a (.clk(clk), .rst(rst), .din(din_a), .dout(din_a_s1));
    pipeline_reg #(DATA_WIDTH) din_reg_b (.clk(clk), .rst(rst), .din(din_b), .dout(din_b_s1));
    pipeline_reg #(DATA_WIDTH) din_reg_c (.clk(clk), .rst(rst), .din(din_c), .dout(din_c_s1));
    pipeline_reg #(DATA_WIDTH) din_reg_d (.clk(clk), .rst(rst), .din(din_d), .dout(din_d_s1));

    // Instantiate pipeline registers for write enable
    pipeline_reg #(1) we_reg_a (.clk(clk), .rst(rst), .din(we_a), .dout(we_a_s1));
    pipeline_reg #(1) we_reg_b (.clk(clk), .rst(rst), .din(we_b), .dout(we_b_s1));
    pipeline_reg #(1) we_reg_c (.clk(clk), .rst(rst), .din(we_c), .dout(we_c_s1));
    pipeline_reg #(1) we_reg_d (.clk(clk), .rst(rst), .din(we_d), .dout(we_d_s1));

    // Instantiate RAM cores
    ram_core #(DATA_WIDTH, ADDR_WIDTH) ram_a (
        .clk(clk),
        .addr(addr_a_s1),
        .din(din_a_s1),
        .we(we_a_s1),
        .dout(ram_data_a_s2)
    );

    ram_core #(DATA_WIDTH, ADDR_WIDTH) ram_b (
        .clk(clk),
        .addr(addr_b_s1),
        .din(din_b_s1),
        .we(we_b_s1),
        .dout(ram_data_b_s2)
    );

    ram_core #(DATA_WIDTH, ADDR_WIDTH) ram_c (
        .clk(clk),
        .addr(addr_c_s1),
        .din(din_c_s1),
        .we(we_c_s1),
        .dout(ram_data_c_s2)
    );

    ram_core #(DATA_WIDTH, ADDR_WIDTH) ram_d (
        .clk(clk),
        .addr(addr_d_s1),
        .din(din_d_s1),
        .we(we_d_s1),
        .dout(ram_data_d_s2)
    );

    // Instantiate output pipeline registers
    pipeline_reg #(DATA_WIDTH) dout_reg_a (.clk(clk), .rst(rst), .din(ram_data_a_s2), .dout(dout_a));
    pipeline_reg #(DATA_WIDTH) dout_reg_b (.clk(clk), .rst(rst), .din(ram_data_b_s2), .dout(dout_b));
    pipeline_reg #(DATA_WIDTH) dout_reg_c (.clk(clk), .rst(rst), .din(ram_data_c_s2), .dout(dout_c));
    pipeline_reg #(DATA_WIDTH) dout_reg_d (.clk(clk), .rst(rst), .din(ram_data_d_s2), .dout(dout_d));

endmodule