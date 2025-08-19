//SystemVerilog
module shadow_reg_ring #(parameter DW=8, DEPTH=4) (
    input clk, shift,
    input [DW-1:0] new_data,
    output [DW-1:0] oldest_data
);
    reg [DW-1:0] ring_reg [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] wr_ptr;
    reg [$clog2(DEPTH)-1:0] rd_ptr;
    
    // 使用$clog2确定指针位宽，避免不必要的比较器开销
    initial begin
        wr_ptr = 0;
        rd_ptr = 1; // 预先计算读指针初始值
    end
    
    always @(posedge clk) begin
        if(shift) begin
            // 数据写入寄存器
            ring_reg[wr_ptr] <= new_data;
            
            // 预先计算下一个写指针值，减少关键路径
            if(wr_ptr == DEPTH-1)
                wr_ptr <= 0;
            else
                wr_ptr <= wr_ptr + 1;
                
            // 同步更新读指针，避免每次读取时计算，减少组合逻辑延迟
            if(rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            else
                rd_ptr <= rd_ptr + 1;
        end
    end
    
    // 直接使用预计算的读指针，避免每次读取时进行模运算
    assign oldest_data = ring_reg[rd_ptr];
endmodule