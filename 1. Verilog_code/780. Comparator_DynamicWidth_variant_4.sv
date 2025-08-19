//SystemVerilog
module Comparator_AXI4Lite (
    // 全局信号
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite 写地址通道
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite 写数据通道
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite 写响应通道
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite 读地址通道
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite 读数据通道
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // 比较结果输出
    output wire        unequal
);

    // 寄存器地址定义
    localparam ADDR_DATA_X     = 4'h0;     // 0x00: data_x 寄存器
    localparam ADDR_DATA_Y     = 4'h4;     // 0x04: data_y 寄存器
    localparam ADDR_VALID_BITS = 4'h8;     // 0x08: valid_bits 寄存器
    localparam ADDR_RESULT     = 4'hC;     // 0x0C: 比较结果寄存器
    
    // 内部寄存器
    reg [15:0] data_x_reg;
    reg [15:0] data_y_reg;
    reg [3:0]  valid_bits_reg;
    reg        unequal_reg;
    
    // AXI4-Lite 写状态机 - 使用二进制编码
    localparam W_IDLE = 2'b00;  // 空闲状态
    localparam W_ADDR = 2'b01;  // 地址接收状态
    localparam W_DATA = 2'b10;  // 数据接收状态
    localparam W_RESP = 2'b11;  // 响应状态
    
    reg [1:0] w_state;
    reg [3:0] write_addr;
    
    // AXI4-Lite 读状态机 - 使用二进制编码
    localparam R_IDLE = 2'b00;  // 空闲状态
    localparam R_ADDR = 2'b01;  // 地址接收状态
    localparam R_DATA = 2'b10;  // 数据发送状态
    
    reg [1:0] r_state;
    reg [3:0] read_addr;
    
    // 动态掩码生成和比较逻辑
    wire [15:0] mask;
    assign mask = (16'hFFFF << valid_bits_reg);
    assign unequal = unequal_reg;
    
    // 比较计算功能 - 优化位运算
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            unequal_reg <= 1'b0;
        end else begin
            unequal_reg <= ((data_x_reg & ~mask) != (data_y_reg & ~mask));
        end
    end
    
    // AXI4-Lite 写状态机实现 - 使用二进制状态编码的优化实现
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            w_state <= W_IDLE;
            write_addr <= 4'h0;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            data_x_reg <= 16'h0000;
            data_y_reg <= 16'h0000;
            valid_bits_reg <= 4'h0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    s_axi_awready <= 1'b1;
                    if (s_axi_awvalid) begin
                        write_addr <= s_axi_awaddr[5:2];
                        s_axi_awready <= 1'b0;
                        w_state <= W_ADDR;
                    end
                end
                
                W_ADDR: begin
                    s_axi_wready <= 1'b1;
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b0;
                        w_state <= W_DATA;
                        
                        // 写入数据到对应寄存器
                        case (write_addr)
                            ADDR_DATA_X: begin
                                if (s_axi_wstrb[0]) data_x_reg[7:0] <= s_axi_wdata[7:0];
                                if (s_axi_wstrb[1]) data_x_reg[15:8] <= s_axi_wdata[15:8];
                            end
                            ADDR_DATA_Y: begin
                                if (s_axi_wstrb[0]) data_y_reg[7:0] <= s_axi_wdata[7:0];
                                if (s_axi_wstrb[1]) data_y_reg[15:8] <= s_axi_wdata[15:8];
                            end
                            ADDR_VALID_BITS: begin
                                if (s_axi_wstrb[0]) valid_bits_reg <= s_axi_wdata[3:0];
                            end
                        endcase
                    end
                end
                
                W_DATA: begin
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp <= 2'b00; // OKAY response
                    w_state <= W_RESP;
                end
                
                W_RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        w_state <= W_IDLE;
                    end
                end
            endcase
        end
    end
    
    // AXI4-Lite 读状态机实现 - 使用二进制状态编码的优化实现
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            r_state <= R_IDLE;
            read_addr <= 4'h0;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h00000000;
        end else begin
            case (r_state)
                R_IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid) begin
                        read_addr <= s_axi_araddr[5:2];
                        s_axi_arready <= 1'b0;
                        r_state <= R_ADDR;
                    end
                end
                
                R_ADDR: begin
                    s_axi_rvalid <= 1'b1;
                    s_axi_rresp <= 2'b00; // OKAY response
                    
                    // 从对应寄存器读取数据
                    case (read_addr)
                        ADDR_DATA_X:     s_axi_rdata <= {16'h0000, data_x_reg};
                        ADDR_DATA_Y:     s_axi_rdata <= {16'h0000, data_y_reg};
                        ADDR_VALID_BITS: s_axi_rdata <= {28'h0000000, valid_bits_reg};
                        ADDR_RESULT:     s_axi_rdata <= {31'h00000000, unequal_reg};
                        default:         s_axi_rdata <= 32'h00000000;
                    endcase
                    
                    r_state <= R_DATA;
                end
                
                R_DATA: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        r_state <= R_IDLE;
                    end
                end
            endcase
        end
    end

endmodule