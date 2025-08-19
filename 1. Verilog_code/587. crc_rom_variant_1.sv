//SystemVerilog
module crc_rom (
    input clk,
    input rst_n,
    input [3:0] addr,
    output reg [7:0] data,
    output reg crc_error
);
    reg [7:0] rom [0:15];
    reg [3:0] crc [0:15];
    
    // Pipeline registers
    reg [3:0] addr_stage1;
    reg [7:0] rom_data_stage1;
    reg [3:0] crc_value_stage1;
    
    reg [7:0] rom_data_stage2;
    reg [3:0] crc_value_stage2;
    reg [7:0] data_stage2;
    
    reg [7:0] data_stage3;
    reg crc_error_stage3;

    // Carry lookahead adder signals
    wire [7:0] sum;
    wire [8:0] carry;
    wire [7:0] p, g;
    
    // Initialize ROM
    initial begin
        rom[0] = 8'h99; crc[0] = 4'hF;
        for (integer i = 1; i < 16; i = i + 1) begin
            rom[i] = 8'h00;
            crc[i] = 4'h0;
        end
    end
    
    // Carry lookahead adder implementation
    assign p = rom_data_stage2 ^ {4'h0, crc_value_stage2};
    assign g = rom_data_stage2 & {4'h0, crc_value_stage2};
    
    assign carry[0] = 1'b0;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & carry[0]);
    assign carry[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & carry[0]);
    assign carry[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & carry[0]);
    assign carry[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]);
    assign carry[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]);
    assign carry[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]);
    assign carry[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]);
    
    assign sum = p ^ carry[7:0];
    
    // Stage 1: Address and ROM access
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'h0;
            rom_data_stage1 <= 8'h00;
            crc_value_stage1 <= 4'h0;
        end else begin
            addr_stage1 <= addr;
            rom_data_stage1 <= rom[addr];
            crc_value_stage1 <= crc[addr];
        end
    end
    
    // Stage 2: Data preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_stage2 <= 8'h00;
            crc_value_stage2 <= 4'h0;
            data_stage2 <= 8'h00;
        end else begin
            rom_data_stage2 <= rom_data_stage1;
            crc_value_stage2 <= crc_value_stage1;
            data_stage2 <= rom_data_stage1;
        end
    end
    
    // Stage 3: CRC calculation and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 8'h00;
            crc_error_stage3 <= 1'b0;
        end else begin
            data_stage3 <= data_stage2;
            crc_error_stage3 <= (^sum) != 1'b0;
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'h00;
            crc_error <= 1'b0;
        end else begin
            data <= data_stage3;
            crc_error <= crc_error_stage3;
        end
    end
endmodule