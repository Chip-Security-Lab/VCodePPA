//SystemVerilog
module bcd2bin_pipeline (
    input              clk,
    input              rst_n,
    input              enable,
    input      [7:0]   bcd_in,
    output reg [6:0]   bin_out,
    output reg         valid_out
);

// Stage 1: Latch inputs
reg [3:0] bcd_high_stage1;
reg [3:0] bcd_low_stage1;
reg       enable_stage1;
reg       valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bcd_high_stage1 <= 4'd0;
    end else begin
        bcd_high_stage1 <= bcd_in[7:4];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bcd_low_stage1 <= 4'd0;
    end else begin
        bcd_low_stage1 <= bcd_in[3:0];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        enable_stage1 <= 1'b0;
    end else begin
        enable_stage1 <= enable;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage1 <= 1'b0;
    end else begin
        valid_stage1 <= enable;
    end
end

// Stage 2: Multiply high nibble by 10 and pass low nibble
reg [7:0] mul_high_stage2;
reg [3:0] bcd_low_stage2;
reg       enable_stage2;
reg       valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mul_high_stage2 <= 8'd0;
    end else begin
        mul_high_stage2 <= bcd_high_stage1 * 8'd10;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bcd_low_stage2 <= 4'd0;
    end else begin
        bcd_low_stage2 <= bcd_low_stage1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        enable_stage2 <= 1'b0;
    end else begin
        enable_stage2 <= enable_stage1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage2 <= 1'b0;
    end else begin
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Add low nibble to multiplication result
reg [6:0] bin_out_stage3;
reg       valid_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bin_out_stage3 <= 7'd0;
    end else begin
        bin_out_stage3 <= mul_high_stage2[6:0] + bcd_low_stage2;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage3 <= 1'b0;
    end else begin
        valid_stage3 <= valid_stage2 & enable_stage2;
    end
end

// Output stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bin_out <= 7'd0;
    end else begin
        bin_out <= bin_out_stage3;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_out <= 1'b0;
    end else begin
        valid_out <= valid_stage3;
    end
end

endmodule