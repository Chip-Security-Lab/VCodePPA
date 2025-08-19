//SystemVerilog
module d_latch_clock_gated_pipelined (
    input wire d,
    input wire clk,
    input wire gate_en,
    input wire rst_n,
    output reg q,
    output reg valid
);

    // Pipeline registers
    reg d_stage1, d_stage2;
    reg gate_en_stage1, gate_en_stage2;
    reg valid_stage1, valid_stage2;
    wire gated_clk;

    // Clock gating logic
    assign gated_clk = clk & gate_en;

    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage1 <= 1'b0;
            gate_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            d_stage1 <= d;
            gate_en_stage1 <= gate_en;
            valid_stage1 <= 1'b1;
        end
    end

    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_stage2 <= 1'b0;
            gate_en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            d_stage2 <= d_stage1;
            gate_en_stage2 <= gate_en_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
            valid <= 1'b0;
        end else begin
            q <= d_stage2;
            valid <= valid_stage2;
        end
    end

endmodule