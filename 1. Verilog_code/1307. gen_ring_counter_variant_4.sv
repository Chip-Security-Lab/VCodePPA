//SystemVerilog
module gen_ring_counter #(parameter WIDTH=8) (
    input clk, rst,
    input enable, // 流水线控制信号
    output reg [WIDTH-1:0] cnt
);
    // 流水线寄存器
    reg [WIDTH-1:0] cnt_stage1, cnt_stage2;
    reg valid_stage1, valid_stage2;
    
    // 为高扇出的cnt信号添加缓冲寄存器，分散负载
    reg [WIDTH-1:0] cnt_buf1, cnt_buf2;
    
    // 阶段1：产生环形移位数据
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage1 <= {{WIDTH-1{1'b0}}, 1'b1};
            valid_stage1 <= 1'b0;
            cnt_buf1 <= {{WIDTH-1{1'b0}}, 1'b1};
            cnt_buf2 <= {{WIDTH-1{1'b0}}, 1'b1};
        end
        else if (enable) begin
            // 使用缓冲寄存器来减少cnt的扇出负载
            cnt_stage1 <= {cnt_buf1[0], cnt_buf1[WIDTH-1:1]};
            valid_stage1 <= 1'b1;
        end
    end

    // 阶段2：缓存移位数据
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else if (enable) begin
            cnt_stage2 <= cnt_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 输出阶段：将流水线结果更新到输出
    always @(posedge clk) begin
        if (rst) begin
            cnt <= {{WIDTH-1{1'b0}}, 1'b1};
        end
        else if (enable && valid_stage2) begin
            cnt <= cnt_stage2;
        end
        else if (enable && !valid_stage2 && !valid_stage1) begin
            // 特殊情况：流水线刚启动时
            cnt <= {cnt_buf2[0], cnt_buf2[WIDTH-1:1]};
        end
    end
    
    // 更新cnt的缓冲寄存器，平衡各路径负载
    always @(posedge clk) begin
        if (rst) begin
            cnt_buf1 <= {{WIDTH-1{1'b0}}, 1'b1};
            cnt_buf2 <= {{WIDTH-1{1'b0}}, 1'b1};
        end
        else begin
            cnt_buf1 <= cnt;
            cnt_buf2 <= cnt;
        end
    end
endmodule