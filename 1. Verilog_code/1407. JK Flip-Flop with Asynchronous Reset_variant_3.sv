//SystemVerilog
module jk_ff_async_reset_pipelined (
    input wire clk,
    input wire rst_n,
    input wire j,
    input wire k,
    input wire valid_in,
    output wire valid_out,
    output reg q
);
    // Stage 1: Input capture and decode
    reg j_stage1, k_stage1;
    reg valid_stage1;
    reg [1:0] jk_decoded_stage1;
    
    // Stage 2: State computation
    reg q_next_stage2;
    reg valid_stage2;
    
    // Input capture - stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            j_stage1 <= 1'b0;
            k_stage1 <= 1'b0;
        end else begin
            j_stage1 <= j;
            k_stage1 <= k;
        end
    end
    
    // JK operation decode - stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            jk_decoded_stage1 <= 2'b00;
        end else begin
            jk_decoded_stage1 <= {j, k};
        end
    end
    
    // Valid signal propagation - stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
        end
    end
    
    // Next state computation - stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_next_stage2 <= 1'b0;
        end else begin
            case (jk_decoded_stage1)
                2'b00: q_next_stage2 <= q;
                2'b01: q_next_stage2 <= 1'b0;
                2'b10: q_next_stage2 <= 1'b1;
                2'b11: q_next_stage2 <= ~q;
                default: q_next_stage2 <= q;
            endcase
        end
    end
    
    // Valid signal propagation - stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Final stage: Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
        end else if (valid_stage2) begin
            q <= q_next_stage2;
        end
    end
    
    // Valid signal propagation
    assign valid_out = valid_stage2;
    
endmodule