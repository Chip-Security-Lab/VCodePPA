module multi_route_xnor1 (A, B, C, Y);
    input wire A, B, C;
    output wire Y;

    assign Y = ~(A ^ B) & ~(B ^ C) & ~(A ^ C);
endmodule