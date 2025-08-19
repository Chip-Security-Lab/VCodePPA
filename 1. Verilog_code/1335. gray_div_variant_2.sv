//SystemVerilog
module gray_div #(parameter WIDTH=4) (
    input clk, rst,
    output reg clk_div
);
    // Pipeline stage 1 registers
    reg [WIDTH-1:0] gray_cnt_stage1;
    reg [WIDTH-1:0] bin_cnt_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0] bin_cnt_plus1_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [WIDTH-1:0] gray_cnt_next_stage3;
    reg max_value_detected_stage3;
    reg valid_stage3;
    
    // Combinational logic for each stage
    wire [WIDTH-1:0] bin_cnt;
    wire [WIDTH-1:0] bin_cnt_plus1;
    wire [WIDTH-1:0] gray_cnt_next;
    wire max_value_detected;
    
    // Stage 1: Binary to Gray conversion
    assign bin_cnt = gray_cnt_stage1 ^ (gray_cnt_stage1 >> 1);
    
    // Stage 2: Binary increment
    assign bin_cnt_plus1 = bin_cnt_stage1 + 1'b1;
    
    // Stage 3: Gray code conversion and maximum value detection
    assign gray_cnt_next = bin_cnt_plus1_stage2 ^ (bin_cnt_plus1_stage2 >> 1);
    assign max_value_detected = &bin_cnt_plus1_stage2; // AND reduction operator
    
    // Pipeline control
    always @(posedge clk) begin
        if (rst) begin
            // Reset all pipeline stages
            gray_cnt_stage1 <= {WIDTH{1'b0}};
            bin_cnt_stage1 <= {WIDTH{1'b0}};
            bin_cnt_plus1_stage2 <= {WIDTH{1'b0}};
            gray_cnt_next_stage3 <= {WIDTH{1'b0}};
            max_value_detected_stage3 <= 1'b0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            clk_div <= 1'b0;
        end 
        else begin
            // Stage 1: Store current gray_cnt and enable
            valid_stage1 <= 1'b1;
            bin_cnt_stage1 <= bin_cnt;
            
            // Stage 2: Store incremented binary count
            valid_stage2 <= valid_stage1;
            bin_cnt_plus1_stage2 <= bin_cnt_plus1;
            
            // Stage 3: Store next gray code and max detection
            valid_stage3 <= valid_stage2;
            gray_cnt_next_stage3 <= gray_cnt_next;
            max_value_detected_stage3 <= max_value_detected;
            
            // Output stage: Update counter and output
            if (valid_stage3) begin
                gray_cnt_stage1 <= gray_cnt_next_stage3;
                clk_div <= max_value_detected_stage3;
            end
        end
    end
endmodule