module SECDED_Decoder_With_Correction (
    input clk,
    input rst,
    input [7:0] received_code,
    output reg [3:0] decoded_data,
    output reg error_flag,
    output reg correct_flag
);
    reg [3:0] syndrome;
    
    // 将组合逻辑移到always块中并添加敏感信号列表
    always @(received_code) begin
        syndrome[0] = received_code[0] ^ received_code[2] ^ received_code[4] ^ received_code[6];
        syndrome[1] = received_code[1] ^ received_code[2] ^ received_code[5] ^ received_code[6];
        syndrome[2] = received_code[3] ^ received_code[4] ^ received_code[5] ^ received_code[6];
        syndrome[3] = ^received_code;
    end

    // 简化错误位置逻辑，避免负数问题
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            decoded_data <= 4'b0;
            {error_flag, correct_flag} <= 2'b0;
        end else begin
            case({syndrome[3], |syndrome[2:0]})
                2'b00: begin // No error
                    decoded_data <= received_code[7:4];
                    error_flag <= 0;
                    correct_flag <= 0;
                end
                2'b01: begin // Correctable error
                    // 根据症状码纠正数据
                    case(syndrome[2:0])
                        3'b001: decoded_data <= {received_code[7:5], ~received_code[4]};
                        3'b010: decoded_data <= {received_code[7:6], ~received_code[5], received_code[4]};
                        3'b011: decoded_data <= {received_code[7], ~received_code[6], received_code[5:4]};
                        3'b100: decoded_data <= {~received_code[7], received_code[6:4]};
                        default: decoded_data <= received_code[7:4];
                    endcase
                    error_flag <= 1;
                    correct_flag <= 1;
                end
                default: begin // Uncorrectable error
                    decoded_data <= 4'b0;
                    error_flag <= 1;
                    correct_flag <= 0;
                end
            endcase
        end
    end
endmodule