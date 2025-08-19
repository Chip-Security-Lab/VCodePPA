//SystemVerilog
module xor_nand_gate_axi (
    // 全局信号
    input wire aclk,                    // AXI时钟
    input wire aresetn,                 // AXI异步复位，低电平有效
    
    // AXI4-Lite写地址通道
    input wire [31:0] s_axil_awaddr,    // 写地址
    input wire [2:0] s_axil_awprot,     // 写保护类型
    input wire s_axil_awvalid,          // 写地址有效
    output reg s_axil_awready,          // 写地址就绪
    
    // AXI4-Lite写数据通道
    input wire [31:0] s_axil_wdata,     // 写数据
    input wire [3:0] s_axil_wstrb,      // 写数据字节选通
    input wire s_axil_wvalid,           // 写数据有效
    output reg s_axil_wready,           // 写数据就绪
    
    // AXI4-Lite写响应通道
    output reg [1:0] s_axil_bresp,      // 写响应
    output reg s_axil_bvalid,           // 写响应有效
    input wire s_axil_bready,           // 写响应就绪
    
    // AXI4-Lite读地址通道
    input wire [31:0] s_axil_araddr,    // 读地址
    input wire [2:0] s_axil_arprot,     // 读保护类型
    input wire s_axil_arvalid,          // 读地址有效
    output reg s_axil_arready,          // 读地址就绪
    
    // AXI4-Lite读数据通道
    output reg [31:0] s_axil_rdata,     // 读数据
    output reg [1:0] s_axil_rresp,      // 读响应
    output reg s_axil_rvalid,           // 读数据有效
    input wire s_axil_rready            // 读数据就绪
);

    // 寄存器定义
    reg [31:0] reg_control;     // 控制寄存器 - 地址 0x00 (输入A,B,C位于[2:0])
    reg [31:0] reg_status;      // 状态寄存器 - 地址 0x04 (输出Y位于[0])
    
    // 提取输入信号
    wire A, B, C;
    assign A = reg_control[0];
    assign B = reg_control[1];
    assign C = reg_control[2];
    
    // 分离XOR中的两个操作以减少逻辑深度
    reg a_and_not_b;
    reg b_and_not_a;
    reg xor_result;
    
    // 预计算C的取反，减少后续级的逻辑深度
    reg not_c;
    
    // 数据流通路分段 - 最终NAND操作结果
    reg nand_result;
    reg Y;
    
    // 第一级流水线：预计算XOR的子操作和C的取反
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            a_and_not_b <= 1'b0;
            b_and_not_a <= 1'b0;
            not_c <= 1'b0;
        end else begin
            a_and_not_b <= A & ~B;
            b_and_not_a <= B & ~A;
            not_c <= ~C;
        end
    end
    
    // 第二级流水线：完成XOR操作并准备NAND计算
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            xor_result <= 1'b0;
            nand_result <= 1'b0;
        end else begin
            xor_result <= a_and_not_b | b_and_not_a;
            nand_result <= xor_result & not_c;
        end
    end
    
    // 输出级：传递结果到输出端口
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            Y <= 1'b0;
        end else begin
            Y <= nand_result;
        end
    end
    
    // 状态寄存器更新
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            reg_status <= 32'h0;
        end else begin
            reg_status[0] <= Y;  // 将结果Y更新到状态寄存器
        end
    end
    
    // AXI4-Lite写地址通道处理
    reg write_address_valid;
    reg [31:0] write_address;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
            write_address_valid <= 1'b0;
            write_address <= 32'h0;
        end else begin
            if (s_axil_awvalid && !write_address_valid && !s_axil_awready) begin
                s_axil_awready <= 1'b1;
                write_address_valid <= 1'b1;
                write_address <= s_axil_awaddr;
            end else if (s_axil_wvalid && s_axil_wready) begin
                write_address_valid <= 1'b0;
                s_axil_awready <= 1'b0;
            end else begin
                s_axil_awready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite写数据通道处理
    reg write_data_valid;
    reg [31:0] write_data;
    reg [3:0] write_strobe;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_wready <= 1'b0;
            write_data_valid <= 1'b0;
            write_data <= 32'h0;
            write_strobe <= 4'h0;
        end else begin
            if (s_axil_wvalid && !write_data_valid && !s_axil_wready) begin
                s_axil_wready <= 1'b1;
                write_data_valid <= 1'b1;
                write_data <= s_axil_wdata;
                write_strobe <= s_axil_wstrb;
            end else if (write_data_valid && write_address_valid) begin
                write_data_valid <= 1'b0;
                s_axil_wready <= 1'b0;
            end else begin
                s_axil_wready <= 1'b0;
            end
        end
    end
    
    // 寄存器写入逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            reg_control <= 32'h0;
        end else if (write_data_valid && write_address_valid) begin
            case (write_address[7:0])
                8'h00: begin // 控制寄存器
                    if (write_strobe[0]) reg_control[7:0] <= write_data[7:0];
                    if (write_strobe[1]) reg_control[15:8] <= write_data[15:8];
                    if (write_strobe[2]) reg_control[23:16] <= write_data[23:16];
                    if (write_strobe[3]) reg_control[31:24] <= write_data[31:24];
                end
                default: begin
                    // 其他地址不做处理
                end
            endcase
        end
    end
    
    // AXI4-Lite写响应通道处理
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            if (write_data_valid && write_address_valid) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b00; // OKAY响应
            end else if (s_axil_bready && s_axil_bvalid) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite读地址通道处理
    reg read_address_valid;
    reg [31:0] read_address;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            read_address_valid <= 1'b0;
            read_address <= 32'h0;
        end else begin
            if (s_axil_arvalid && !read_address_valid && !s_axil_arready) begin
                s_axil_arready <= 1'b1;
                read_address_valid <= 1'b1;
                read_address <= s_axil_araddr;
            end else if (s_axil_rvalid && s_axil_rready) begin
                read_address_valid <= 1'b0;
                s_axil_arready <= 1'b0;
            end else begin
                s_axil_arready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite读数据通道处理
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
        end else begin
            if (read_address_valid && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp <= 2'b00; // OKAY响应
                
                case (read_address[7:0])
                    8'h00: s_axil_rdata <= reg_control;  // 控制寄存器
                    8'h04: s_axil_rdata <= reg_status;   // 状态寄存器
                    default: s_axil_rdata <= 32'h0;      // 未知地址返回0
                endcase
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

endmodule