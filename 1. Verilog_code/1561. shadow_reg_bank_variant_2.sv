//SystemVerilog
module shadow_reg_bank #(parameter DW=8, AW=4) (
    input clk, we,
    input [AW-1:0] addr,
    input [DW-1:0] wdata,
    output [DW-1:0] rdata
);
    reg [DW-1:0] shadow_mem [2**AW-1:0];
    reg [DW-1:0] output_reg;
    
    // Parallel Prefix Subtractor
    wire [DW-1:0] a, b, s;
    wire [DW:0] carry;

    assign a = shadow_mem[addr];
    assign b = wdata;

    // Generate carries and sums
    assign carry[0] = 0; // Initial carry
    genvar i;
    generate
        for (i = 0; i < DW; i = i + 1) begin : prefix
            assign carry[i + 1] = (a[i] < b[i]) ? 1'b1 : 1'b0; // Use 1'b1 for clarity
            assign s[i] = a[i] ^ b[i] ^ carry[i];
        end
    endgenerate

    always @(posedge clk) begin
        if (we) begin
            shadow_mem[addr] <= wdata;
        end
        output_reg <= s; // Store the result of the subtraction
    end
    assign rdata = output_reg;
endmodule