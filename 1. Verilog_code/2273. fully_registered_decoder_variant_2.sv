//SystemVerilog
module fully_registered_decoder(
    input clk,
    input rst,
    input [2:0] addr_in,
    output reg [7:0] decode_out
);
    // Intermediate signals for direct decode
    wire [7:0] decoded_value;
    
    // Directly decode without first stage register
    assign decoded_value = (8'b00000001 << addr_in);
    
    // Stage 1: Register decoded value instead of input
    reg [7:0] decode_stage1;
    
    always @(posedge clk) begin
        if (rst) begin
            decode_stage1 <= 8'b00000000;
        end else begin
            decode_stage1 <= decoded_value;
        end
    end
    
    // Stage 2: Final output registration
    always @(posedge clk) begin
        if (rst) begin
            decode_out <= 8'b00000000;
        end else begin
            decode_out <= decode_stage1;
        end
    end
endmodule