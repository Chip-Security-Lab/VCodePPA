module sawtooth_generator(
    input clock,
    input areset,
    input en,
    output reg [7:0] sawtooth
);
    always @(posedge clock or posedge areset) begin
        if (areset)
            sawtooth <= 8'h00;
        else if (en)
            sawtooth <= sawtooth + 8'h01;
    end
endmodule