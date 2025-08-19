module twos_complement_8bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  in,
    output reg  [7:0]  out
);

    // Single pipeline stage with optimized logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out <= 8'b0;
        else
            out <= (~in) + 1'b1;
    end

endmodule

module subtractor_8bit_negative (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output reg  [7:0]  diff
);

    // Single pipeline stage with optimized subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            diff <= 8'b0;
        else
            diff <= a - b;
    end

endmodule