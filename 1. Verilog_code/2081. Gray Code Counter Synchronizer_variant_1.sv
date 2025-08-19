//SystemVerilog
`timescale 1ns / 1ps

module gray_counter_sync_pipelined #(parameter WIDTH = 8) (
    input  wire                  src_clk,
    input  wire                  dst_clk,
    input  wire                  reset,
    input  wire                  increment,
    output wire [WIDTH-1:0]      sync_count,
    output wire                  sync_count_valid
);

    // Stage 1: Binary counter increment (src_clk domain)
    reg [WIDTH-1:0] bin_counter_stage1;
    reg             increment_stage1;
    reg             valid_stage1;

    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            bin_counter_stage1 <= {WIDTH{1'b0}};
            increment_stage1    <= 1'b0;
            valid_stage1        <= 1'b0;
        end else begin
            increment_stage1 <= increment;
            valid_stage1     <= increment;
            if (increment) begin
                bin_counter_stage1 <= bin_counter_stage1 + 1'b1;
            end
        end
    end

    // Stage 2: Binary to Gray conversion (src_clk domain)
    reg [WIDTH-1:0] gray_code_stage2;
    reg             valid_stage2;

    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            gray_code_stage2 <= {WIDTH{1'b0}};
            valid_stage2     <= 1'b0;
        end else begin
            gray_code_stage2 <= bin_counter_stage1 ^ (bin_counter_stage1 >> 1);
            valid_stage2     <= valid_stage1;
        end
    end

    // Stage 3: Gray code synchronizer (cross to dst_clk domain)
    reg [WIDTH-1:0] gray_sync_stage3, gray_sync_stage4;
    reg             valid_stage3, valid_stage4;

    // Synchronize gray_code_stage2 to dst_clk domain with double flip-flop
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            gray_sync_stage3 <= {WIDTH{1'b0}};
            gray_sync_stage4 <= {WIDTH{1'b0}};
            valid_stage3     <= 1'b0;
            valid_stage4     <= 1'b0;
        end else begin
            gray_sync_stage3 <= gray_code_stage2;
            gray_sync_stage4 <= gray_sync_stage3;
            valid_stage3     <= valid_stage2;
            valid_stage4     <= valid_stage3;
        end
    end

    // Stage 4: Gray to binary conversion (dst_clk domain, pipelined)
    reg [WIDTH-1:0] bin_conv_stage5;
    reg             valid_stage5;
    integer k;

    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            bin_conv_stage5 <= {WIDTH{1'b0}};
            valid_stage5    <= 1'b0;
        end else begin
            bin_conv_stage5[WIDTH-1] <= gray_sync_stage4[WIDTH-1];
            for (k = WIDTH-2; k >= 0; k = k - 1)
                bin_conv_stage5[k] <= bin_conv_stage5[k+1] ^ gray_sync_stage4[k];
            valid_stage5 <= valid_stage4;
        end
    end

    assign sync_count       = bin_conv_stage5;
    assign sync_count_valid = valid_stage5;

endmodule