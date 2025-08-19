//SystemVerilog
module SECDED_Decoder_With_Correction (
    input clk,
    input rst,
    
    // Valid-Ready input interface
    input [7:0] received_code,
    input valid_in,
    output reg ready_in,
    
    // Valid-Ready output interface
    output reg [3:0] decoded_data,
    output reg error_flag,
    output reg correct_flag,
    output reg valid_out,
    input ready_out
);
    reg [3:0] syndrome;
    reg [7:0] received_code_reg;
    reg processing;
    
    // 计算校验码
    always @(*) begin
        syndrome[0] = received_code_reg[0] ^ received_code_reg[2] ^ received_code_reg[4] ^ received_code_reg[6];
        syndrome[1] = received_code_reg[1] ^ received_code_reg[2] ^ received_code_reg[5] ^ received_code_reg[6];
        syndrome[2] = received_code_reg[3] ^ received_code_reg[4] ^ received_code_reg[5] ^ received_code_reg[6];
        syndrome[3] = ^received_code_reg;
    end

    // 控制握手信号和数据处理
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            decoded_data <= 4'b0;
            {error_flag, correct_flag} <= 2'b0;
            valid_out <= 1'b0;
            ready_in <= 1'b1;
            processing <= 1'b0;
            received_code_reg <= 8'b0;
        end else begin
            // 输入握手逻辑
            if (valid_in && ready_in) begin
                received_code_reg <= received_code;
                ready_in <= 1'b0;
                processing <= 1'b1;
            end
            
            // 处理数据
            if (processing) begin
                case({syndrome[3], |syndrome[2:0]})
                    2'b00: begin // No error
                        decoded_data <= received_code_reg[7:4];
                        error_flag <= 1'b0;
                        correct_flag <= 1'b0;
                    end
                    2'b01: begin // Correctable error
                        // 根据症状码纠正数据
                        case(syndrome[2:0])
                            3'b001: decoded_data <= {received_code_reg[7:5], ~received_code_reg[4]};
                            3'b010: decoded_data <= {received_code_reg[7:6], ~received_code_reg[5], received_code_reg[4]};
                            3'b011: decoded_data <= {received_code_reg[7], ~received_code_reg[6], received_code_reg[5:4]};
                            3'b100: decoded_data <= {~received_code_reg[7], received_code_reg[6:4]};
                            default: decoded_data <= received_code_reg[7:4];
                        endcase
                        error_flag <= 1'b1;
                        correct_flag <= 1'b1;
                    end
                    default: begin // Uncorrectable error
                        decoded_data <= 4'b0;
                        error_flag <= 1'b1;
                        correct_flag <= 1'b0;
                    end
                endcase
                
                valid_out <= 1'b1;
                processing <= 1'b0;
            end
            
            // 输出握手逻辑
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;
                ready_in <= 1'b1;
            end
        end
    end
endmodule