//SystemVerilog
module sync_single_port_ram_with_bandwidth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire bandwidth_control,  // 带宽控制信号
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 添加带宽控制信号的缓冲寄存器
    reg bandwidth_control_buf;
    
    // 添加地址信号的缓冲寄存器
    reg [ADDR_WIDTH-1:0] addr_buf;
    
    // 添加写使能信号的缓冲寄存器
    reg we_buf;
    
    // 添加数据输入信号的缓冲寄存器
    reg [DATA_WIDTH-1:0] din_buf;
    
    // 添加RAM输出数据的缓冲寄存器
    reg [DATA_WIDTH-1:0] ram_data_buf;
    
    // 并行前缀减法器相关信号
    reg [DATA_WIDTH-1:0] a, b;  // 减法操作数
    reg [DATA_WIDTH-1:0] diff;  // 减法结果
    reg [DATA_WIDTH-1:0] borrow;  // 借位信号
    
    // 并行前缀减法器的传播和生成信号
    reg [DATA_WIDTH-1:0] p, g;  // 传播和生成信号
    reg [DATA_WIDTH-1:0] p_level1, g_level1;  // 第一级前缀
    reg [DATA_WIDTH-1:0] p_level2, g_level2;  // 第二级前缀
    reg [DATA_WIDTH-1:0] p_level3, g_level3;  // 第三级前缀
    reg [DATA_WIDTH-1:0] final_borrow;  // 最终借位

    // 第一级缓冲寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bandwidth_control_buf <= 1'b0;
            addr_buf <= {ADDR_WIDTH{1'b0}};
            we_buf <= 1'b0;
            din_buf <= {DATA_WIDTH{1'b0}};
            a <= {DATA_WIDTH{1'b0}};
            b <= {DATA_WIDTH{1'b0}};
        end else begin
            bandwidth_control_buf <= bandwidth_control;
            addr_buf <= addr;
            we_buf <= we;
            din_buf <= din;
            a <= din;  // 使用输入数据作为减法操作数a
            b <= ram_data_buf;  // 使用RAM数据作为减法操作数b
        end
    end

    // RAM访问逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_buf <= {DATA_WIDTH{1'b0}};
        end else begin
            if (bandwidth_control_buf) begin
                if (we_buf) ram[addr_buf] <= din_buf;
                ram_data_buf <= ram[addr_buf];
            end
        end
    end
    
    // 并行前缀减法器实现
    always @(*) begin
        // 计算传播和生成信号
        for (int i = 0; i < DATA_WIDTH; i++) begin
            p[i] = a[i] ^ b[i];  // 传播信号
            g[i] = a[i] & ~b[i];  // 生成信号
        end
        
        // 第一级前缀计算
        p_level1[0] = p[0];
        g_level1[0] = g[0];
        
        for (int i = 1; i < DATA_WIDTH; i++) begin
            p_level1[i] = p[i] & p[i-1];
            g_level1[i] = g[i] | (p[i] & g[i-1]);
        end
        
        // 第二级前缀计算
        p_level2[0] = p_level1[0];
        g_level2[0] = g_level1[0];
        
        p_level2[1] = p_level1[1];
        g_level2[1] = g_level1[1];
        
        for (int i = 2; i < DATA_WIDTH; i++) begin
            p_level2[i] = p_level1[i] & p_level1[i-2];
            g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
        end
        
        // 第三级前缀计算
        p_level3[0] = p_level2[0];
        g_level3[0] = g_level2[0];
        
        p_level3[1] = p_level2[1];
        g_level3[1] = g_level2[1];
        
        p_level3[2] = p_level2[2];
        g_level3[2] = g_level2[2];
        
        p_level3[3] = p_level2[3];
        g_level3[3] = g_level2[3];
        
        for (int i = 4; i < DATA_WIDTH; i++) begin
            p_level3[i] = p_level2[i] & p_level2[i-4];
            g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
        end
        
        // 计算最终借位
        final_borrow[0] = g_level3[0];
        for (int i = 1; i < DATA_WIDTH; i++) begin
            final_borrow[i] = g_level3[i] | (p_level3[i] & final_borrow[i-1]);
        end
        
        // 计算差值
        diff[0] = a[0] ^ b[0] ^ 1'b0;  // 初始借位为0
        for (int i = 1; i < DATA_WIDTH; i++) begin
            diff[i] = a[i] ^ b[i] ^ final_borrow[i-1];
        end
    end

    // 输出数据缓冲
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= {DATA_WIDTH{1'b0}};
        end else begin
            if (bandwidth_control_buf) begin
                dout <= diff;  // 输出减法结果而不是RAM数据
            end
        end
    end
endmodule