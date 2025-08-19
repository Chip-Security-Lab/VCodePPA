//SystemVerilog
module d_latch_registered_pipelined (
    input wire d,
    input wire latch_enable,
    input wire clk,
    input wire rst_n,
    output reg q_reg
);

    // Pipeline stage 1: Input register
    reg d_stage1;
    reg latch_enable_stage1;
    
    // Pipeline stage 2: Latch logic
    reg d_stage2;
    reg latch_enable_stage2;
    
    // Pipeline stage 3: Output register
    reg d_stage3;
    reg latch_enable_stage3;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage1 <= 1'b0;
            latch_enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            d_stage1 <= d;
            latch_enable_stage1 <= latch_enable;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Latch logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage2 <= 1'b0;
            latch_enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            d_stage2 <= d_stage1;
            latch_enable_stage2 <= latch_enable_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage3 <= 1'b0;
            latch_enable_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            q_reg <= 1'b0;
        end else begin
            d_stage3 <= d_stage2;
            latch_enable_stage3 <= latch_enable_stage2;
            valid_stage3 <= valid_stage2;
            if (latch_enable_stage3 && valid_stage3)
                q_reg <= d_stage3;
        end
    end
    
endmodule