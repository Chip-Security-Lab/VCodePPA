//SystemVerilog
//IEEE 1364-2005 Verilog
module one_hot_counter_axi (
    // Clock and Reset
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready
);

    // 内部寄存器
    reg [7:0] one_hot;
    reg [1:0] control_reg;  // 控制寄存器: [0] - 使能, [1] - 软复位
    
    // 寄存器地址映射 (字节寻址)
    localparam ADDR_ONE_HOT     = 4'h0;  // 0x00: one_hot寄存器
    localparam ADDR_CONTROL     = 4'h4;  // 0x04: 控制寄存器
    
    // AXI4-Lite响应代码
    localparam RESP_OKAY        = 2'b00;
    localparam RESP_SLVERR      = 2'b10;
    
    // 写事务控制状态机 - 混合编码
    // 常用状态使用独热编码，不常用状态使用二进制编码
    // 独热编码部分
    localparam WRITE_IDLE       = 4'b0001;  // 最常用状态，使用独热编码
    localparam WRITE_RESP       = 4'b0010;  // 常用状态，使用独热编码
    // 二进制编码部分
    localparam WRITE_ADDR_FIRST = 4'b0100;  // 不太常用，使用紧凑编码
    localparam WRITE_DATA_FIRST = 4'b1000;  // 不太常用，使用紧凑编码
    
    reg [3:0] write_state;
    reg [3:0] write_addr;
    reg write_addr_valid;
    reg [31:0] write_data;
    reg [3:0] write_strb;
    reg write_data_valid;
    
    // 读事务控制状态机 - 混合编码
    // 由于状态较少，使用独热编码
    localparam READ_IDLE        = 2'b01;
    localparam READ_DATA        = 2'b10;
    
    reg [1:0] read_state;
    reg [3:0] read_addr;
    
    // One-hot计数器逻辑
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn || control_reg[1]) begin
            // 复位或软复位
            one_hot <= 8'b00000001;
        end else if (control_reg[0]) begin
            // 使能时才进行计数
            one_hot <= {one_hot[6:0], one_hot[7]};
        end
    end
    
    // 写地址/数据通道处理
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            write_state <= WRITE_IDLE;
            write_addr_valid <= 1'b0;
            write_data_valid <= 1'b0;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
            control_reg <= 2'b00;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    // 检查地址和数据通道
                    if (s_axi_awvalid && !write_addr_valid) begin
                        write_addr <= s_axi_awaddr[5:2];
                        write_addr_valid <= 1'b1;
                        s_axi_awready <= 1'b1;
                        
                        if (s_axi_wvalid && !write_data_valid) begin
                            // 地址和数据同时到达
                            write_data <= s_axi_wdata;
                            write_strb <= s_axi_wstrb;
                            write_data_valid <= 1'b1;
                            s_axi_wready <= 1'b1;
                            write_state <= WRITE_RESP;
                        end else begin
                            // 只有地址到达
                            write_state <= WRITE_ADDR_FIRST;
                        end
                    end else if (s_axi_wvalid && !write_data_valid) begin
                        // 只有数据到达
                        write_data <= s_axi_wdata;
                        write_strb <= s_axi_wstrb;
                        write_data_valid <= 1'b1;
                        s_axi_wready <= 1'b1;
                        write_state <= WRITE_DATA_FIRST;
                    end
                end
                
                WRITE_ADDR_FIRST: begin
                    s_axi_awready <= 1'b0;
                    
                    if (s_axi_wvalid) begin
                        write_data <= s_axi_wdata;
                        write_strb <= s_axi_wstrb;
                        write_data_valid <= 1'b1;
                        s_axi_wready <= 1'b1;
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_DATA_FIRST: begin
                    s_axi_wready <= 1'b0;
                    
                    if (s_axi_awvalid) begin
                        write_addr <= s_axi_awaddr[5:2];
                        write_addr_valid <= 1'b1;
                        s_axi_awready <= 1'b1;
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready <= 1'b0;
                    
                    // 处理写操作
                    if (write_addr_valid && write_data_valid) begin
                        case (write_addr)
                            ADDR_ONE_HOT: begin
                                // one_hot寄存器是只读的，写入会产生错误
                                s_axi_bresp <= RESP_SLVERR;
                            end
                            
                            ADDR_CONTROL: begin
                                if (write_strb[0]) begin
                                    control_reg <= write_data[1:0];
                                end
                                s_axi_bresp <= RESP_OKAY;
                            end
                            
                            default: begin
                                // 未知地址
                                s_axi_bresp <= RESP_SLVERR;
                            end
                        endcase
                        
                        // 清除地址和数据有效标志
                        write_addr_valid <= 1'b0;
                        write_data_valid <= 1'b0;
                        
                        // 发送响应
                        s_axi_bvalid <= 1'b1;
                    end
                    
                    // 等待主机接收响应
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: begin
                    // 安全处理异常状态
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end
    
    // 读地址/数据通道处理
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            read_state <= READ_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            s_axi_rdata <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axi_arvalid) begin
                        read_addr <= s_axi_araddr[5:2];
                        s_axi_arready <= 1'b1;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    s_axi_arready <= 1'b0;
                    
                    // 准备读取数据
                    case (read_addr)
                        ADDR_ONE_HOT: begin
                            s_axi_rdata <= {24'h0, one_hot};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        
                        ADDR_CONTROL: begin
                            s_axi_rdata <= {30'h0, control_reg};
                            s_axi_rresp <= RESP_OKAY;
                        end
                        
                        default: begin
                            // 未知地址
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= RESP_SLVERR;
                        end
                    endcase
                    
                    s_axi_rvalid <= 1'b1;
                    
                    // 等待主机接收数据
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: begin
                    // 安全处理异常状态
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end

endmodule