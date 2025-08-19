module parity_gen #(parameter TYPE=0) ( // 0: Even, 1: Odd
    input [7:0] data,
    output parity
);
    assign parity = (^data) ^ TYPE;
endmodule