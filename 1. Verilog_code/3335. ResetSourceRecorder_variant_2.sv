//SystemVerilog
module ResetSourceRecorder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  reset_source,
    output wire [1:0]  last_reset_source
);

    // Pipeline stage 1: capture input
    reg [1:0] reset_source_stage1;
    reg       valid_stage1;

    // Pipeline stage 2: output register
    reg [1:0] last_reset_source_stage2;
    reg       valid_stage2;

    // Flattened pipeline flush logic and balanced reset logic
    wire async_reset = ~rst_n;

    // Balanced Stage 1 - capture input and valid
    always @(posedge clk) begin
        if (async_reset) begin
            reset_source_stage1 <= 2'b00;
            valid_stage1        <= 1'b0;
        end else begin
            reset_source_stage1 <= reset_source;
            valid_stage1        <= 1'b1;
        end
    end

    // Balanced Stage 2 - capture from stage 1
    always @(posedge clk) begin
        if (async_reset) begin
            last_reset_source_stage2 <= 2'b00;
            valid_stage2             <= 1'b0;
        end else begin
            last_reset_source_stage2 <= reset_source_stage1;
            valid_stage2             <= valid_stage1;
        end
    end

    // Direct output assignment
    assign last_reset_source = last_reset_source_stage2;

endmodule