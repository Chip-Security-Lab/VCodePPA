//SystemVerilog
module FastDiv(
    input [15:0] a,
    input [15:0] b,
    output reg [15:0] q,
    output reg valid,
    input ready
);
    reg [31:0] inv_b;
    
    always @(posedge ready) begin
        inv_b <= (b != 0) ? (32'hFFFF_FFFF / b) : 0;
        valid <= (b != 0) ? 1'b1 : 1'b0; // Set valid based on b
    end

    always @(posedge valid) begin
        q <= (inv_b * a) >> 16;
    end

endmodule