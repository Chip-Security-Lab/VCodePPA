//SystemVerilog
module SECDED_Decoder_With_Correction (
    input clk,
    input rst,
    input [7:0] received_code,
    input data_valid_in,
    output reg [3:0] decoded_data,
    output reg error_flag,
    output reg correct_flag,
    output reg data_valid_out
);
    // Stage 1 - Syndrome calculation
    reg [7:0] received_code_stage1;
    reg [3:0] syndrome_stage1;
    reg data_valid_stage1;
    
    // Stage 2 - Correction logic
    reg [7:0] received_code_stage2;
    reg [3:0] syndrome_stage2;
    reg data_valid_stage2;
    
    // Stage 1: Compute syndrome
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            received_code_stage1 <= 8'b0;
            syndrome_stage1 <= 4'b0;
            data_valid_stage1 <= 1'b0;
        end else begin
            received_code_stage1 <= received_code;
            
            // Syndrome calculation
            syndrome_stage1[0] <= received_code[0] ^ received_code[2] ^ received_code[4] ^ received_code[6];
            syndrome_stage1[1] <= received_code[1] ^ received_code[2] ^ received_code[5] ^ received_code[6];
            syndrome_stage1[2] <= received_code[3] ^ received_code[4] ^ received_code[5] ^ received_code[6];
            syndrome_stage1[3] <= ^received_code;
            
            data_valid_stage1 <= data_valid_in;
        end
    end
    
    // Stage 2: Store syndrome and received code for error correction
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            received_code_stage2 <= 8'b0;
            syndrome_stage2 <= 4'b0;
            data_valid_stage2 <= 1'b0;
        end else begin
            received_code_stage2 <= received_code_stage1;
            syndrome_stage2 <= syndrome_stage1;
            data_valid_stage2 <= data_valid_stage1;
        end
    end
    
    // Stage 3: Error correction and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            decoded_data <= 4'b0;
            error_flag <= 1'b0;
            correct_flag <= 1'b0;
            data_valid_out <= 1'b0;
        end else begin
            data_valid_out <= data_valid_stage2;
            
            case({syndrome_stage2[3], |syndrome_stage2[2:0]})
                2'b00: begin // No error
                    decoded_data <= received_code_stage2[7:4];
                    error_flag <= 1'b0;
                    correct_flag <= 1'b0;
                end
                2'b01: begin // Correctable error
                    // 根据症状码纠正数据
                    case(syndrome_stage2[2:0])
                        3'b001: decoded_data <= {received_code_stage2[7:5], ~received_code_stage2[4]};
                        3'b010: decoded_data <= {received_code_stage2[7:6], ~received_code_stage2[5], received_code_stage2[4]};
                        3'b011: decoded_data <= {received_code_stage2[7], ~received_code_stage2[6], received_code_stage2[5:4]};
                        3'b100: decoded_data <= {~received_code_stage2[7], received_code_stage2[6:4]};
                        default: decoded_data <= received_code_stage2[7:4];
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
        end
    end
endmodule