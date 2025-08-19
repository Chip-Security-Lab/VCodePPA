module async_sawtooth(
    input clock,
    input arst,
    input [7:0] increment,
    output reg [9:0] sawtooth_out
);
    always @(posedge clock or posedge arst) begin
        if (arst)
            sawtooth_out <= 10'h000;
        else
            sawtooth_out <= sawtooth_out + {2'b00, increment};
    end
endmodule