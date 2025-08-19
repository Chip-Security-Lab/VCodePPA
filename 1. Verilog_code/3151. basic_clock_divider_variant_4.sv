//SystemVerilog
module basic_clock_divider(
    input wire clk_in,
    input wire rst_n,
    output reg clk_out
);
    // Pipeline stage 1: Counter increment
    reg [3:0] counter_stage1;
    reg [3:0] counter_stage2;
    reg clk_out_stage1;
    reg clk_out_stage2;
    
    // Stage 1: Counter logic
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= 4'd0;
            clk_out_stage1 <= 1'b0;
        end else begin
            counter_stage1 <= counter_stage2;
            clk_out_stage1 <= clk_out_stage2;
        end
    end
    
    // Stage 2: Counter update and clock generation
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= 4'd0;
            clk_out_stage2 <= 1'b0;
        end else if (counter_stage1 == 4'd9) begin
            counter_stage2 <= 4'd0;
            clk_out_stage2 <= ~clk_out_stage1;
        end else begin
            counter_stage2 <= counter_stage1 + 1'b1;
            clk_out_stage2 <= clk_out_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
        end else begin
            clk_out <= clk_out_stage2;
        end
    end
endmodule