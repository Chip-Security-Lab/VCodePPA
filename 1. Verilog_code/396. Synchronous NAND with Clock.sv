module nand2_16 (
    input wire A, B,
    input wire clk,
    output reg Y
);

    always @(posedge clk) begin
        Y <= ~(A & B); // Update output on clock's positive edge
    end
endmodule
