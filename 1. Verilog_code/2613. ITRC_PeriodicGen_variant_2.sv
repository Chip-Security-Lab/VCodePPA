//SystemVerilog
module ITRC_PeriodicGen #(
    parameter PERIOD = 100
)(
    input clk,
    input rst_n,
    input en,
    output reg int_out
);
    // Stage 1: Counter Update Logic
    reg [$clog2(PERIOD):0] counter_stage1;
    reg [$clog2(PERIOD):0] counter_next_stage1;
    reg en_stage1;
    
    // Stage 2: Output Generation Logic
    reg [$clog2(PERIOD):0] counter_stage2;
    reg en_stage2;
    reg int_out_next;
    
    // Stage 1: Counter Update
    always @(*) begin
        if (!rst_n) begin
            counter_next_stage1 = 0;
        end else if (en) begin
            if (counter_stage1 == PERIOD-1) begin
                counter_next_stage1 = 0;
            end else begin
                counter_next_stage1 = counter_stage1 + 1;
            end
        end else begin
            counter_next_stage1 = counter_stage1;
        end
    end
    
    // Stage 2: Output Generation
    always @(*) begin
        if (!rst_n) begin
            int_out_next = 0;
        end else if (en_stage2) begin
            int_out_next = (counter_stage2 == PERIOD-1);
        end else begin
            int_out_next = 0;
        end
    end
    
    // Pipeline Registers
    always @(posedge clk) begin
        if (!rst_n) begin
            counter_stage1 <= 0;
            counter_stage2 <= 0;
            en_stage1 <= 0;
            en_stage2 <= 0;
            int_out <= 0;
        end else begin
            counter_stage1 <= counter_next_stage1;
            counter_stage2 <= counter_stage1;
            en_stage1 <= en;
            en_stage2 <= en_stage1;
            int_out <= int_out_next;
        end
    end
endmodule