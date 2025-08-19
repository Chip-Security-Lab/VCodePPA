//SystemVerilog
module rst_sequencer(
    input wire clk,
    input wire rst_trigger,
    output reg [3:0] rst_stages
);
    // Pipeline stage registers
    reg [2:0] counter_stage1;
    reg [2:0] counter_stage2;
    reg rst_trigger_stage1;
    reg rst_trigger_stage2;
    reg [3:0] rst_stages_stage1;
    reg [3:0] rst_stages_stage2;
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Input processing and counter manipulation
    always @(posedge clk) begin
        rst_trigger_stage1 <= rst_trigger;
        valid_stage1 <= 1'b1;  // Always valid after first cycle
        
        if (rst_trigger) begin
            counter_stage1 <= 3'b0;
            rst_stages_stage1 <= 4'b1111;
        end else if (counter_stage1 < 3'b111) begin
            counter_stage1 <= counter_stage1 + 1'b1;
            rst_stages_stage1 <= rst_stages_stage1 >> 1;
        end
    end
    
    // Stage 2: Output calculation and finalization
    always @(posedge clk) begin
        rst_trigger_stage2 <= rst_trigger_stage1;
        valid_stage2 <= valid_stage1;
        counter_stage2 <= counter_stage1;
        rst_stages_stage2 <= rst_stages_stage1;
        
        // Final output assignment
        if (valid_stage2) begin
            rst_stages <= rst_stages_stage2;
        end
    end

endmodule