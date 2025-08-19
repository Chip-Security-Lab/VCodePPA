//SystemVerilog
module pl_reg_gray #(parameter W=4) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_in,
    input  wire [W-1:0] bin_in,
    output wire         valid_out,
    output wire [W-1:0] gray_out,
    input  wire         ready_next,
    output wire         ready_prev
);
    // Pipeline stage registers
    reg [W-1:0] bin_stage1;
    reg         valid_stage1;
    reg [W-1:0] gray_stage2;
    reg         valid_stage2;
    
    // Optimized ready logic for better timing
    assign ready_prev = ~valid_stage1 | ready_next;
    
    // Optimized stage 1 pipeline registers with priority to reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_stage1   <= '0;
            valid_stage1 <= 1'b0;
        end 
        else if (ready_prev) begin
            bin_stage1   <= bin_in;
            valid_stage1 <= valid_in;
        end
    end
    
    // Efficient Gray code conversion using direct XOR of adjacent bits
    // Reduces critical path by optimizing bit shifting operations
    wire [W-1:0] gray_code;
    assign gray_code = bin_stage1 ^ {1'b0, bin_stage1[W-1:1]};
    
    // Pipeline stage 2 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_stage2  <= '0;
            valid_stage2 <= 1'b0;
        end 
        else if (ready_next) begin
            gray_stage2  <= gray_code;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output assignments
    assign gray_out  = gray_stage2;
    assign valid_out = valid_stage2;
    
endmodule