//SystemVerilog
// 顶层模块 - 带AXI4-Lite接口的16位超前进位加法器
module cla_adder_16bit_axi (
    // 全局信号
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite写地址通道
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    
    // AXI4-Lite写数据通道
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    
    // AXI4-Lite写响应通道
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite读地址通道
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    
    // AXI4-Lite读数据通道
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready
);

    // 寄存器地址映射 (字对齐)
    localparam ADDR_A_REG     = 4'h0;    // 偏移地址 0x00 - A输入寄存器
    localparam ADDR_B_REG     = 4'h4;    // 偏移地址 0x04 - B输入寄存器
    localparam ADDR_CTRL_REG  = 4'h8;    // 偏移地址 0x08 - 控制寄存器（bit 0: cin）
    localparam ADDR_RESULT_REG = 4'hC;   // 偏移地址 0x0C - 结果寄存器（bit 16: cout, bits 15-0: sum）
    
    // 内部寄存器
    reg [15:0] reg_a;
    reg [15:0] reg_b;
    reg        reg_cin;
    reg [15:0] reg_sum;
    reg        reg_cout;
    
    // AXI4-Lite接口控制信号
    reg        axi_awready;
    reg        axi_wready;
    reg        axi_bvalid;
    reg        axi_arready;
    reg [31:0] axi_rdata;
    reg        axi_rvalid;
    
    // 地址解码寄存器
    reg [3:0]  axi_awaddr_reg;
    reg [3:0]  axi_araddr_reg;
    
    // 加法器实例输出
    wire [15:0] cla_sum;
    wire        cla_cout;
    
    // 实例化16位CLA加法器
    cla_adder_16bit cla_inst (
        .a(reg_a),
        .b(reg_b),
        .cin(reg_cin),
        .sum(cla_sum),
        .cout(cla_cout)
    );
    
    // AXI输出信号赋值
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = 2'b00;        // OKAY响应
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = 2'b00;        // OKAY响应
    assign s_axi_rvalid  = axi_rvalid;
    
    // 写地址通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_awready <= 1'b0;
            axi_awaddr_reg <= 4'h0;
        end else begin
            if (~axi_awready && s_axi_awvalid) begin
                axi_awready <= 1'b1;
                axi_awaddr_reg <= s_axi_awaddr[5:2];  // 字对齐地址
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end
    
    // 写数据通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_wready <= 1'b0;
            reg_a <= 16'h0;
            reg_b <= 16'h0;
            reg_cin <= 1'b0;
        end else begin
            if (~axi_wready && s_axi_wvalid && axi_awready) begin
                axi_wready <= 1'b1;
                
                case (axi_awaddr_reg)
                    ADDR_A_REG: 
                        if (s_axi_wstrb[1:0] != 2'b00)
                            reg_a <= s_axi_wdata[15:0];
                    
                    ADDR_B_REG: 
                        if (s_axi_wstrb[1:0] != 2'b00)
                            reg_b <= s_axi_wdata[15:0];
                    
                    ADDR_CTRL_REG: 
                        if (s_axi_wstrb[0])
                            reg_cin <= s_axi_wdata[0];
                    
                    default: ; // 无操作
                endcase
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end
    
    // 写响应通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
        end else begin
            if (axi_wready && s_axi_wvalid && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end
    
    // 读地址通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_arready <= 1'b0;
            axi_araddr_reg <= 4'h0;
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
                axi_araddr_reg <= s_axi_araddr[5:2];  // 字对齐地址
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end
    
    // 读数据通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rdata <= 32'h0;
            reg_sum <= 16'h0;
            reg_cout <= 1'b0;
        end else begin
            // 在每个时钟周期更新加法器结果
            reg_sum <= cla_sum;
            reg_cout <= cla_cout;
            
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                
                case (axi_araddr_reg)
                    ADDR_A_REG:
                        axi_rdata <= {16'h0, reg_a};
                    
                    ADDR_B_REG:
                        axi_rdata <= {16'h0, reg_b};
                    
                    ADDR_CTRL_REG:
                        axi_rdata <= {31'h0, reg_cin};
                    
                    ADDR_RESULT_REG:
                        axi_rdata <= {15'h0, reg_cout, reg_sum};
                    
                    default:
                        axi_rdata <= 32'h0;
                endcase
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

endmodule

// 16位带状进位加法器模块
module cla_adder_16bit (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] sum,
    output wire        cout
);
    wire [3:0] c_out; // 每个4位块的进位输出
    
    // 实例化4个4位CLA加法器子模块
    cla_adder_4bit cla_0 (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(cin),
        .sum(sum[3:0]),
        .cout(c_out[0])
    );
    
    cla_adder_4bit cla_1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(c_out[0]),
        .sum(sum[7:4]),
        .cout(c_out[1])
    );
    
    cla_adder_4bit cla_2 (
        .a(a[11:8]),
        .b(b[11:8]),
        .cin(c_out[1]),
        .sum(sum[11:8]),
        .cout(c_out[2])
    );
    
    cla_adder_4bit cla_3 (
        .a(a[15:12]),
        .b(b[15:12]),
        .cin(c_out[2]),
        .sum(sum[15:12]),
        .cout(c_out[3])
    );
    
    assign cout = c_out[3]; // 最终进位输出
endmodule

// 4位带状进位加法器子模块
module cla_adder_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    // 优化：直接计算进位与和，减少中间信号数量，提高性能
    wire [3:0] g, p;  // 生成和传播信号
    wire [4:0] c;     // 内部进位信号
    
    // 计算生成和传播信号
    assign g = a & b;         // 生成信号
    assign p = a ^ b;         // 改为异或操作以提高精度和PPA指标
    
    // 计算进位链 - 优化版本
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);
    
    // 计算和 - 使用异或操作
    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule