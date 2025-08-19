//SystemVerilog
module BurstArbiter #(parameter BURST_LEN=4) (
    input clk, rst, en,
    input [3:0] req,
    output reg [3:0] grant
);

reg [1:0] burst_cnt;
reg [3:0] req_buf;
reg [1:0] burst_cnt_buf;
reg [3:0] grant_next;

// 添加缓冲寄存器
reg [3:0] req_buf_stage1;
reg [3:0] req_buf_stage2;
reg [1:0] burst_cnt_buf_stage1;
reg [1:0] burst_cnt_buf_stage2;

always @(posedge clk) begin
    if(rst) begin
        {grant, burst_cnt, req_buf, req_buf_stage1, req_buf_stage2, 
         burst_cnt_buf, burst_cnt_buf_stage1, burst_cnt_buf_stage2} <= 0;
    end
    else if(en) begin
        // 多级缓冲结构
        req_buf_stage1 <= req;
        req_buf_stage2 <= req_buf_stage1;
        req_buf <= req_buf_stage2;
        
        burst_cnt_buf_stage1 <= burst_cnt;
        burst_cnt_buf_stage2 <= burst_cnt_buf_stage1;
        burst_cnt_buf <= burst_cnt_buf_stage2;
        
        if(|grant) begin
            burst_cnt <= (burst_cnt_buf == BURST_LEN-1) ? 0 : burst_cnt_buf + 1;
            grant_next <= (burst_cnt_buf == BURST_LEN-1) ? req_buf & -req_buf : grant;
        end else begin
            grant_next <= req_buf & -req_buf;
            burst_cnt <= 0;
        end
        
        grant <= grant_next;
    end
end

endmodule