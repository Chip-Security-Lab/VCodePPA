//SystemVerilog
//IEEE 1364-2005
module xor2_4 (
    input wire clk,                     // 系统时钟
    input wire rst_n,                   // 复位信号，低电平有效
    
    // AXI4-Lite Slave接口
    // 写地址通道
    input wire [31:0] s_axil_awaddr,    // 写地址
    input wire [2:0] s_axil_awprot,     // 写保护类型
    input wire s_axil_awvalid,          // 写地址有效
    output reg s_axil_awready,          // 写地址就绪
    
    // 写数据通道
    input wire [31:0] s_axil_wdata,     // 写数据
    input wire [3:0] s_axil_wstrb,      // 写数据字节使能
    input wire s_axil_wvalid,           // 写数据有效
    output reg s_axil_wready,           // 写数据就绪
    
    // 写响应通道
    output reg [1:0] s_axil_bresp,      // 写响应
    output reg s_axil_bvalid,           // 写响应有效
    input wire s_axil_bready,           // 写响应就绪
    
    // 读地址通道
    input wire [31:0] s_axil_araddr,    // 读地址
    input wire [2:0] s_axil_arprot,     // 读保护类型
    input wire s_axil_arvalid,          // 读地址有效
    output reg s_axil_arready,          // 读地址就绪
    
    // 读数据通道
    output reg [31:0] s_axil_rdata,     // 读数据
    output reg [1:0] s_axil_rresp,      // 读响应
    output reg s_axil_rvalid,           // 读数据有效
    input wire s_axil_rready            // 读数据就绪
);

    // 内部寄存器
    reg [31:0] reg_A;          // 存储输入A
    reg [31:0] reg_B;          // 存储输入B
    reg [31:0] reg_Y;          // 存储输出Y
    
    // 流水线寄存器
    reg stage1_A, stage1_B;
    wire Y_result;
    
    // 写状态机状态
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    reg [1:0] write_state;
    
    // 读状态机状态
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    reg [1:0] read_state;
    
    // 寄存器地址映射
    localparam ADDR_A    = 4'h0;    // 地址0x00: 输入A
    localparam ADDR_B    = 4'h4;    // 地址0x04: 输入B
    localparam ADDR_Y    = 4'h8;    // 地址0x08: 输出Y (只读)
    
    // 保存当前地址
    reg [31:0] write_addr;
    reg [31:0] read_addr;
    
    // 写状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;    // OKAY
            write_addr <= 32'h0;
            reg_A <= 32'h0;
            reg_B <= 32'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;  // 准备接收地址
                    if (s_axil_awvalid && s_axil_awready) begin
                        write_addr <= s_axil_awaddr;
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;  // 准备接收数据
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        
                        // 根据地址写入相应寄存器
                        case (write_addr[3:0])
                            ADDR_A: begin
                                if (s_axil_wstrb[0]) reg_A[7:0] <= s_axil_wdata[7:0];
                                if (s_axil_wstrb[1]) reg_A[15:8] <= s_axil_wdata[15:8];
                                if (s_axil_wstrb[2]) reg_A[23:16] <= s_axil_wdata[23:16];
                                if (s_axil_wstrb[3]) reg_A[31:24] <= s_axil_wdata[31:24];
                            end
                            
                            ADDR_B: begin
                                if (s_axil_wstrb[0]) reg_B[7:0] <= s_axil_wdata[7:0];
                                if (s_axil_wstrb[1]) reg_B[15:8] <= s_axil_wdata[15:8];
                                if (s_axil_wstrb[2]) reg_B[23:16] <= s_axil_wdata[23:16];
                                if (s_axil_wstrb[3]) reg_B[31:24] <= s_axil_wdata[31:24];
                            end
                            
                            default: begin
                                // 其他地址不可写
                            end
                        endcase
                        
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00;  // OKAY
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        s_axil_awready <= 1'b1;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: begin
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end
    
    // 读状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;    // OKAY
            s_axil_rdata <= 32'h0;
            read_addr <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;  // 准备接收地址
                    if (s_axil_arvalid && s_axil_arready) begin
                        read_addr <= s_axil_araddr;
                        s_axil_arready <= 1'b0;
                        read_state <= READ_DATA;
                        
                        // 根据地址准备数据
                        case (s_axil_araddr[3:0])
                            ADDR_A: s_axil_rdata <= reg_A;
                            ADDR_B: s_axil_rdata <= reg_B;
                            ADDR_Y: s_axil_rdata <= reg_Y;
                            default: s_axil_rdata <= 32'h0;
                        endcase
                        
                        s_axil_rvalid <= 1'b1;
                        s_axil_rresp <= 2'b00;  // OKAY
                    end
                end
                
                READ_DATA: begin
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        s_axil_arready <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: begin
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end
    
    // XOR运算流水线实现，与原始代码功能保持一致
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
        end else begin
            stage1_A <= reg_A[0];
            stage1_B <= reg_B[0];
        end
    end
    
    // XOR结果计算
    assign Y_result = stage1_A ^ stage1_B;
    
    // 第二级：更新结果寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_Y <= 32'h0;
        end else begin
            reg_Y <= {31'h0, Y_result};  // 只使用最低位
        end
    end
    
endmodule