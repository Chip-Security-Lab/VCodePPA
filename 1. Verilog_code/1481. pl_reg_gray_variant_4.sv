//SystemVerilog
module pl_reg_gray #(parameter W=8) (
    input clk, en,
    input [W-1:0] bin_in,
    output reg [W-1:0] gray_out
);
    // Register input data
    reg [W-1:0] bin_reg;
    
    // Combinational logic signals
    wire [W-1:0] borrow;
    wire [W-1:0] difference;
    
    // Register the input first
    always @(posedge clk) begin
        if (en) begin
            bin_reg <= bin_in;
        end
    end
    
    // Initial borrow bit
    assign borrow[0] = 1'b0;
    assign difference[0] = bin_reg[0] ^ borrow[0];
    
    // Generate borrow and difference using combinational logic
    genvar i;
    generate
        for (i = 1; i < W; i = i + 1) begin : gen_borrow_diff
            assign borrow[i] = (~bin_reg[i-1]) & borrow[i-1] | 
                               (~bin_reg[i-1]) & bin_reg[i] | 
                               bin_reg[i] & borrow[i-1];
            assign difference[i] = bin_reg[i] ^ bin_reg[i-1] ^ borrow[i-1];
        end
    endgenerate
    
    // Register the output
    always @(posedge clk) begin
        if (en) begin
            gray_out <= difference;
        end
    end
endmodule