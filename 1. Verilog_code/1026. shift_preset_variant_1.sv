//SystemVerilog
module shift_preset #(parameter W=8) (
    input wire clk,
    input wire preset,
    input wire [W-1:0] preset_val,
    output reg [W-1:0] dout
);

wire [W-1:0] next_dout;

// Efficient decrement with range check and optimized concatenation
assign next_dout = (dout[W-1:1] == { (W-1){1'b0} }) ?
                   { {W-1{1'b0}}, 1'b1 } :
                   { dout[W-2:0], 1'b1 };

always @(posedge clk) begin
    if (preset)
        dout <= preset_val;
    else
        dout <= next_dout;
end

endmodule