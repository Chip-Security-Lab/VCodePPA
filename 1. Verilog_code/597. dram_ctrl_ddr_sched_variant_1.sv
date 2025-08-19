//SystemVerilog
module dram_ctrl_ddr_sched #(
    parameter CMD_QUEUE_DEPTH = 8
)(
    input clk,
    input [31:0] cmd_in,
    input cmd_valid,
    output reg cmd_ready
);
    reg [31:0] cmd_queue [0:CMD_QUEUE_DEPTH-1];
    reg [2:0] wr_ptr, rd_ptr;
    wire queue_full, queue_empty;
    
    assign queue_full = (wr_ptr + 1) == rd_ptr;
    assign queue_empty = wr_ptr == rd_ptr;
    
    always @(posedge clk) begin
        if(cmd_valid && !queue_full) begin
            cmd_queue[wr_ptr] <= cmd_in;
            wr_ptr <= wr_ptr + 1;
        end
        
        if(!queue_empty) begin
            rd_ptr <= rd_ptr + 1;
        end
        
        cmd_ready <= !queue_full;
    end
endmodule