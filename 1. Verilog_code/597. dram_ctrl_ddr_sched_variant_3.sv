//SystemVerilog
module dram_ctrl_ddr_sched #(
    parameter CMD_QUEUE_DEPTH = 8,
    parameter PTR_WIDTH = 3
)(
    input clk,
    input [31:0] cmd_in,
    input cmd_valid,
    output reg cmd_ready
);

    // Command queue storage
    reg [31:0] cmd_queue [0:CMD_QUEUE_DEPTH-1];
    
    // Queue pointers
    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr_next;
    
    // Queue status signals
    wire queue_full;
    wire queue_empty;
    wire queue_almost_full;
    
    // Queue control logic
    assign queue_full = (wr_ptr + 1) == rd_ptr;
    assign queue_empty = wr_ptr == rd_ptr;
    assign queue_almost_full = (wr_ptr + 2) == rd_ptr;
    
    // Write pointer update
    always @(posedge clk) begin
        if (cmd_valid && !queue_full) begin
            cmd_queue[wr_ptr] <= cmd_in;
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    // Read pointer update
    always @(posedge clk) begin
        if (!queue_empty) begin
            rd_ptr_next <= rd_ptr + 1;
            rd_ptr <= rd_ptr_next;
        end
    end
    
    // Ready signal generation
    always @(posedge clk) begin
        cmd_ready <= !queue_almost_full;
    end

endmodule