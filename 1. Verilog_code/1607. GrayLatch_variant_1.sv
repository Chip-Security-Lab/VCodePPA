//SystemVerilog
module GrayLatch #(parameter DW=4) (
    input wire clk,
    input wire en,
    input wire [DW-1:0] bin_in,
    output reg [DW-1:0] gray_out
);

    // Pipeline stage 1: Input register
    reg [DW-1:0] bin_reg;
    
    // Pipeline stage 2: Gray conversion with barrel shifter
    wire [DW-1:0] gray_comb;
    wire [DW-1:0] shifted_bin;
    
    // Barrel shifter implementation
    genvar i;
    generate
        for (i = 0; i < DW; i = i + 1) begin : barrel_shift
            assign shifted_bin[i] = (i == 0) ? 1'b0 : bin_reg[i-1];
        end
    endgenerate
    
    assign gray_comb = bin_reg ^ shifted_bin;

    // Main pipeline control
    always @(posedge clk) begin
        if (en) begin
            bin_reg <= bin_in;
            gray_out <= gray_comb;
        end
    end

endmodule