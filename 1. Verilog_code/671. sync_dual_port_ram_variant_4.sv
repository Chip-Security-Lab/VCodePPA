//SystemVerilog
module sync_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_a_data, ram_b_data;
    
    // LUT for 8-bit subtraction
    reg [DATA_WIDTH-1:0] sub_lut [0:255];
    reg [DATA_WIDTH-1:0] sub_result_a, sub_result_b;
    
    // Initialize LUT
    integer i;
    initial begin
        for(i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = i;
        end
    end

    // RAM data read and buffer
    always @(posedge clk) begin
        ram_a_data <= ram[addr_a];
        ram_b_data <= ram[addr_b];
    end

    // Subtraction using LUT
    always @(posedge clk) begin
        sub_result_a <= sub_lut[ram_a_data] - din_a;
        sub_result_b <= sub_lut[ram_b_data] - din_b;
    end

    // Port A write logic
    always @(posedge clk) begin
        if (we_a) begin
            ram[addr_a] <= sub_result_a;
        end
    end

    // Port B write logic
    always @(posedge clk) begin
        if (we_b) begin
            ram[addr_b] <= sub_result_b;
        end
    end

    // Port A read logic
    always @(posedge clk) begin
        dout_a <= ram[addr_a];
    end

    // Port B read logic
    always @(posedge clk) begin
        dout_b <= ram[addr_b];
    end

    // Reset logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            ram_a_data <= 0;
            ram_b_data <= 0;
            sub_result_a <= 0;
            sub_result_b <= 0;
        end
    end
endmodule