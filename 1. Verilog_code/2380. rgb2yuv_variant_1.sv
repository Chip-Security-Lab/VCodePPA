//SystemVerilog
//IEEE 1364-2005
module rgb2yuv (
    input wire clk,           // 时钟输入
    input wire rst_n,         // 复位信号
    input wire [7:0] r, g, b, // RGB输入
    input wire valid_in,      // 数据有效输入信号
    output wire ready_out,    // 准备接收输入数据的信号
    output wire [7:0] y, u, v, // YUV输出
    output wire valid_out,    // 输出数据有效信号
    input wire ready_in       // 下游模块准备接收数据的信号
);
    // 第一级流水线 - 预处理RGB值
    reg [7:0] r_stage1, g_stage1, b_stage1;
    
    // 第二级流水线 - 中间计算结果
    reg [15:0] y_temp_stage2, u_temp_stage2, v_temp_stage2;
    
    // 第三级流水线 - 输出缩放结果
    reg [15:0] y_temp_stage3, u_temp_stage3, v_temp_stage3;
    
    // 最终输出寄存器
    reg [7:0] y_reg, u_reg, v_reg;
    
    // 流水线各级有效信号
    reg valid_stage1, valid_stage2, valid_stage3, valid_out_reg;
    
    // 流水线阻塞控制
    wire stall;
    
    // 常量系数 - 提高代码可读性
    localparam [7:0] Y_COEF_R = 8'd66;
    localparam [7:0] Y_COEF_G = 8'd129;
    localparam [7:0] Y_COEF_B = 8'd25;
    
    localparam [7:0] U_COEF_R = 8'd38;  // 使用正值，计算时减去
    localparam [7:0] U_COEF_G = 8'd74;  // 使用正值，计算时减去
    localparam [7:0] U_COEF_B = 8'd112;
    
    localparam [7:0] V_COEF_R = 8'd112;
    localparam [7:0] V_COEF_G = 8'd94;  // 使用正值，计算时减去
    localparam [7:0] V_COEF_B = 8'd18;  // 使用正值，计算时减去
    
    localparam [7:0] OFFSET = 8'd128;   // 偏移常量
    
    // 阻塞信号生成 - 当输出有效但下游未准备好接收时，流水线阻塞
    assign stall = valid_out_reg && !ready_in;
    
    // 准备接收新数据的条件 - 没有阻塞时可以接收新数据
    assign ready_out = !stall;
    
    // 输出连接
    assign y = y_reg;
    assign u = u_reg;
    assign v = v_reg;
    assign valid_out = valid_out_reg;
    
    // 流水线阶段1：寄存输入RGB
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_stage1 <= 8'd0;
            g_stage1 <= 8'd0;
            b_stage1 <= 8'd0;
            valid_stage1 <= 1'b0;
        end else if (!stall) begin
            r_stage1 <= r;
            g_stage1 <= g;
            b_stage1 <= b;
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线阶段2：计算YUV中间值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_temp_stage2 <= 16'd0;
            u_temp_stage2 <= 16'd0;
            v_temp_stage2 <= 16'd0;
            valid_stage2 <= 1'b0;
        end else if (!stall) begin
            // Y分量计算: Y = 0.257*R + 0.504*G + 0.098*B + 16
            y_temp_stage2 <= Y_COEF_R * r_stage1 + Y_COEF_G * g_stage1 + Y_COEF_B * b_stage1 + OFFSET;
            
            // U分量计算: U = -0.148*R - 0.291*G + 0.439*B + 128
            u_temp_stage2 <= OFFSET + U_COEF_B * b_stage1 - U_COEF_R * r_stage1 - U_COEF_G * g_stage1;
            
            // V分量计算: V = 0.439*R - 0.368*G - 0.071*B + 128
            v_temp_stage2 <= OFFSET + V_COEF_R * r_stage1 - V_COEF_G * g_stage1 - V_COEF_B * b_stage1;
            
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线阶段3：缓存中间结果进行偶数级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_temp_stage3 <= 16'd0;
            u_temp_stage3 <= 16'd0;
            v_temp_stage3 <= 16'd0;
            valid_stage3 <= 1'b0;
        end else if (!stall) begin
            y_temp_stage3 <= y_temp_stage2;
            u_temp_stage3 <= u_temp_stage2;
            v_temp_stage3 <= v_temp_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 流水线阶段4：最终输出缩放
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_reg <= 8'd0;
            u_reg <= 8'd0;
            v_reg <= 8'd0;
            valid_out_reg <= 1'b0;
        end else if (!stall) begin
            // 通过右移8位进行缩放 (除以256)
            y_reg <= y_temp_stage3 >> 8;
            u_reg <= u_temp_stage3 >> 8;
            v_reg <= v_temp_stage3 >> 8;
            valid_out_reg <= valid_stage3;
        end else if (ready_in) begin
            // 当下游准备好接收但流水线阻塞时，清除输出有效信号
            valid_out_reg <= 1'b0;
        end
    end
    
endmodule