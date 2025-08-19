//SystemVerilog
module ITRC_PeriodicGen #(
    parameter PERIOD = 100
)(
    input clk,
    input rst_n,
    input en,
    output reg int_out
);
    reg [$clog2(PERIOD):0] counter_stage1;
    reg [$clog2(PERIOD):0] counter_stage2;
    wire [$clog2(PERIOD):0] next_counter;
    wire [$clog2(PERIOD):0] counter_plus_1;
    wire [$clog2(PERIOD):0] counter_plus_1_stage1;
    wire [$clog2(PERIOD):0] counter_plus_1_stage2;
    wire [$clog2(PERIOD):0] counter_plus_1_stage3;
    wire [$clog2(PERIOD):0] counter_plus_1_stage4;
    
    // Stage 1: LSB addition
    assign counter_plus_1_stage1[0] = ~counter_stage1[0];
    assign counter_plus_1_stage1[1] = counter_stage1[1] ^ counter_stage1[0];
    
    // Stage 2: Middle bits addition
    assign counter_plus_1_stage2[2] = counter_stage1[2] ^ (counter_stage1[1] & counter_stage1[0]);
    assign counter_plus_1_stage2[3] = counter_stage1[3] ^ (counter_stage1[2] & counter_stage1[1] & counter_stage1[0]);
    
    // Stage 3: Upper bits addition
    assign counter_plus_1_stage3[4] = counter_stage1[4] ^ (counter_stage1[3] & counter_stage1[2] & counter_stage1[1] & counter_stage1[0]);
    assign counter_plus_1_stage3[5] = counter_stage1[5] ^ (counter_stage1[4] & counter_stage1[3] & counter_stage1[2] & counter_stage1[1] & counter_stage1[0]);
    
    // Stage 4: MSB addition
    assign counter_plus_1_stage4[6] = counter_stage1[6] ^ (counter_stage1[5] & counter_stage1[4] & counter_stage1[3] & counter_stage1[2] & counter_stage1[1] & counter_stage1[0]);
    assign counter_plus_1_stage4[7] = counter_stage1[7] ^ (counter_stage1[6] & counter_stage1[5] & counter_stage1[4] & counter_stage1[3] & counter_stage1[2] & counter_stage1[1] & counter_stage1[0]);
    
    // Combine all stages
    assign counter_plus_1 = {counter_plus_1_stage4[7:6], counter_plus_1_stage3[5:4], 
                           counter_plus_1_stage2[3:2], counter_plus_1_stage1[1:0]};
    
    assign next_counter = (counter_stage2 == PERIOD-1) ? 0 : counter_plus_1;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter_stage1 <= 0;
            counter_stage2 <= 0;
            int_out <= 0;
        end else if (en) begin
            counter_stage1 <= counter_stage2;
            counter_stage2 <= next_counter;
            int_out <= (counter_stage2 == PERIOD-1);
        end
    end
endmodule