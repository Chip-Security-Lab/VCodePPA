//SystemVerilog
module EdgeDetectLatch (
    input wire clk,
    input wire rst_n,
    input wire sig_in,
    output reg rising,
    output reg falling
);

// Pipeline registers
reg sig_in_stage1;
reg sig_in_stage2;
reg last_sig_stage1;
reg last_sig_stage2;

// Pipeline control signals
reg valid_stage1;
reg valid_stage2;

// Stage 1: Input sampling
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sig_in_stage1 <= 1'b0;
        valid_stage1 <= 1'b0;
    end else begin
        sig_in_stage1 <= sig_in;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Edge detection
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sig_in_stage2 <= 1'b0;
        last_sig_stage1 <= 1'b0;
        valid_stage2 <= 1'b0;
    end else begin
        sig_in_stage2 <= sig_in_stage1;
        last_sig_stage1 <= sig_in_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Output generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rising <= 1'b0;
        falling <= 1'b0;
    end else if (valid_stage2) begin
        rising <= sig_in_stage2 & ~last_sig_stage1;
        falling <= ~sig_in_stage2 & last_sig_stage1;
    end else begin
        rising <= 1'b0;
        falling <= 1'b0;
    end
end

endmodule