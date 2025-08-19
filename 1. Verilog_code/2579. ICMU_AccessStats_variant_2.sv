//SystemVerilog
module ICMU_AccessStats #(
    parameter DW = 64,
    parameter STAT_W = 8
)(
    input clk,
    input access_en,
    input [DW-1:0] ctx_addr,
    output reg [DW-1:0] hot_ctx
);

    reg [STAT_W-1:0] access_count [0:(1<<DW)-1];
    reg [DW-1:0] max_addr;
    reg [STAT_W-1:0] max_count;
    reg [DW-1:0] max_addr_pipe;
    reg [STAT_W-1:0] max_count_pipe;
    reg [STAT_W-1:0] current_count;
    reg [DW-1:0] current_addr;
    reg access_en_pipe;

    // Access counter update logic
    always @(posedge clk) begin
        if (access_en) begin
            access_count[ctx_addr] <= access_count[ctx_addr] + 1;
        end
    end

    // Pipeline stage 1: Capture current values
    always @(posedge clk) begin
        current_count <= access_count[ctx_addr];
        current_addr <= ctx_addr;
        access_en_pipe <= access_en;
    end

    // Pipeline stage 2: Max count and address tracking
    always @(posedge clk) begin
        if (access_en_pipe && (current_count >= max_count_pipe)) begin
            max_count_pipe <= current_count;
            max_addr_pipe <= current_addr;
        end
    end

    // Pipeline stage 3: Final max value update
    always @(posedge clk) begin
        max_count <= max_count_pipe;
        max_addr <= max_addr_pipe;
    end

    // Hot context output update
    always @(posedge clk) begin
        hot_ctx <= max_addr;
    end

endmodule