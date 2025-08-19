//SystemVerilog
// 顶层模块
module Comparator_AXIWrapper #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4
)(
    // AXI-Lite接口信号
    input                              S_AXI_ACLK,
    input                              S_AXI_ARESETN,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_AWADDR,
    input                              S_AXI_AWVALID,
    output                             S_AXI_AWREADY,
    input  [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_WDATA,
    input                              S_AXI_WVALID,
    output                             S_AXI_WREADY,
    output [1:0]                       S_AXI_BRESP,
    output                             S_AXI_BVALID,
    input                              S_AXI_BREADY,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_ARADDR,
    input                              S_AXI_ARVALID,
    output                             S_AXI_ARREADY,
    output [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_RDATA,
    output [1:0]                       S_AXI_RRESP,
    output                             S_AXI_RVALID,
    input                              S_AXI_RREADY,
    
    // 比较结果中断
    output                             irq
);
    // 寄存器地址映射
    localparam ADDR_COMP_A = 4'h0;
    localparam ADDR_COMP_B = 4'h4;
    localparam ADDR_CTRL   = 4'h8;
    
    // 内部连线
    wire [31:0] reg_comp_a;
    wire [31:0] reg_comp_b;
    wire        reg_ctrl;
    wire        comp_result;
    wire        write_enable;
    wire [C_S_AXI_ADDR_WIDTH-1:0] waddr;
    wire [C_S_AXI_ADDR_WIDTH-1:0] raddr;
    
    // AXI写控制模块实例化
    AXI_Write_Controller #(
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
    ) write_ctrl_inst (
        .clk(S_AXI_ACLK),
        .resetn(S_AXI_ARESETN),
        .s_axi_awvalid(S_AXI_AWVALID),
        .s_axi_awready(S_AXI_AWREADY),
        .s_axi_awaddr(S_AXI_AWADDR),
        .s_axi_wvalid(S_AXI_WVALID),
        .s_axi_wready(S_AXI_WREADY),
        .s_axi_bvalid(S_AXI_BVALID),
        .s_axi_bresp(S_AXI_BRESP),
        .s_axi_bready(S_AXI_BREADY),
        .write_enable(write_enable),
        .waddr(waddr)
    );
    
    // AXI读控制模块实例化
    AXI_Read_Controller #(
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)
    ) read_ctrl_inst (
        .clk(S_AXI_ACLK),
        .resetn(S_AXI_ARESETN),
        .s_axi_arvalid(S_AXI_ARVALID),
        .s_axi_arready(S_AXI_ARREADY),
        .s_axi_araddr(S_AXI_ARADDR),
        .s_axi_rvalid(S_AXI_RVALID),
        .s_axi_rready(S_AXI_RREADY),
        .s_axi_rdata(S_AXI_RDATA),
        .s_axi_rresp(S_AXI_RRESP),
        .raddr(raddr),
        .reg_comp_a(reg_comp_a),
        .reg_comp_b(reg_comp_b),
        .reg_ctrl(reg_ctrl),
        .ADDR_COMP_A(ADDR_COMP_A),
        .ADDR_COMP_B(ADDR_COMP_B),
        .ADDR_CTRL(ADDR_CTRL)
    );
    
    // 寄存器模块实例化
    Register_Bank register_inst (
        .clk(S_AXI_ACLK),
        .resetn(S_AXI_ARESETN),
        .write_enable(write_enable),
        .waddr(waddr),
        .wdata(S_AXI_WDATA),
        .reg_comp_a(reg_comp_a),
        .reg_comp_b(reg_comp_b),
        .reg_ctrl(reg_ctrl),
        .ADDR_COMP_A(ADDR_COMP_A),
        .ADDR_COMP_B(ADDR_COMP_B),
        .ADDR_CTRL(ADDR_CTRL)
    );
    
    // 比较器和中断控制模块实例化
    Comparator_IRQ_Controller comp_irq_inst (
        .clk(S_AXI_ACLK),
        .resetn(S_AXI_ARESETN),
        .reg_comp_a(reg_comp_a),
        .reg_comp_b(reg_comp_b),
        .reg_ctrl(reg_ctrl),
        .comp_result(comp_result),
        .irq(irq)
    );
    
endmodule

// AXI写控制模块
module AXI_Write_Controller #(
    parameter C_S_AXI_ADDR_WIDTH = 4
)(
    input                              clk,
    input                              resetn,
    input                              s_axi_awvalid,
    output reg                         s_axi_awready,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
    input                              s_axi_wvalid,
    output reg                         s_axi_wready,
    output reg                         s_axi_bvalid,
    output reg [1:0]                   s_axi_bresp,
    input                              s_axi_bready,
    output reg                         write_enable,
    output reg [C_S_AXI_ADDR_WIDTH-1:0] waddr
);
    
    // 流水线寄存器
    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_stage1;
    reg awvalid_stage1;
    reg wvalid_stage1;
    reg write_enable_stage1;
    
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            write_enable <= 1'b0;
            waddr <= 0;
            awaddr_stage1 <= 0;
            awvalid_stage1 <= 1'b0;
            wvalid_stage1 <= 1'b0;
            write_enable_stage1 <= 1'b0;
        end else begin
            // 第一阶段：地址和数据有效信号处理
            awaddr_stage1 <= s_axi_awaddr;
            awvalid_stage1 <= s_axi_awvalid;
            wvalid_stage1 <= s_axi_wvalid;
            
            // 第二阶段：地址写入通道
            if (awvalid_stage1 && !s_axi_awready) begin
                s_axi_awready <= 1'b1;
                waddr <= awaddr_stage1;
            end else begin
                s_axi_awready <= 1'b0;
            end
            
            // 第三阶段：数据写入通道
            if (wvalid_stage1 && !s_axi_wready) begin
                s_axi_wready <= 1'b1;
                write_enable_stage1 <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
                write_enable_stage1 <= 1'b0;
            end
            
            // 第四阶段：写入使能和响应
            write_enable <= write_enable_stage1;
            
            if (!s_axi_bvalid && write_enable_stage1) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00; // OKAY response
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
endmodule

// AXI读控制模块
module AXI_Read_Controller #(
    parameter C_S_AXI_ADDR_WIDTH = 4,
    parameter C_S_AXI_DATA_WIDTH = 32
)(
    input                              clk,
    input                              resetn,
    input                              s_axi_arvalid,
    output reg                         s_axi_arready,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    s_axi_araddr,
    output reg                         s_axi_rvalid,
    input                              s_axi_rready,
    output reg [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg [1:0]                   s_axi_rresp,
    output reg [C_S_AXI_ADDR_WIDTH-1:0] raddr,
    input  [31:0]                      reg_comp_a,
    input  [31:0]                      reg_comp_b,
    input                              reg_ctrl,
    input  [3:0]                       ADDR_COMP_A,
    input  [3:0]                       ADDR_COMP_B,
    input  [3:0]                       ADDR_CTRL
);
    
    // 流水线寄存器
    reg [C_S_AXI_ADDR_WIDTH-1:0] araddr_stage1;
    reg arvalid_stage1;
    reg [C_S_AXI_ADDR_WIDTH-1:0] raddr_stage2;
    reg [C_S_AXI_DATA_WIDTH-1:0] rdata_stage2;
    reg rvalid_stage2;
    
    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 0;
            s_axi_rresp <= 0;
            raddr <= 0;
            araddr_stage1 <= 0;
            arvalid_stage1 <= 1'b0;
            raddr_stage2 <= 0;
            rdata_stage2 <= 0;
            rvalid_stage2 <= 1'b0;
        end else begin
            // 第一阶段：地址有效信号处理
            araddr_stage1 <= s_axi_araddr;
            arvalid_stage1 <= s_axi_arvalid;
            
            // 第二阶段：地址读取通道
            if (arvalid_stage1 && !s_axi_arready) begin
                s_axi_arready <= 1'b1;
                raddr_stage2 <= araddr_stage1;
            end else begin
                s_axi_arready <= 1'b0;
            end
            
            // 第三阶段：数据准备
            if (!rvalid_stage2 && s_axi_arready) begin
                rvalid_stage2 <= 1'b1;
                raddr <= raddr_stage2;
                
                case(raddr_stage2)
                    ADDR_COMP_A: rdata_stage2 <= reg_comp_a;
                    ADDR_COMP_B: rdata_stage2 <= reg_comp_b;
                    ADDR_CTRL: rdata_stage2 <= {31'b0, reg_ctrl};
                    default: rdata_stage2 <= 32'h00000000;
                endcase
            end
            
            // 第四阶段：数据读取通道
            if (!s_axi_rvalid && rvalid_stage2) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata <= rdata_stage2;
                s_axi_rresp <= 2'b00; // OKAY response
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                rvalid_stage2 <= 1'b0;
            end
        end
    end
    
endmodule

// 寄存器模块
module Register_Bank (
    input                              clk,
    input                              resetn,
    input                              write_enable,
    input  [3:0]                       waddr,
    input  [31:0]                      wdata,
    output reg [31:0]                  reg_comp_a,
    output reg [31:0]                  reg_comp_b,
    output reg                         reg_ctrl,
    input  [3:0]                       ADDR_COMP_A,
    input  [3:0]                       ADDR_COMP_B,
    input  [3:0]                       ADDR_CTRL
);
    
    // 流水线寄存器
    reg [3:0] waddr_stage1;
    reg [31:0] wdata_stage1;
    reg write_enable_stage1;
    
    always @(posedge clk) begin
        if (!resetn) begin
            reg_comp_a <= 32'h00000000;
            reg_comp_b <= 32'h00000000;
            reg_ctrl <= 1'b0;
            waddr_stage1 <= 0;
            wdata_stage1 <= 0;
            write_enable_stage1 <= 1'b0;
        end else begin
            // 第一阶段：输入寄存器
            waddr_stage1 <= waddr;
            wdata_stage1 <= wdata;
            write_enable_stage1 <= write_enable;
            
            // 第二阶段：寄存器写入
            if (write_enable_stage1) begin
                case(waddr_stage1)
                    ADDR_COMP_A: reg_comp_a <= wdata_stage1;
                    ADDR_COMP_B: reg_comp_b <= wdata_stage1;
                    ADDR_CTRL: reg_ctrl <= wdata_stage1[0];
                endcase
            end
        end
    end
    
endmodule

// 比较器和中断控制模块
module Comparator_IRQ_Controller (
    input                              clk,
    input                              resetn,
    input  [31:0]                      reg_comp_a,
    input  [31:0]                      reg_comp_b,
    input                              reg_ctrl,
    output                             comp_result,
    output reg                         irq
);
    
    // 流水线寄存器
    reg [31:0] comp_a_stage1;
    reg [31:0] comp_b_stage1;
    reg ctrl_stage1;
    reg comp_result_stage1;
    reg comp_result_stage2;
    
    always @(posedge clk) begin
        if (!resetn) begin
            comp_a_stage1 <= 0;
            comp_b_stage1 <= 0;
            ctrl_stage1 <= 1'b0;
            comp_result_stage1 <= 1'b0;
            comp_result_stage2 <= 1'b0;
            irq <= 1'b0;
        end else begin
            // 第一阶段：输入寄存器
            comp_a_stage1 <= reg_comp_a;
            comp_b_stage1 <= reg_comp_b;
            ctrl_stage1 <= reg_ctrl;
            
            // 第二阶段：比较运算
            comp_result_stage1 <= (comp_a_stage1 == comp_b_stage1);
            
            // 第三阶段：结果寄存
            comp_result_stage2 <= comp_result_stage1;
            
            // 第四阶段：中断生成
            irq <= ctrl_stage1 & comp_result_stage2;
        end
    end
    
    assign comp_result = comp_result_stage2;
    
endmodule