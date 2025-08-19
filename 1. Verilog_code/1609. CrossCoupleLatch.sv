module CrossCoupleLatch (
    input set, reset,
    output reg q, qn
);
always @* begin
    case({set, reset})
        2'b10: {q, qn} = 2'b10;
        2'b01: {q, qn} = 2'b01;
        2'b11: {q, qn} = 2'b11;
    endcase
end
endmodule