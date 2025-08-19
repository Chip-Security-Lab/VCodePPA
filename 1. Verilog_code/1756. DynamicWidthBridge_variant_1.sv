//SystemVerilog
module DynamicWidthBridge #(
    parameter IN_W = 32,
    parameter OUT_W = 64
)(
    input clk, rst_n,
    input [IN_W-1:0] data_in,
    input in_valid,
    output [OUT_W-1:0] data_out,
    output out_valid
);
    localparam RATIO = OUT_W / IN_W;
    reg [OUT_W-1:0] shift_reg;
    reg [3:0] count;
    
    // Optimized implementation using direct subtraction
    wire [IN_W:0] sub_extended;
    
    assign sub_extended = {1'b0, shift_reg[IN_W-1:0]} - {1'b0, data_in};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= '0;
            count <= '0;
        end else if (in_valid) begin
            // Use efficient shift and direct subtraction for better timing
            shift_reg <= {shift_reg[OUT_W-IN_W-1:0], sub_extended[IN_W-1:0]};
            count <= (count == RATIO-1) ? '0 : count + 1'b1;
        end
    end

    assign data_out = shift_reg;
    assign out_valid = (count == RATIO-1) & in_valid;
endmodule