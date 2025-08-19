//SystemVerilog
//IEEE 1364-2005 SystemVerilog
// 顶层模块
module rgb_async_convert (
    // AXI-Stream输入接口
    input wire clk,
    input wire rst_n,
    input wire [23:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream输出接口
    output wire [15:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);
    // 各颜色通道信号
    wire [4:0] red_component;
    wire [5:0] green_component;
    wire [4:0] blue_component;
    wire [15:0] rgb565_internal;
    
    // 控制信号
    reg data_valid;
    
    // 设置输入准备好信号
    assign s_axis_tready = m_axis_tready;
    
    // 数据有效性控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_valid <= 1'b0;
        else if (s_axis_tvalid && s_axis_tready)
            data_valid <= 1'b1;
        else if (m_axis_tready)
            data_valid <= 1'b0;
    end
    
    // 输出有效信号
    assign m_axis_tvalid = data_valid;
    
    // 子模块实例化
    red_channel_extract red_extract (
        .rgb888_red(s_axis_tdata[23:16]),
        .rgb565_red(red_component)
    );

    green_channel_extract green_extract (
        .rgb888_green(s_axis_tdata[15:8]),
        .rgb565_green(green_component)
    );

    blue_channel_extract blue_extract (
        .rgb888_blue(s_axis_tdata[7:0]),
        .rgb565_blue(blue_component)
    );

    // 颜色分量组合
    color_combine combiner (
        .red(red_component),
        .green(green_component),
        .blue(blue_component),
        .rgb565(rgb565_internal)
    );
    
    // 输出数据寄存
    reg [15:0] rgb565_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rgb565_reg <= 16'b0;
        else if (s_axis_tvalid && s_axis_tready)
            rgb565_reg <= rgb565_internal;
    end
    
    assign m_axis_tdata = rgb565_reg;
    
endmodule

// 红色通道提取子模块
module red_channel_extract (
    input [7:0] rgb888_red,
    output [4:0] rgb565_red
);
    // 提取高5位
    assign rgb565_red = rgb888_red[7:3];
endmodule

// 绿色通道提取子模块
module green_channel_extract (
    input [7:0] rgb888_green,
    output [5:0] rgb565_green
);
    // 提取高6位
    assign rgb565_green = rgb888_green[7:2];
endmodule

// 蓝色通道提取子模块
module blue_channel_extract (
    input [7:0] rgb888_blue,
    output [4:0] rgb565_blue
);
    // 提取高5位
    assign rgb565_blue = rgb888_blue[7:3];
endmodule

// 颜色组合子模块
module color_combine (
    input [4:0] red,
    input [5:0] green,
    input [4:0] blue,
    output [15:0] rgb565
);
    // 将各颜色通道组合成RGB565格式
    assign rgb565 = {red, green, blue};
endmodule