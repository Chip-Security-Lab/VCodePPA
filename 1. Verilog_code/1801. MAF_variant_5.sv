//SystemVerilog
module MAF #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n, en,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    // 定义流水线级寄存器
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [WIDTH-1:0] din_stage1;
    reg [WIDTH-1:0] out_buffer_stage1;
    reg [WIDTH+3:0] acc, acc_stage1, acc_stage2;
    reg en_stage1, en_stage2;
    integer i;

    // 第一级流水线：缓冲区移位
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0; i<DEPTH; i=i+1)
                buffer[i] <= 0;
        end else if(en) begin
            for(i=DEPTH-1; i>0; i=i-1)
                buffer[i] <= buffer[i-1];
            buffer[0] <= din;
        end
    end

    // 第一级流水线：数据暂存
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            din_stage1 <= 0;
            out_buffer_stage1 <= 0;
        end else if(en) begin
            din_stage1 <= din;
            out_buffer_stage1 <= buffer[DEPTH-1];
        end
    end

    // 第一级流水线：使能信号传递
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            en_stage1 <= 0;
        end else begin
            en_stage1 <= en;
        end
    end

    // 第一级流水线：累加器保持
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            acc <= 0;
        end else begin
            acc <= acc;
        end
    end

    // 第二级流水线：累加器更新
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            acc_stage1 <= 0;
        end else if(en_stage1) begin
            acc_stage1 <= acc + din_stage1 - out_buffer_stage1;
        end
    end

    // 第二级流水线：使能信号传递
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            en_stage2 <= 0;
        end else begin
            en_stage2 <= en_stage1;
        end
    end

    // 第三级流水线：平均值计算
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            acc_stage2 <= 0;
            dout <= 0;
        end else if(en_stage2) begin
            acc_stage2 <= acc_stage1;
            dout <= acc_stage1 / DEPTH;
        end
    end

endmodule