module Comparator_AXIWrapper #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4
)(
    // AXI-Lite接口信号
    input                              S_AXI_ACLK,
    input                              S_AXI_ARESETN,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_AWADDR,
    input                              S_AXI_AWVALID,
    output reg                         S_AXI_AWREADY,
    input  [C_S_AXI_DATA_WIDTH-1:0]    S_AXI_WDATA,
    input                              S_AXI_WVALID,
    output reg                         S_AXI_WREADY,
    output reg [1:0]                   S_AXI_BRESP,
    output reg                         S_AXI_BVALID,
    input                              S_AXI_BREADY,
    input  [C_S_AXI_ADDR_WIDTH-1:0]    S_AXI_ARADDR,
    input                              S_AXI_ARVALID,
    output reg                         S_AXI_ARREADY,
    output reg [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0]                   S_AXI_RRESP,
    output reg                         S_AXI_RVALID,
    input                              S_AXI_RREADY,
    
    // 比较结果中断
    output reg                         irq
);
    // 寄存器定义
    reg [31:0] reg_comp_a;
    reg [31:0] reg_comp_b;
    reg        reg_ctrl;
    wire       comp_result;
    
    // 寄存器地址映射
    localparam ADDR_COMP_A = 4'h0;
    localparam ADDR_COMP_B = 4'h4;
    localparam ADDR_CTRL   = 4'h8;
    
    // 写入握手逻辑
    reg [C_S_AXI_ADDR_WIDTH-1:0] waddr;
    reg write_enable;
    
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY <= 1'b0;
            S_AXI_BVALID <= 1'b0;
            write_enable <= 1'b0;
            waddr <= 0;
        end else begin
            // 地址写入通道
            if (S_AXI_AWVALID && !S_AXI_AWREADY) begin
                S_AXI_AWREADY <= 1'b1;
                waddr <= S_AXI_AWADDR;
            end else begin
                S_AXI_AWREADY <= 1'b0;
            end
            
            // 数据写入通道
            if (S_AXI_WVALID && !S_AXI_WREADY) begin
                S_AXI_WREADY <= 1'b1;
                write_enable <= 1'b1;
            end else begin
                S_AXI_WREADY <= 1'b0;
                write_enable <= 1'b0;
            end
            
            // 写入响应通道
            if (!S_AXI_BVALID && write_enable) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP <= 2'b00; // OKAY response
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end
    
    // 读取握手逻辑
    reg [C_S_AXI_ADDR_WIDTH-1:0] raddr;
    
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RVALID <= 1'b0;
            S_AXI_RDATA <= 0;
            S_AXI_RRESP <= 0;
            raddr <= 0;
        end else begin
            // 地址读取通道
            if (S_AXI_ARVALID && !S_AXI_ARREADY) begin
                S_AXI_ARREADY <= 1'b1;
                raddr <= S_AXI_ARADDR;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end
            
            // 数据读取通道
            if (!S_AXI_RVALID && S_AXI_ARREADY) begin
                S_AXI_RVALID <= 1'b1;
                S_AXI_RRESP <= 2'b00; // OKAY response
                
                case(raddr)
                    ADDR_COMP_A: S_AXI_RDATA <= reg_comp_a;
                    ADDR_COMP_B: S_AXI_RDATA <= reg_comp_b;
                    ADDR_CTRL: S_AXI_RDATA <= {31'b0, reg_ctrl};
                    default: S_AXI_RDATA <= 32'h00000000;
                endcase
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end
    
    // 寄存器写入逻辑
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            reg_comp_a <= 32'h00000000;
            reg_comp_b <= 32'h00000000;
            reg_ctrl <= 1'b0;
        end else if (write_enable) begin
            case(waddr)
                ADDR_COMP_A: reg_comp_a <= S_AXI_WDATA;
                ADDR_COMP_B: reg_comp_b <= S_AXI_WDATA;
                ADDR_CTRL: reg_ctrl <= S_AXI_WDATA[0];
            endcase
        end
    end
    
    // 核心比较逻辑
    assign comp_result = (reg_comp_a == reg_comp_b);
    
    // 中断生成逻辑
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) 
            irq <= 1'b0;
        else                
            irq <= reg_ctrl & comp_result;
    end
endmodule