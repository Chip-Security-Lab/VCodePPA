//SystemVerilog
module sync_quadrupole_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b, we_c, we_d,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, addr_c, addr_d,
    input wire [DATA_WIDTH-1:0] din_a, din_b, din_c, din_d,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b, dout_c, dout_d
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg, addr_c_reg, addr_d_reg;
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b, ram_data_c, ram_data_d;
    
    // LUT-based subtractor signals
    reg [DATA_WIDTH-1:0] lut_sub_a, lut_sub_b, lut_sub_c, lut_sub_d;
    reg [DATA_WIDTH-1:0] lut_result_a, lut_result_b, lut_result_c, lut_result_d;
    
    // LUT for 8-bit subtraction
    reg [DATA_WIDTH-1:0] sub_lut [0:255];
    
    // Initialize LUT
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = (i > 0) ? ~i + 1'b1 : i;
        end
    end

    // Address register buffer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_reg <= 0;
            addr_b_reg <= 0;
            addr_c_reg <= 0;
            addr_d_reg <= 0;
        end else begin
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            addr_c_reg <= addr_c;
            addr_d_reg <= addr_d;
        end
    end

    // RAM write operation
    always @(posedge clk) begin
        if (we_a) ram[addr_a] <= din_a;
        if (we_b) ram[addr_b] <= din_b;
        if (we_c) ram[addr_c] <= din_c;
        if (we_d) ram[addr_d] <= din_d;
    end

    // RAM read operation buffer
    always @(posedge clk) begin
        ram_data_a <= ram[addr_a_reg];
        ram_data_b <= ram[addr_b_reg];
        ram_data_c <= ram[addr_c_reg];
        ram_data_d <= ram[addr_d_reg];
    end
    
    // LUT-based subtractor implementation - Port A
    always @(posedge clk) begin
        lut_sub_a <= ram_data_a;
        lut_result_a <= sub_lut[lut_sub_a];
    end
    
    // LUT-based subtractor implementation - Port B
    always @(posedge clk) begin
        lut_sub_b <= ram_data_b;
        lut_result_b <= sub_lut[lut_sub_b];
    end
    
    // LUT-based subtractor implementation - Port C
    always @(posedge clk) begin
        lut_sub_c <= ram_data_c;
        lut_result_c <= sub_lut[lut_sub_c];
    end
    
    // LUT-based subtractor implementation - Port D
    always @(posedge clk) begin
        lut_sub_d <= ram_data_d;
        lut_result_d <= sub_lut[lut_sub_d];
    end

    // Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            dout_c <= 0;
            dout_d <= 0;
        end else begin
            dout_a <= lut_result_a;
            dout_b <= lut_result_b;
            dout_c <= lut_result_c;
            dout_d <= lut_result_d;
        end
    end

endmodule