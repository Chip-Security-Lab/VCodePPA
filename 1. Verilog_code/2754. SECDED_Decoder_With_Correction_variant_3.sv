//SystemVerilog
module SECDED_Decoder_With_Correction (
    input clk,
    input rst,
    input [7:0] received_code,
    output reg [3:0] decoded_data,
    output reg error_flag,
    output reg correct_flag
);
    // 提前计算一些常用逻辑，减少关键路径
    reg [2:0] syndrome_lower;
    reg syndrome_parity;
    reg syndrome_valid;
    reg [3:0] corrected_data;
    
    // 将组合逻辑分解为更小的并行计算单元
    always @(*) begin
        // 并行计算校验位，减少逻辑深度
        syndrome_lower[0] = received_code[0] ^ received_code[2] ^ received_code[4] ^ received_code[6];
        syndrome_lower[1] = received_code[1] ^ received_code[2] ^ received_code[5] ^ received_code[6];
        syndrome_lower[2] = received_code[3] ^ received_code[4] ^ received_code[5] ^ received_code[6];
        
        // 计算奇偶校验
        syndrome_parity = ^received_code;
        
        // 预先计算症状码是否有效（非零）
        syndrome_valid = |syndrome_lower;
        
        // 预先计算纠正后的数据，减少关键路径
        case(syndrome_lower)
            3'b001: corrected_data = {received_code[7:5], ~received_code[4]};
            3'b010: corrected_data = {received_code[7:6], ~received_code[5], received_code[4]};
            3'b011: corrected_data = {received_code[7], ~received_code[6], received_code[5:4]};
            3'b100: corrected_data = {~received_code[7], received_code[6:4]};
            default: corrected_data = received_code[7:4];
        endcase
    end

    // 时序逻辑，使用预计算的值
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            decoded_data <= 4'b0;
            error_flag <= 1'b0;
            correct_flag <= 1'b0;
        end else begin
            case({syndrome_parity, syndrome_valid})
                2'b00: begin // 无错误
                    decoded_data <= received_code[7:4];
                    error_flag <= 1'b0;
                    correct_flag <= 1'b0;
                end
                2'b01: begin // 可纠正错误
                    // 直接使用预计算的纠正数据
                    decoded_data <= corrected_data;
                    error_flag <= 1'b1;
                    correct_flag <= 1'b1;
                end
                default: begin // 不可纠正错误
                    decoded_data <= 4'b0;
                    error_flag <= 1'b1;
                    correct_flag <= 1'b0;
                end
            endcase
        end
    end
endmodule