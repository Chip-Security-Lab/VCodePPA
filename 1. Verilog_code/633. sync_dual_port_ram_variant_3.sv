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

    // Memory array declaration
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] lut_sub [255:0];
    
    // Internal signals
    reg [DATA_WIDTH-1:0] sub_result_a, sub_result_b;
    reg [DATA_WIDTH-1:0] lut_addr_a, lut_addr_b;

    // LUT initialization
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut_sub[i] = i;
        end
    end

    // Port A LUT address generation
    always @(*) begin
        lut_addr_a = din_a;
    end

    // Port B LUT address generation
    always @(*) begin
        lut_addr_b = din_b;
    end

    // Port A LUT subtraction and write
    always @(posedge clk) begin
        if (we_a) begin
            sub_result_a <= lut_sub[lut_addr_a];
            ram[addr_a] <= sub_result_a;
        end
    end

    // Port B LUT subtraction and write
    always @(posedge clk) begin
        if (we_b) begin
            sub_result_b <= lut_sub[lut_addr_b];
            ram[addr_b] <= sub_result_b;
        end
    end

    // Port A read operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
        end else begin
            dout_a <= ram[addr_a];
        end
    end

    // Port B read operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_b <= 0;
        end else begin
            dout_b <= ram[addr_b];
        end
    end

endmodule