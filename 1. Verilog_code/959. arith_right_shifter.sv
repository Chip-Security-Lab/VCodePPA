module arith_right_shifter (
    input CLK, RST_n,
    input [15:0] DATA_IN,
    input SHIFT,
    output reg [15:0] DATA_OUT
);
    always @(posedge CLK) begin
        if (!RST_n)
            DATA_OUT <= 16'h0000;
        else if (SHIFT)
            DATA_OUT <= {DATA_OUT[15], DATA_OUT[15:1]};  // Sign extension
        else
            DATA_OUT <= DATA_IN;
    end
endmodule