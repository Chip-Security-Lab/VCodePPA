module MixedLogicNOT(
    input a,
    output y1,
    output reg y2
);
    assign y1 = ~a;     // Dataflow implementation
    
    always @(*) begin
        y2 = ~a;        // Procedural block implementation
    end
endmodule