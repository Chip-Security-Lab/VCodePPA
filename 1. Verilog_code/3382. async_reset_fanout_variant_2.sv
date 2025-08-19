//SystemVerilog
module async_reset_fanout (
    input  wire        clk,           // 系统时钟
    input  wire        async_rst_in,  // 输入异步复位信号
    output wire [15:0] rst_out        // 输出复位信号组
);

    // 第一级复位缓冲
    reg rst_buf1;
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in)
            rst_buf1 <= 1'b1;
        else
            rst_buf1 <= 1'b0;
    end

    // 第二级复位分配 - 为rst_buf1添加缓冲以减少扇出
    reg rst_buf1_a, rst_buf1_b;
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            rst_buf1_a <= 1'b1;
            rst_buf1_b <= 1'b1;
        end
        else begin
            rst_buf1_a <= rst_buf1;
            rst_buf1_b <= rst_buf1;
        end
    end

    // 第三级复位分配 - 将复位信号分为4组，使用缓冲后的rst_buf1信号
    reg [1:0] rst_group_a, rst_group_b;
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            rst_group_a <= 2'b11;
            rst_group_b <= 2'b11;
        end
        else begin
            rst_group_a <= {2{rst_buf1_a}};
            rst_group_b <= {2{rst_buf1_b}};
        end
    end

    // 为4组复位信号添加缓冲以减少扇出负载
    reg [3:0] rst_group_buf;
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in)
            rst_group_buf <= 4'hF;
        else begin
            rst_group_buf[1:0] <= rst_group_a;
            rst_group_buf[3:2] <= rst_group_b;
        end
    end

    // 第四级复位扇出 - 为每组复位信号添加专用的寄存器以平衡负载
    reg [3:0] rst_fanout_reg0, rst_fanout_reg1, rst_fanout_reg2, rst_fanout_reg3;
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            rst_fanout_reg0 <= 4'hF;
            rst_fanout_reg1 <= 4'hF;
            rst_fanout_reg2 <= 4'hF;
            rst_fanout_reg3 <= 4'hF;
        end
        else begin
            rst_fanout_reg0 <= {4{rst_group_buf[0]}};
            rst_fanout_reg1 <= {4{rst_group_buf[1]}};
            rst_fanout_reg2 <= {4{rst_group_buf[2]}};
            rst_fanout_reg3 <= {4{rst_group_buf[3]}};
        end
    end

    // 输出复位信号 - 组合最终输出
    assign rst_out = {rst_fanout_reg3, rst_fanout_reg2, rst_fanout_reg1, rst_fanout_reg0};

endmodule