//SystemVerilog
module error_detect_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] in_data,
    input in_valid,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    output reg error,
    input out_ready
);

    // Stage 1: Input and parity calculation
    reg [DWIDTH-1:0] data_stage1;
    reg valid_stage1;
    reg parity_stage1;
    reg ready_stage1;
    integer j;

    // Buffer for high fanout signals
    reg clk_buf;
    reg parity_stage1_buf;

    // Stage 2: Error detection and output preparation
    reg [DWIDTH-1:0] data_stage2;
    reg valid_stage2;
    reg error_stage2;
    reg ready_stage2;

    // Stage 1: Parity calculation
    always @(*) begin
        parity_stage1 = 0;
        for (j = 0; j < DWIDTH; j = j + 1)
            parity_stage1 = parity_stage1 ^ in_data[j];
    end

    // Buffering high fanout signal parity_stage1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_stage1_buf <= 0;
        end else begin
            parity_stage1_buf <= parity_stage1;
        end
    end

    // Stage 1 pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
            ready_stage1 <= 1;
        end else if (in_valid && in_ready) begin
            data_stage1 <= in_data;
            valid_stage1 <= 1;
            ready_stage1 <= 0;
        end else if (ready_stage2) begin
            valid_stage1 <= 0;
            ready_stage1 <= 1;
        end
    end

    // Stage 2 pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 0;
            valid_stage2 <= 0;
            error_stage2 <= 0;
            ready_stage2 <= 1;
        end else if (valid_stage1 && ready_stage2) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= 1;
            error_stage2 <= parity_stage1_buf ? 1'b0 : 1'b1;
            ready_stage2 <= 0;
        end else if (out_valid && out_ready) begin
            valid_stage2 <= 0;
            ready_stage2 <= 1;
            error_stage2 <= 0;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 0;
            out_valid <= 0;
            error <= 0;
            in_ready <= 1;
        end else if (valid_stage2 && ready_stage2) begin
            out_data <= data_stage2;
            out_valid <= 1;
            error <= error_stage2;
            in_ready <= 0;
        end else if (out_valid && out_ready) begin
            out_valid <= 0;
            in_ready <= 1;
            error <= 0;
        end
    end

endmodule