//SystemVerilog
module dram_ctrl_power #(
    parameter LOW_POWER_THRESH = 100
)(
    input clk,
    input activity,
    output reg clk_en
);
    reg [7:0] idle_counter_stage1;
    reg [7:0] idle_counter_stage2;
    reg activity_stage1;
    reg activity_stage2;
    reg clk_en_stage1;
    
    // Stage 1: Activity detection and counter update
    always @(posedge clk) begin
        activity_stage1 <= activity;
        if(activity_stage1) begin
            idle_counter_stage1 <= 0;
            clk_en_stage1 <= 1;
        end else if(idle_counter_stage1 < LOW_POWER_THRESH) begin
            idle_counter_stage1 <= idle_counter_stage1 + 1;
            clk_en_stage1 <= 1;
        end else begin
            clk_en_stage1 <= 0;
        end
    end
    
    // Stage 2: Counter and control signal propagation
    always @(posedge clk) begin
        activity_stage2 <= activity_stage1;
        idle_counter_stage2 <= idle_counter_stage1;
        clk_en <= clk_en_stage1;
    end
endmodule