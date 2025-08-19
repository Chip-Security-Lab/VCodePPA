//SystemVerilog
module param_hamming_encoder #(
    parameter DATA_WIDTH = 4
)(
    input clk, enable,
    input [DATA_WIDTH-1:0] data,
    output reg [(DATA_WIDTH+4):0] encoded,
    output reg valid_out
);
    reg [DATA_WIDTH-1:0] data_stage1;
    reg [3:0] parity_bits_stage1;
    reg valid_stage1;
    
    reg [DATA_WIDTH-1:0] data_stage2;
    reg [3:0] parity_bits_stage2;
    reg valid_stage2;
    
    // 桶形移位器实现
    wire [DATA_WIDTH+4:0] barrel_shifted;
    reg [2:0] shift_amount;
    
    // 计算移位量
    always @(*) begin
        case (data_stage2)
            4'b0000: shift_amount = 3'd0;
            4'b0001: shift_amount = 3'd1;
            4'b0010: shift_amount = 3'd2;
            4'b0011: shift_amount = 3'd3;
            4'b0100: shift_amount = 3'd4;
            4'b0101: shift_amount = 3'd5;
            4'b0110: shift_amount = 3'd6;
            4'b0111: shift_amount = 3'd7;
            default: shift_amount = 3'd0;
        endcase
    end
    
    // 桶形移位器核心逻辑
    assign barrel_shifted = {parity_bits_stage2, data_stage2} << shift_amount;
    
    // 流水线阶段1
    always @(posedge clk) begin
        if (!enable) begin
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data;
            parity_bits_stage1[0] <= ^(data & 4'b0101);
            parity_bits_stage1[1] <= ^(data & 4'b0110);
            parity_bits_stage1[2] <= ^(data & 4'b1100);
            parity_bits_stage1[3] <= ^data;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 流水线阶段2
    always @(posedge clk) begin
        data_stage2 <= data_stage1;
        parity_bits_stage2 <= parity_bits_stage1;
        valid_stage2 <= valid_stage1;
    end
    
    // 流水线阶段3
    always @(posedge clk) begin
        if (valid_stage2) begin
            encoded <= barrel_shifted;
        end
        valid_out <= valid_stage2;
    end
endmodule