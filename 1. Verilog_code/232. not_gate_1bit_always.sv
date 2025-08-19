module not_gate_1bit_always (
    input wire A,
    output reg Y
);
    always @ (A) begin
        Y = ~A;
    end
endmodule