//SystemVerilog
module MAF #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n, en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [WIDTH+3:0] acc;
    integer i;
    
    // 为高扇出信号添加缓冲寄存器
    reg [WIDTH-1:0] din_buf1, din_buf2;
    reg en_buf1, en_buf2;
    reg [WIDTH-1:0] buffer_last_buf;
    reg [WIDTH+3:0] acc_stage1, acc_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            din_buf1 <= 0;
            din_buf2 <= 0;
            en_buf1 <= 0;
            en_buf2 <= 0;
            buffer_last_buf <= 0;
        end else begin
            // 输入信号缓冲
            din_buf1 <= din;
            din_buf2 <= din_buf1;
            en_buf1 <= en;
            en_buf2 <= en_buf1;
            // 末尾缓冲区元素的缓冲
            buffer_last_buf <= buffer[DEPTH-1];
        end
    end
    
    // 分段计算累加器逻辑，减少关键路径延迟
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            acc_stage1 <= 0;
            acc_stage2 <= 0;
            acc <= 0;
        end else if(en_buf2) begin
            // 第一级：添加新输入
            acc_stage1 <= acc + din_buf2;
            // 第二级：减去最旧的值
            acc_stage2 <= acc_stage1 - buffer_last_buf;
            // 最终累加值
            acc <= acc_stage2;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout <= 0;
            for(i=0; i<DEPTH; i=i+1)
                buffer[i] <= 0;
        end else if(en_buf2) begin
            // 手动移位缓冲区，使用缓冲后的输入
            for(i=DEPTH-1; i>0; i=i-1)
                buffer[i] <= buffer[i-1];
            buffer[0] <= din_buf2;
            
            // 对于2的幂DEPTH，这将合成为移位
            dout <= acc_stage2 / DEPTH;
        end
    end
endmodule