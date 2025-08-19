//SystemVerilog
module gray_signal_recovery (
    input clk,
    input enable,
    input [3:0] gray_in,
    output reg [3:0] binary_out,
    output reg valid
);
    reg [3:0] prev_gray;
    reg [3:0] gray_in_reg;
    reg [1:0] pipeline_decoded_high;
    wire [3:0] decoded;
    
    // First stage of decoding
    assign decoded[3] = gray_in_reg[3];
    assign decoded[2] = decoded[3] ^ gray_in_reg[2];
    
    // Second stage uses pipelined values
    assign decoded[1] = pipeline_decoded_high[1] ^ gray_in_reg[1];
    assign decoded[0] = pipeline_decoded_high[0] ^ gray_in_reg[0];
    
    // Input registration and pipeline stage
    always @(posedge clk) begin
        if (enable) begin
            gray_in_reg <= gray_in;
            pipeline_decoded_high[1] <= decoded[2];
            pipeline_decoded_high[0] <= decoded[1];
        end
    end
    
    // Output and validation stage
    always @(posedge clk) begin
        if (enable) begin
            binary_out <= decoded;
            prev_gray <= gray_in_reg;
            valid <= (prev_gray != gray_in_reg);
        end else begin
            valid <= 1'b0;
        end
    end
endmodule