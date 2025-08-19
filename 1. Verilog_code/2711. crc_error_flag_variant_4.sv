//SystemVerilog
module crc_error_flag (
    input wire clk, 
    input wire rst,
    input wire [15:0] data_in, 
    input wire [15:0] expected_crc,
    output wire error_flag
);
    wire [15:0] current_crc;
    wire valid_stage1, valid_stage2;
    
    crc_calculator crc_calc_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .current_crc(current_crc),
        .valid_out(valid_stage1)
    );
    
    error_detector error_det_inst (
        .clk(clk),
        .rst(rst),
        .current_crc(current_crc),
        .expected_crc(expected_crc),
        .valid_in(valid_stage1),
        .error_flag(error_flag),
        .valid_out(valid_stage2)
    );
endmodule

module crc_calculator (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    output reg [15:0] current_crc,
    output reg valid_out
);
    localparam CRC_POLY = 16'h1021;
    reg [15:0] crc_stage1, crc_stage2;
    reg valid_stage1, valid_stage2;
    
    function [15:0] crc16_update;
        input [15:0] crc, data;
        begin
            crc16_update = {crc[14:0], 1'b0} ^ 
                          ((crc[15] ^ data[15]) ? CRC_POLY : 16'h0000);
        end
    endfunction
    
    always @(posedge clk) begin
        if (rst) begin
            crc_stage1 <= 16'hFFFF;
            valid_stage1 <= 1'b0;
        end else begin
            crc_stage1 <= crc16_update(current_crc, data_in);
            valid_stage1 <= 1'b1;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            crc_stage2 <= 16'hFFFF;
            valid_stage2 <= 1'b0;
        end else begin
            crc_stage2 <= crc_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            current_crc <= 16'hFFFF;
            valid_out <= 1'b0;
        end else begin
            current_crc <= crc_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule

module error_detector (
    input wire clk,
    input wire rst,
    input wire [15:0] current_crc,
    input wire [15:0] expected_crc,
    input wire valid_in,
    output reg error_flag,
    output reg valid_out
);
    reg error_stage1, valid_stage1;
    
    always @(posedge clk) begin
        if (rst) begin
            error_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            error_stage1 <= (current_crc != expected_crc);
            valid_stage1 <= valid_in;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            error_flag <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            error_flag <= error_stage1;
            valid_out <= valid_stage1;
        end
    end
endmodule