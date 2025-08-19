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
    reg [2:0] wr_ptr_next, rd_ptr_next;
    reg cmd_ready_next;
    reg [31:0] cmd_in_pipe;
    reg cmd_valid_pipe;
    
    // 简化的指针更新逻辑
    wire [2:0] wr_ptr_plus_1 = wr_ptr + 1'b1;
    wire [2:0] rd_ptr_plus_1 = rd_ptr + 1'b1;
    wire queue_full = (wr_ptr_next == rd_ptr_plus_1);
    wire queue_empty = (rd_ptr == wr_ptr);
    
    // 第一级流水线
    always @(posedge clk) begin
        cmd_in_pipe <= cmd_in;
        cmd_valid_pipe <= cmd_valid;
    end
    
    // 第二级流水线
    always @(posedge clk) begin
        if(cmd_valid_pipe && !queue_full) begin
            cmd_queue[wr_ptr] <= cmd_in_pipe;
            wr_ptr_next <= wr_ptr_plus_1;
        end else begin
            wr_ptr_next <= wr_ptr;
        end
        
        if(!queue_empty) begin
            rd_ptr_next <= rd_ptr_plus_1;
        end else begin
            rd_ptr_next <= rd_ptr;
        end
        
        cmd_ready_next <= !queue_full;
    end
    
    // 第三级流水线
    always @(posedge clk) begin
        wr_ptr <= wr_ptr_next;
        rd_ptr <= rd_ptr_next;
        cmd_ready <= cmd_ready_next;
    end
endmodule