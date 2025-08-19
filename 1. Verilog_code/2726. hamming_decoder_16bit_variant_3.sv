//SystemVerilog
module hamming_decoder_16bit(
    input clk, rst,
    input [21:0] encoded_data,
    input encoded_valid,
    output encoded_ready,
    output reg [15:0] decoded_data,
    output reg [4:0] error_pos,
    output decoded_valid,
    input decoded_ready
);

    reg [4:0] syndrome;
    reg processing;
    reg output_valid;
    reg encoded_ready_reg;
    
    assign encoded_ready = !processing || (output_valid && decoded_ready);
    assign decoded_valid = output_valid;
    
    always @(posedge clk) begin
        if (rst) begin
            decoded_data <= 16'b0;
            error_pos <= 5'b0;
            processing <= 1'b0;
            output_valid <= 1'b0;
            encoded_ready_reg <= 1'b1;
        end else if (encoded_valid && encoded_ready && !processing) begin
            processing <= 1'b1;
            encoded_ready_reg <= 1'b0;
            syndrome[0] <= ^(encoded_data & 22'b0101_0101_0101_0101_0101_0);
            syndrome[1] <= ^(encoded_data & 22'b0110_0110_0110_0110_0110_0);
            syndrome[2] <= ^(encoded_data & 22'b0111_1000_0111_1000_0111_1);
            syndrome[3] <= ^(encoded_data & 22'b0111_1111_1000_0000_0000_0);
            syndrome[4] <= ^encoded_data;
            decoded_data <= {encoded_data[21:17], encoded_data[15:9], encoded_data[7:4], encoded_data[2]};
            error_pos <= syndrome;
            output_valid <= 1'b1;
        end else if (output_valid && decoded_ready) begin
            output_valid <= 1'b0;
            processing <= 1'b0;
            encoded_ready_reg <= 1'b1;
        end
    end

endmodule