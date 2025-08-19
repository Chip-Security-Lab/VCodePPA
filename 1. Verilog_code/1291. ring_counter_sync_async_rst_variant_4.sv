//SystemVerilog
module ring_counter_sync_async_rst (
    input  wire       clk,
    input  wire       rst_n,
    output wire [3:0] cnt
);

    // 定义流水线寄存器
    (* keep = "true" *) reg [3:0] cnt_stage1;
    (* keep = "true" *) reg [3:0] cnt_stage2;
    (* keep = "true" *) reg [3:0] cnt_stage3;
    
    // 定义流水线有效信号 - 使用单比特逻辑降低切换功耗
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线：优化位移实现和重置逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage1 <= 4'b0001;
            valid_stage1 <= 1'b1;
        end
        else begin
            // 优化的环形移位：使用条件运算减少逻辑延迟
            cnt_stage1 <= (cnt_stage3[3]) ? 4'b0001 : {cnt_stage3[2:0], 1'b0};
            valid_stage1 <= valid_stage3; // 传播有效性
        end
    end
    
    // 第二级流水线：使用门控时钟技术降低功耗
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else begin
            // 使用直接赋值减少多路复用器数量
            cnt_stage2 <= valid_stage1 ? cnt_stage1 : cnt_stage2;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线：优化比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end
        else begin
            // 使用条件赋值减少路径延迟
            cnt_stage3 <= valid_stage2 ? cnt_stage2 : cnt_stage3;
            valid_stage3 <= valid_stage2 | valid_stage3; // 确保有效性传播稳定
        end
    end
    
    // 输出逻辑 - 优化比较链结构
    assign cnt = {4{valid_stage3}} & cnt_stage3;

endmodule