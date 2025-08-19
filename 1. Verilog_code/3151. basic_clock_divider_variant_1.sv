//SystemVerilog
module basic_clock_divider(
    input wire clk_in,
    input wire rst_n,
    output reg clk_out
);
    reg [3:0] counter_stage1;
    reg [3:0] counter_stage2;
    reg clk_out_stage1;
    
    // Stage 1: Counter increment
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= 4'd0;
            clk_out_stage1 <= 1'b0;
        end else if (counter_stage1 == 4'd9) begin
            counter_stage1 <= 4'd0;
            clk_out_stage1 <= ~clk_out_stage1;
        end else begin
            counter_stage1 <= counter_stage1 + 1'b1;
        end
    end
    
    // Stage 2: Output synchronization
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= 4'd0;
            clk_out <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            clk_out <= clk_out_stage1;
        end
    end
endmodule