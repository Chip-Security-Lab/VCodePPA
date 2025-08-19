//SystemVerilog
module SoftClipper #(parameter W=8, THRESH=8'hF0) (
    input [W-1:0] din,
    output reg [W-1:0] dout
);

    wire [W-1:0] din_abs;
    wire din_sign;
    wire [W-1:0] diff;
    wire [W-1:0] diff_shifted;
    wire [W-1:0] result;
    
    // Get absolute value and sign
    assign din_sign = din[W-1];
    assign din_abs = din_sign ? -din : din;
    
    // Calculate difference using conditional inversion
    assign diff = din_abs > THRESH ? din_abs - THRESH : THRESH - din_abs;
    assign diff_shifted = diff >> 1;
    
    // Calculate final result
    assign result = din_abs > THRESH ? 
                   (din_sign ? -THRESH - diff_shifted : THRESH + diff_shifted) :
                   din;

    always @(*) begin
        dout = result;
    end

endmodule