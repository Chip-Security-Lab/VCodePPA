module dram_ctrl_ddr_sched #(
    parameter CMD_QUEUE_DEPTH = 8
)(
    input clk,
    input [31:0] cmd_in,
    input cmd_valid,
    output reg cmd_ready
);
    // 命令队列
    reg [31:0] cmd_queue [0:CMD_QUEUE_DEPTH-1];
    reg [2:0] wr_ptr, rd_ptr;
    
    always @(posedge clk) begin
        if(cmd_valid && cmd_ready) begin
            cmd_queue[wr_ptr] <= cmd_in;
            wr_ptr <= wr_ptr + 1;
        end
        
        if(rd_ptr != wr_ptr) begin
            // 处理命令
            rd_ptr <= rd_ptr + 1;
        end
        
        cmd_ready <= (wr_ptr != rd_ptr + 1);
    end
endmodule
