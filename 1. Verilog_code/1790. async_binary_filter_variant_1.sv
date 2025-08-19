//SystemVerilog
module async_binary_filter #(
    parameter W = 8
)(
    input [W-1:0] analog_in,
    input [W-1:0] threshold,
    output reg binary_out
);
    wire [W-1:0] diff;
    wire borrow;
    
    // Conditional inversion subtractor
    assign {borrow, diff} = analog_in + (~threshold + 1'b1);
    
    always @(*) begin
        binary_out = ~borrow;
    end
endmodule