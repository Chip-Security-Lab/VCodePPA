//SystemVerilog
module key_encoder_axi (
    // 全局信号
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite 写地址通道
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite 写数据通道
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite 写响应通道
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // AXI4-Lite 读地址通道
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite 读数据通道
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // 原始输入信号
    input wire [15:0] keys
);

    // 寄存器地址映射
    localparam ADDR_KEY_INPUT    = 4'h0;  // 0x00: 键盘输入寄存器
    localparam ADDR_KEY_CODE     = 4'h4;  // 0x04: 编码输出寄存器
    
    // 流水线寄存器
    reg [15:0] keys_reg;
    reg [15:0] keys_stage1;
    reg [3:0] key_code_stage1;
    reg [3:0] key_code_stage2;
    reg key_valid_stage1;
    reg key_valid_stage2;
    
    // 流水线阶段1: 键盘采样
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            keys_stage1 <= 16'h0000;
            key_valid_stage1 <= 1'b0;
        end else begin
            keys_stage1 <= keys_reg;
            key_valid_stage1 <= 1'b1;
        end
    end
    
    // 流水线阶段2: 键盘编码逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            key_code_stage1 <= 4'hF;
        end else if (key_valid_stage1) begin
            casez(keys_stage1)
                16'b????_????_????_???1: key_code_stage1 <= 4'h0;
                16'b????_????_????_??10: key_code_stage1 <= 4'h1;
                16'b????_????_????_?100: key_code_stage1 <= 4'h2;
                16'b????_????_????_1000: key_code_stage1 <= 4'h3;
                16'b????_????_???1_0000: key_code_stage1 <= 4'h4;
                16'b????_????_??10_0000: key_code_stage1 <= 4'h5;
                16'b????_????_?100_0000: key_code_stage1 <= 4'h6;
                16'b????_????_1000_0000: key_code_stage1 <= 4'h7;
                16'b????_???1_0000_0000: key_code_stage1 <= 4'h8;
                16'b????_??10_0000_0000: key_code_stage1 <= 4'h9;
                16'b????_?100_0000_0000: key_code_stage1 <= 4'hA;
                16'b????_1000_0000_0000: key_code_stage1 <= 4'hB;
                16'b???1_0000_0000_0000: key_code_stage1 <= 4'hC;
                16'b??10_0000_0000_0000: key_code_stage1 <= 4'hD;
                16'b?100_0000_0000_0000: key_code_stage1 <= 4'hE;
                16'b1000_0000_0000_0000: key_code_stage1 <= 4'h0;
                default: key_code_stage1 <= 4'hF;
            endcase
        end
    end
    
    // 流水线阶段3: 输出寄存
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            key_code_stage2 <= 4'hF;
            key_valid_stage2 <= 1'b0;
        end else begin
            key_code_stage2 <= key_code_stage1;
            key_valid_stage2 <= key_valid_stage1;
        end
    end
    
    // AXI4-Lite 写地址通道处理 - 流水线化
    reg awaddr_done;
    reg awaddr_done_stage1;
    reg [3:0] write_addr;
    reg [3:0] write_addr_stage1;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
            awaddr_done <= 1'b0;
            write_addr <= 4'h0;
            awaddr_done_stage1 <= 1'b0;
            write_addr_stage1 <= 4'h0;
        end else begin
            // 第一阶段: 地址接收
            if (s_axil_awvalid && !awaddr_done) begin
                s_axil_awready <= 1'b1;
                write_addr <= s_axil_awaddr[5:2];
                awaddr_done <= 1'b1;
            end else begin
                s_axil_awready <= 1'b0;
            end
            
            // 第二阶段: 地址传递
            awaddr_done_stage1 <= awaddr_done;
            write_addr_stage1 <= write_addr;
            
            // 重置握手状态
            if (awaddr_done_stage1 && s_axil_wvalid && s_axil_wready) begin
                awaddr_done <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite 写数据通道处理 - 流水线化
    reg wdata_done;
    reg wdata_done_stage1;
    reg wstrb_valid;
    reg [1:0] wstrb_valid_bits;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_wready <= 1'b0;
            wdata_done <= 1'b0;
            keys_reg <= 16'h0000;
            wdata_done_stage1 <= 1'b0;
            wstrb_valid <= 1'b0;
            wstrb_valid_bits <= 2'b00;
        end else begin
            // 第一阶段: 数据接收
            if (s_axil_wvalid && awaddr_done_stage1 && !wdata_done) begin
                s_axil_wready <= 1'b1;
                wdata_done <= 1'b1;
                
                if (write_addr_stage1 == ADDR_KEY_INPUT) begin
                    wstrb_valid <= 1'b1;
                    wstrb_valid_bits <= s_axil_wstrb[1:0];
                    
                    if (s_axil_wstrb[0]) keys_reg[7:0] <= s_axil_wdata[7:0];
                    if (s_axil_wstrb[1]) keys_reg[15:8] <= s_axil_wdata[15:8];
                end
            end else begin
                s_axil_wready <= 1'b0;
                wstrb_valid <= 1'b0;
            end
            
            // 第二阶段: 传递写完成状态
            wdata_done_stage1 <= wdata_done;
            
            // 重置握手状态
            if (wdata_done_stage1 && s_axil_bready && s_axil_bvalid) begin
                wdata_done <= 1'b0;
            end
            
            // 键盘输入采样 - 当无写操作时
            if (write_addr_stage1 != ADDR_KEY_INPUT && !wstrb_valid) begin
                keys_reg <= keys;
            end
        end
    end
    
    // AXI4-Lite 写响应通道处理 - 流水线化
    reg bvalid_ready;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            bvalid_ready <= 1'b0;
        end else begin
            // 第一阶段: 准备响应条件
            bvalid_ready <= wdata_done_stage1 && awaddr_done_stage1;
            
            // 第二阶段: 发送响应
            if (bvalid_ready && !s_axil_bvalid) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b00; // OKAY响应
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite 读地址通道处理 - 流水线化
    reg araddr_done;
    reg araddr_done_stage1;
    reg [3:0] read_addr;
    reg [3:0] read_addr_stage1;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            araddr_done <= 1'b0;
            read_addr <= 4'h0;
            araddr_done_stage1 <= 1'b0;
            read_addr_stage1 <= 4'h0;
        end else begin
            // 第一阶段: 地址接收
            if (s_axil_arvalid && !araddr_done) begin
                s_axil_arready <= 1'b1;
                read_addr <= s_axil_araddr[5:2];
                araddr_done <= 1'b1;
            end else begin
                s_axil_arready <= 1'b0;
            end
            
            // 第二阶段: 地址传递
            araddr_done_stage1 <= araddr_done;
            read_addr_stage1 <= read_addr;
            
            // 重置握手状态
            if (araddr_done_stage1 && s_axil_rvalid && s_axil_rready) begin
                araddr_done <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite 读数据通道处理 - 流水线化
    reg rdata_ready;
    reg [31:0] rdata_stage1;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
            rdata_ready <= 1'b0;
            rdata_stage1 <= 32'h0;
        end else begin
            // 第一阶段: 准备数据
            rdata_ready <= araddr_done_stage1;
            
            // 第二阶段: 选择数据
            if (rdata_ready && !s_axil_rvalid) begin
                case (read_addr_stage1)
                    ADDR_KEY_INPUT: rdata_stage1 <= {16'h0000, keys_stage1};
                    ADDR_KEY_CODE:  rdata_stage1 <= {28'h0, key_code_stage2};
                    default:        rdata_stage1 <= 32'h0;
                endcase
            end
            
            // 第三阶段: 发送数据
            if (rdata_ready && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp <= 2'b00; // OKAY
                s_axil_rdata <= rdata_stage1;
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

endmodule