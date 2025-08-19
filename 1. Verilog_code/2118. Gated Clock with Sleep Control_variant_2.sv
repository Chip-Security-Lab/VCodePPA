//SystemVerilog
//==========================================================
//==========================================================
module gated_clk_sleep(
    input clk_src,
    input sleep,
    input enable,
    output gated_clk
);
    // Pipeline stage 1: Enable capture
    reg enable_latch;
    reg sleep_stage1, sleep_stage2;
    reg enable_stage1, enable_stage2;
    reg valid_stage1, valid_stage2;
    
    // Latch enable signal on negative edge (maintain original behavior)
    always @(negedge clk_src or posedge sleep) begin
        if (sleep)
            enable_latch <= 1'b0;
        else
            enable_latch <= enable;
    end
    
    // Pipeline registers for stage 1
    always @(posedge clk_src or posedge sleep) begin
        if (sleep) begin
            sleep_stage1 <= 1'b1;
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            sleep_stage1 <= sleep;
            enable_stage1 <= enable_latch;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline registers for stage 2
    always @(posedge clk_src or posedge sleep) begin
        if (sleep) begin
            sleep_stage2 <= 1'b1;
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            sleep_stage2 <= sleep_stage1;
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Final clock gating logic with pipelined signals
    assign gated_clk = clk_src & enable_stage2 & ~sleep_stage2 & valid_stage2;
endmodule