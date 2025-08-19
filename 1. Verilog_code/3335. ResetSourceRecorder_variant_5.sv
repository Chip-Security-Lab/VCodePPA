//SystemVerilog
module ResetSourceRecorder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  reset_source,
    output reg  [1:0]  last_reset_source
);

    // Pipeline stage 1: Capture reset_source input
    reg [1:0] reset_source_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_source_stage1 <= 2'b00;
        else
            reset_source_stage1 <= reset_source;
    end

    // Pipeline stage 2: Latch to output with clear structure and path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            last_reset_source <= 2'b00;
        else
            last_reset_source <= reset_source_stage1;
    end

endmodule