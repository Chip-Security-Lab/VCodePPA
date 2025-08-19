//SystemVerilog
module DiffLatch #(parameter DW=8) (
    input clk,
    input rst_n,
    input [DW-1:0] d_p, d_n,
    output reg [DW-1:0] q,
    output reg valid
);

    // Pipeline registers
    reg [DW-1:0] d_p_stage1, d_n_stage1;
    reg [DW-1:0] d_p_stage2, d_n_stage2;
    reg valid_stage1, valid_stage2;

    // Stage 1: Input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_p_stage1 <= {DW{1'b0}};
            d_n_stage1 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            d_p_stage1 <= d_p;
            d_n_stage1 <= d_n;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: XOR computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_p_stage2 <= {DW{1'b0}};
            d_n_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            d_p_stage2 <= d_p_stage1;
            d_n_stage2 <= d_n_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= {DW{1'b0}};
            valid <= 1'b0;
        end else begin
            q <= d_p_stage2 ^ d_n_stage2;
            valid <= valid_stage2;
        end
    end

endmodule