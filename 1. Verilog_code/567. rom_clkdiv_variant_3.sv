//SystemVerilog
module rom_clkdiv #(parameter MAX=50000000)(
    input clk,
    output reg clk_out
);
    reg [25:0] counter_stage1;
    reg [25:0] counter_stage2;
    reg [25:0] max_val_stage1 = MAX;
    reg clk_out_stage1;
    
    // Stage 1: Counter Increment
    always @(posedge clk) begin
        counter_stage1 <= (counter_stage1 >= max_val_stage1) ? 26'd0 : counter_stage1 + 1'b1;
        clk_out_stage1 <= (counter_stage1 >= max_val_stage1) ? ~clk_out_stage1 : clk_out_stage1;
    end

    // Stage 2: Output Assignment
    always @(posedge clk) begin
        counter_stage2 <= counter_stage1; // Pass the counter value to the next stage
        clk_out <= clk_out_stage1; // Update the output clock signal
    end
endmodule