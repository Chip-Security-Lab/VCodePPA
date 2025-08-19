//SystemVerilog
module redun_logic_xnor_axi (
    // 全局信号
    input wire aclk,             // AXI时钟
    input wire aresetn,          // AXI异步复位（低电平有效）

    // AXI4-Lite 写地址通道信号
    input wire [31:0] s_axil_awaddr,     // 写地址
    input wire [2:0] s_axil_awprot,      // 写保护类型
    input wire s_axil_awvalid,           // 写地址有效
    output reg s_axil_awready,           // 写地址准备好

    // AXI4-Lite 写数据通道信号
    input wire [31:0] s_axil_wdata,      // 写数据
    input wire [3:0] s_axil_wstrb,       // 写数据字节使能
    input wire s_axil_wvalid,            // 写数据有效
    output reg s_axil_wready,            // 写数据准备好

    // AXI4-Lite 写响应通道信号
    output reg [1:0] s_axil_bresp,       // 写响应
    output reg s_axil_bvalid,            // 写响应有效
    input wire s_axil_bready,            // 主设备准备好接收写响应

    // AXI4-Lite 读地址通道信号
    input wire [31:0] s_axil_araddr,     // 读地址
    input wire [2:0] s_axil_arprot,      // 读保护类型
    input wire s_axil_arvalid,           // 读地址有效
    output reg s_axil_arready,           // 读地址准备好

    // AXI4-Lite 读数据通道信号
    output reg [31:0] s_axil_rdata,      // 读数据
    output reg [1:0] s_axil_rresp,       // 读响应
    output reg s_axil_rvalid,            // 读数据有效
    input wire s_axil_rready             // 主设备准备好接收读数据
);

    // 内部寄存器定义
    reg [31:0] control_reg;      // 控制寄存器 - 地址0x00
    reg [31:0] status_reg;       // 状态寄存器 - 地址0x04
    reg [31:0] input_reg;        // 输入寄存器 - 地址0x08
    reg [31:0] output_reg;       // 输出寄存器 - 地址0x0C

    // 地址解码参数
    localparam ADDR_CONTROL = 32'h00;
    localparam ADDR_STATUS  = 32'h04;
    localparam ADDR_INPUT   = 32'h08;
    localparam ADDR_OUTPUT  = 32'h0C;

    // AXI响应码
    localparam RESP_OKAY    = 2'b00;  // 正常访问成功
    localparam RESP_SLVERR  = 2'b10;  // 从机错误

    // 状态机状态
    localparam IDLE           = 2'b00;
    localparam WRITE_DATA     = 2'b01;
    localparam WRITE_RESPONSE = 2'b10;
    localparam READ_DATA      = 2'b11;
    
    reg [1:0] write_state;
    reg [1:0] read_state;
    
    // 存储接受的地址
    reg [31:0] write_addr;
    reg [31:0] read_addr;

    // 原始模块所需的信号
    wire a, b, c, d;
    reg y;
    
    // 使用本地参数明确标识信号处理阶段
    localparam STAGE_FIRST_PAIR = 1;
    localparam STAGE_SECOND_PAIR = 2;
    localparam STAGE_FINAL_RESULT = 3;

    // 第一阶段：计算第一对输入的XOR结果
    reg first_pair_xor;
    // 第二阶段：计算第二对输入的XOR结果  
    reg second_pair_xor;
    // 保存中间结果的寄存器
    reg combined_xor;

    // 从输入寄存器映射到原始模块的输入
    assign a = input_reg[0];
    assign b = input_reg[1];
    assign c = input_reg[2];
    assign d = input_reg[3];

    // 写状态机
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
            write_addr <= 32'h0;
            
            // 初始化寄存器
            control_reg <= 32'h0;
            input_reg <= 32'h0;
        end else begin
            case (write_state)
                IDLE: begin
                    // 等待有效的写地址
                    if (s_axil_awvalid && !s_axil_awready) begin
                        s_axil_awready <= 1'b1;
                        write_addr <= s_axil_awaddr;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    // 清除写地址准备信号
                    s_axil_awready <= 1'b0;
                    
                    // 等待有效的写数据
                    if (s_axil_wvalid && !s_axil_wready) begin
                        s_axil_wready <= 1'b1;
                        
                        // 解码地址并写入相应的寄存器
                        case (write_addr & 32'hFF)
                            ADDR_CONTROL: begin
                                // 写入控制寄存器
                                if (s_axil_wstrb[0]) control_reg[7:0] <= s_axil_wdata[7:0];
                                if (s_axil_wstrb[1]) control_reg[15:8] <= s_axil_wdata[15:8];
                                if (s_axil_wstrb[2]) control_reg[23:16] <= s_axil_wdata[23:16];
                                if (s_axil_wstrb[3]) control_reg[31:24] <= s_axil_wdata[31:24];
                                s_axil_bresp <= RESP_OKAY;
                            end
                            
                            ADDR_INPUT: begin
                                // 写入输入寄存器
                                if (s_axil_wstrb[0]) input_reg[7:0] <= s_axil_wdata[7:0];
                                if (s_axil_wstrb[1]) input_reg[15:8] <= s_axil_wdata[15:8];
                                if (s_axil_wstrb[2]) input_reg[23:16] <= s_axil_wdata[23:16];
                                if (s_axil_wstrb[3]) input_reg[31:24] <= s_axil_wdata[31:24];
                                s_axil_bresp <= RESP_OKAY;
                            end
                            
                            default: begin
                                // 地址错误
                                s_axil_bresp <= RESP_SLVERR;
                            end
                        endcase
                        
                        write_state <= WRITE_RESPONSE;
                    end
                end
                
                WRITE_RESPONSE: begin
                    // 清除写数据准备信号
                    s_axil_wready <= 1'b0;
                    
                    // 产生写响应
                    s_axil_bvalid <= 1'b1;
                    
                    // 等待主机接收响应
                    if (s_axil_bvalid && s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                default: begin
                    write_state <= IDLE;
                end
            endcase
        end
    end

    // 读状态机
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= RESP_OKAY;
            s_axil_rdata <= 32'h0;
            read_addr <= 32'h0;
        end else begin
            case (read_state)
                IDLE: begin
                    // 等待有效的读地址
                    if (s_axil_arvalid && !s_axil_arready) begin
                        s_axil_arready <= 1'b1;
                        read_addr <= s_axil_araddr;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    // 清除读地址准备信号
                    s_axil_arready <= 1'b0;
                    
                    // 解码地址并读取相应的寄存器
                    case (read_addr & 32'hFF)
                        ADDR_CONTROL: begin
                            s_axil_rdata <= control_reg;
                            s_axil_rresp <= RESP_OKAY;
                        end
                        
                        ADDR_STATUS: begin
                            s_axil_rdata <= status_reg;
                            s_axil_rresp <= RESP_OKAY;
                        end
                        
                        ADDR_INPUT: begin
                            s_axil_rdata <= input_reg;
                            s_axil_rresp <= RESP_OKAY;
                        end
                        
                        ADDR_OUTPUT: begin
                            s_axil_rdata <= output_reg;
                            s_axil_rresp <= RESP_OKAY;
                        end
                        
                        default: begin
                            s_axil_rdata <= 32'h0;
                            s_axil_rresp <= RESP_SLVERR;
                        end
                    endcase
                    
                    // 设置数据有效
                    s_axil_rvalid <= 1'b1;
                    
                    // 等待主机接收数据
                    if (s_axil_rvalid && s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: begin
                    read_state <= IDLE;
                end
            endcase
        end
    end

    // 原始模块的核心逻辑 - 第一级流水线
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            first_pair_xor <= 1'b0;
            second_pair_xor <= 1'b0;
        end else if (control_reg[0]) begin  // 使能位
            // 分割数据路径，先计算a^b和c^d
            first_pair_xor <= a ^ b;
            second_pair_xor <= c ^ d;
        end
    end

    // 原始模块的核心逻辑 - 第二级流水线
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            combined_xor <= 1'b0;
        end else if (control_reg[0]) begin  // 使能位
            // 计算(a^b)^(c^d)
            combined_xor <= first_pair_xor ^ second_pair_xor;
        end
    end

    // 原始模块的核心逻辑 - 第三级流水线
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            y <= 1'b0;
        end else if (control_reg[0]) begin  // 使能位
            // 最终结果是XOR结果的取反
            y <= ~combined_xor;
        end
    end
    
    // 更新状态和输出寄存器
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            status_reg <= 32'h0;
            output_reg <= 32'h0;
        end else begin
            // 状态寄存器指示计算完成
            status_reg <= {31'b0, control_reg[0]};
            
            // 更新输出寄存器
            output_reg <= {31'b0, y};
        end
    end

endmodule