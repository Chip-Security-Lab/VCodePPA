//SystemVerilog
module ResetSourceRecorder (
    input wire clk,
    input wire rst_n,
    input wire [1:0] reset_source,
    output reg [1:0] last_reset_source
);

    // Stage 1: Capture input and validate
    reg [1:0] reset_source_stage1;
    reg       valid_stage1;

    // Stage 2: Process logic (limit and select)
    reg [1:0] reset_source_stage2;
    reg       valid_stage2;

    // Stage 3: Output register
    reg [1:0] last_reset_source_stage3;
    reg       valid_stage3;

    // Pipeline flush logic
    wire pipeline_flush = !rst_n;

    // Stage 1: Input Registering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_source_stage1 <= 2'd0;
            valid_stage1        <= 1'b0;
        end else begin
            reset_source_stage1 <= reset_source;
            valid_stage1        <= 1'b1;
        end
    end

    // Stage 2: Logic Processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_source_stage2 <= 2'd0;
            valid_stage2        <= 1'b0;
        end else begin
            reset_source_stage2 <= (reset_source_stage1 <= 2'd3) ? reset_source_stage1 : 2'd0;
            valid_stage2        <= valid_stage1;
        end
    end

    // Stage 3: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_reset_source_stage3 <= (reset_source <= 2'd3) ? reset_source : 2'd0;
            valid_stage3             <= 1'b0;
        end else begin
            last_reset_source_stage3 <= reset_source_stage2;
            valid_stage3             <= valid_stage2;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_reset_source <= (reset_source <= 2'd3) ? reset_source : 2'd0;
        end else if (valid_stage3) begin
            last_reset_source <= last_reset_source_stage3;
        end
    end

endmodule