//SystemVerilog
module nor2_pipeline_valid_ready (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    input  wire in_valid,
    output wire in_ready,
    output reg  out_y,
    output reg  out_valid,
    input  wire out_ready
);

// Pipeline Stage 1: Input Registering with Valid
reg stage1_a;
reg stage1_b;
reg stage1_valid;

assign in_ready = !stage1_valid || (stage2_ready && stage1_valid);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage1_a     <= 1'b0;
        stage1_b     <= 1'b0;
        stage1_valid <= 1'b0;
    end else if (in_ready) begin
        stage1_a     <= in_a;
        stage1_b     <= in_b;
        stage1_valid <= in_valid;
    end else if (stage2_ready && stage1_valid) begin
        stage1_valid <= 1'b0;
    end
end

// Pipeline Stage 2: NOR operation with Valid
reg stage2_nor;
reg stage2_valid;

wire stage2_ready = !stage2_valid || (out_ready && stage2_valid);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage2_nor   <= 1'b0;
        stage2_valid <= 1'b0;
    end else if (stage2_ready) begin
        stage2_nor   <= ~(stage1_a | stage1_b);
        stage2_valid <= stage1_valid;
    end else if (out_ready && stage2_valid) begin
        stage2_valid <= 1'b0;
    end
end

// Pipeline Stage 3: Output Registering with Valid
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_y     <= 1'b0;
        out_valid <= 1'b0;
    end else if (out_ready || !out_valid) begin
        out_y     <= stage2_nor;
        out_valid <= stage2_valid;
    end
end

endmodule