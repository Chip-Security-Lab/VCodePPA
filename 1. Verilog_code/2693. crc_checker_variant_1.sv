//SystemVerilog
// CRC计算子模块
module crc_calculator(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [7:0] calculated_crc
);
    parameter [7:0] POLY = 8'hD5;
    
    wire xor_bit = calculated_crc[7] ^ data_in[0];
    wire [7:0] next_crc_base = {calculated_crc[6:0], 1'b0};
    wire [7:0] next_crc_xor = next_crc_base ^ POLY;
    wire [7:0] next_crc = xor_bit ? next_crc_xor : next_crc_base;
    
    always @(posedge clk) begin
        if (rst) begin
            calculated_crc <= 8'h00;
        end else if (data_valid) begin
            calculated_crc <= next_crc;
        end
    end
endmodule

// CRC校验子模块
module crc_validator(
    input wire clk,
    input wire rst,
    input wire [7:0] calculated_crc,
    input wire [7:0] crc_in,
    input wire data_valid,
    output reg crc_valid
);
    wire crc_match = (calculated_crc == crc_in);
    
    always @(posedge clk) begin
        if (rst) begin
            crc_valid <= 1'b0;
        end else if (data_valid) begin
            crc_valid <= crc_match;
        end
    end
endmodule

// 顶层CRC检查器模块
module crc_checker(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire [7:0] crc_in,
    input wire data_valid,
    output wire crc_valid,
    output wire [7:0] calculated_crc
);
    wire [7:0] internal_crc;
    
    crc_calculator calc_inst(
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .data_valid(data_valid),
        .calculated_crc(internal_crc)
    );
    
    crc_validator valid_inst(
        .clk(clk),
        .rst(rst),
        .calculated_crc(internal_crc),
        .crc_in(crc_in),
        .data_valid(data_valid),
        .crc_valid(crc_valid)
    );
    
    assign calculated_crc = internal_crc;
endmodule