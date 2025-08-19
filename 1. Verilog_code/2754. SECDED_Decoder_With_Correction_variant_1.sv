//SystemVerilog
module SECDED_Decoder_With_Correction (
    input clk,
    input rst,
    input [7:0] received_code,
    output reg [3:0] decoded_data,
    output reg error_flag,
    output reg correct_flag
);
    reg [3:0] syndrome;
    wire parity_check = ^received_code;
    wire [2:0] error_position = {received_code[3] ^ received_code[4] ^ received_code[5] ^ received_code[6],
                                 received_code[1] ^ received_code[2] ^ received_code[5] ^ received_code[6],
                                 received_code[0] ^ received_code[2] ^ received_code[4] ^ received_code[6]};
    wire has_error = |error_position;
    wire single_bit_error = has_error && !parity_check;
    wire [3:0] corrected_data = received_code[7:4] ^ 
                               {error_position == 3'b100, 
                                error_position == 3'b011,
                                error_position == 3'b010,
                                error_position == 3'b001};
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            decoded_data <= 4'b0;
            error_flag <= 1'b0;
            correct_flag <= 1'b0;
        end else begin
            if(!has_error && !parity_check) begin
                // No error
                decoded_data <= received_code[7:4];
                error_flag <= 1'b0;
                correct_flag <= 1'b0;
            end else if(single_bit_error) begin
                // Correctable error (single bit error)
                decoded_data <= corrected_data;
                error_flag <= 1'b1;
                correct_flag <= 1'b1;
            end else begin
                // Uncorrectable error
                decoded_data <= 4'b0;
                error_flag <= 1'b1;
                correct_flag <= 1'b0;
            end
        end
    end
endmodule