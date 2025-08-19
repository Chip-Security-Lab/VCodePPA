//SystemVerilog
module gray_div #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire rst,
    output reg  clk_div
);
    // Gray counter registers
    reg [WIDTH-1:0] gray_cnt_r;
    reg [WIDTH-1:0] bin_cnt_r;
    
    // Pipeline stages for improved timing
    reg bin_cnt_max_stage1;
    
    // Binary to Gray conversion logic
    wire [WIDTH-1:0] next_gray_cnt = gray_cnt_r + 1'b1;
    
    // Gray to Binary conversion - staged for better timing
    wire [WIDTH-1:0] bin_cnt_comb = gray_cnt_r ^ (gray_cnt_r >> 1);
    
    // Maximum binary count detection
    wire bin_cnt_max = (bin_cnt_r == {WIDTH{1'b1}});
    
    // Counter and data path update logic
    always @(posedge clk) begin
        if (rst) begin
            // Reset all registers
            gray_cnt_r <= {WIDTH{1'b0}};
            bin_cnt_r <= {WIDTH{1'b0}};
            bin_cnt_max_stage1 <= 1'b0;
            clk_div <= 1'b0;
        end
        else begin
            // Stage 1: Update gray counter and convert to binary
            gray_cnt_r <= next_gray_cnt;
            bin_cnt_r <= bin_cnt_comb;
            
            // Stage 2: Detect maximum count
            bin_cnt_max_stage1 <= bin_cnt_max;
            
            // Stage 3: Update output
            clk_div <= bin_cnt_max_stage1;
        end
    end
endmodule