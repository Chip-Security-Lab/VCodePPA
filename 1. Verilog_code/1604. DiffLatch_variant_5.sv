//SystemVerilog
module DiffLatch #(parameter DW=8) (
    input clk,
    input rst_n,
    input valid_in,
    output reg ready_out,
    input [DW-1:0] d_p, d_n,
    output reg valid_out,
    output reg [DW-1:0] q
);

    // Pipeline stage 1 registers
    reg [DW-1:0] d_p_stage1, d_n_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [DW-1:0] d_p_stage2, d_n_stage2;
    reg valid_stage2;

    // Pipeline stage 3 registers
    reg [DW-1:0] xor_result_stage3;
    reg valid_stage3;

    // Pipeline stage 4 registers
    reg [DW-1:0] result_stage4;
    reg valid_stage4;

    // Pipeline control
    assign ready_out = 1'b1;

    // Stage 1: Input sampling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_p_stage1 <= {DW{1'b0}};
            d_n_stage1 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            d_p_stage1 <= d_p;
            d_n_stage1 <= d_n;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Data forwarding
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

    // Stage 3: XOR computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result_stage3 <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            xor_result_stage3 <= d_p_stage2 ^ d_n_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Result buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage4 <= {DW{1'b0}};
            valid_stage4 <= 1'b0;
        end else begin
            result_stage4 <= xor_result_stage3;
            valid_stage4 <= valid_stage3;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            q <= result_stage4;
            valid_out <= valid_stage4;
        end
    end

endmodule