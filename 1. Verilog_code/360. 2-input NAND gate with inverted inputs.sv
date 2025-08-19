module nand2_4 (input wire A, input wire B, output wire Y);
    assign Y = ~((~A) & (~B));  // Inverting inputs before NAND operation
endmodule