//SystemVerilog
module async_fifo_sync #(
    parameter ADDR_W = 4
)(
    input  wire                  wr_clk,
    input  wire                  rd_clk,
    input  wire                  rst,
    input  wire [ADDR_W:0]       gray_wptr,  
    output reg  [ADDR_W:0]       synced_wptr
);

    reg [ADDR_W:0] gray_wptr_stage1;
    reg [ADDR_W:0] gray_wptr_stage2;

    wire [ADDR_W:0] rst_vector;
    assign rst_vector = { (ADDR_W+1){1'b0} };

    always @(posedge rd_clk) begin
        if (rst) begin
            gray_wptr_stage1 <= rst_vector;
            gray_wptr_stage2 <= rst_vector;
            synced_wptr      <= rst_vector;
        end else begin
            gray_wptr_stage1 <= gray_wptr;
            gray_wptr_stage2 <= gray_wptr_stage1;
            synced_wptr      <= gray_wptr_stage2;
        end
    end

endmodule