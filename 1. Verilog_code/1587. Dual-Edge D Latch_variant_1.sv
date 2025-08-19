//SystemVerilog
module dual_edge_d_latch_pipelined (
    input wire d,
    input wire clk,
    input wire rst_n,
    output reg q,
    output reg valid
);

    // Pipeline registers
    reg d_stage1;
    reg valid_stage1;
    reg d_stage2;
    reg valid_stage2;
    
    // Stage 1: Input sampling - Positive edge triggered
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            d_stage1 <= d;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Edge detection - Negative edge triggered
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            d_stage2 <= d_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output generation - Positive edge triggered
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
            valid <= 1'b0;
        end else begin
            q <= d_stage2;
            valid <= valid_stage2;
        end
    end

endmodule