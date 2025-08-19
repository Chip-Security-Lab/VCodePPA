//SystemVerilog
module async_fifo_sync #(parameter ADDR_W=4) (
    input  wire              wr_clk,
    input  wire              rd_clk,
    input  wire              rst,
    input  wire [ADDR_W:0]   gray_wptr,
    output reg  [ADDR_W:0]   synced_wptr
);

    reg [ADDR_W:0] gray_wptr_comb;
    reg [ADDR_W:0] gray_wptr_sync1;
    reg [ADDR_W:0] gray_wptr_sync2;

    // Move registers after the combination logic to improve timing
    always @* begin
        gray_wptr_comb = gray_wptr;
    end

    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            gray_wptr_sync1 <= { (ADDR_W+1){1'b0} };
            gray_wptr_sync2 <= { (ADDR_W+1){1'b0} };
            synced_wptr     <= { (ADDR_W+1){1'b0} };
        end else begin
            gray_wptr_sync1 <= gray_wptr_comb;
            gray_wptr_sync2 <= gray_wptr_sync1;
            synced_wptr     <= gray_wptr_sync2;
        end
    end

endmodule