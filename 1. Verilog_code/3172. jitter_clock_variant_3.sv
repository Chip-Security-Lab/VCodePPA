//SystemVerilog
module jitter_clock(
    input clk_in,
    input rst,
    input [2:0] jitter_amount,
    input jitter_en,
    output reg clk_out
);
    // Stage 1 - Jitter calculation
    reg [4:0] counter_stage1;
    reg [2:0] jitter_stage1;
    reg jitter_en_stage1;
    reg [2:0] jitter_amount_stage1;
    reg valid_stage1;
    
    // Stage 2 - Counter update and clock generation
    reg [4:0] counter_stage2;
    reg [2:0] jitter_stage2;
    reg valid_stage2;
    reg clk_toggle_stage2;
    
    // Stage 1: Calculate jitter value
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage1 <= 5'd0;
            jitter_stage1 <= 3'd0;
            jitter_en_stage1 <= 1'b0;
            jitter_amount_stage1 <= 3'd0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            jitter_en_stage1 <= jitter_en;
            jitter_amount_stage1 <= jitter_amount;
            counter_stage1 <= counter_stage2 == 5'd0 ? 5'd0 : 
                             (valid_stage2 ? counter_stage2 : counter_stage1);
            
            if (jitter_en)
                jitter_stage1 <= {^counter_stage1, counter_stage1[1:0]} & jitter_amount;
            else
                jitter_stage1 <= 3'd0;
        end
    end
    
    // Stage 2: Update counter and generate clock output
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage2 <= 5'd0;
            jitter_stage2 <= 3'd0;
            valid_stage2 <= 1'b0;
            clk_toggle_stage2 <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            jitter_stage2 <= jitter_stage1;
            
            if (valid_stage1) begin
                if (counter_stage1 + jitter_stage1 >= 5'd16) begin
                    counter_stage2 <= 5'd0;
                    clk_toggle_stage2 <= ~clk_toggle_stage2;
                    clk_out <= ~clk_toggle_stage2;
                end else begin
                    counter_stage2 <= counter_stage1 + 5'd1;
                end
            end
        end
    end
endmodule