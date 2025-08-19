//SystemVerilog
module async_fifo_sync #(parameter ADDR_W=4) (
    input  wire                wr_clk,
    input  wire                rd_clk,
    input  wire                rst,
    input  wire [ADDR_W:0]     gray_wptr,
    output reg  [ADDR_W:0]     synced_wptr
);

    // Pipeline stage 1: First register synchronization
    reg [ADDR_W:0] gray_wptr_stage1;
    // Pipeline stage 2: Second register synchronization
    reg [ADDR_W:0] gray_wptr_stage2;
    // Pipeline stage 3: Third register synchronization
    reg [ADDR_W:0] gray_wptr_stage3;

    // Stage 1: Synchronize gray_wptr into stage1
    // Handles both reset and normal operation for stage1
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            gray_wptr_stage1 <= { (ADDR_W+1) {1'b0} };
        end else begin
            gray_wptr_stage1 <= gray_wptr;
        end
    end

    // Stage 2: Synchronize stage1 into stage2
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            gray_wptr_stage2 <= { (ADDR_W+1) {1'b0} };
        end else begin
            gray_wptr_stage2 <= gray_wptr_stage1;
        end
    end

    // Stage 3: Synchronize stage2 into stage3
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            gray_wptr_stage3 <= { (ADDR_W+1) {1'b0} };
        end else begin
            gray_wptr_stage3 <= gray_wptr_stage2;
        end
    end

    // Output stage: Register the final synchronized pointer
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            synced_wptr <= { (ADDR_W+1) {1'b0} };
        end else begin
            synced_wptr <= gray_wptr_stage3;
        end
    end

endmodule