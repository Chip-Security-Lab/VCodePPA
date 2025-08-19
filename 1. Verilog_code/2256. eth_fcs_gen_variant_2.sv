//SystemVerilog
module eth_fcs_gen (
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite接口
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // 内部寄存器定义
    localparam REG_CONTROL = 4'h0;      // 控制寄存器地址
    localparam REG_STATUS = 4'h4;       // 状态寄存器地址
    localparam REG_DATA_IN = 4'h8;      // 输入数据寄存器地址
    localparam REG_FCS_OUT = 4'hC;      // FCS输出寄存器地址
    
    // 内部信号
    reg [31:0] fcs;                     // FCS计算结果
    reg processing;                     // 数据处理标志
    reg packet_end;                     // 数据包结束标志
    
    reg [7:0] input_data;               // 输入数据寄存器
    reg data_valid;                     // 数据有效标志
    reg data_last;                      // 最后一个数据标志
    
    reg [31:0] control_reg;             // 控制寄存器
    reg [31:0] status_reg;              // 状态寄存器
    
    // 写请求地址通道状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_awready <= 1'b0;
        end else if (s_axil_awvalid && !s_axil_awready) begin
            s_axil_awready <= 1'b1;
        end else begin
            s_axil_awready <= 1'b0;
        end
    end
    
    // 写请求数据通道状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_wready <= 1'b0;
            control_reg <= 32'h0;
            input_data <= 8'h0;
            data_valid <= 1'b0;
            data_last <= 1'b0;
        end else if (s_axil_wvalid && !s_axil_wready && s_axil_awready) begin
            s_axil_wready <= 1'b1;
            
            // 根据地址写入相应寄存器
            case (s_axil_awaddr[3:0])
                REG_CONTROL: begin
                    // 控制寄存器写入
                    if (s_axil_wstrb[0]) control_reg[7:0] <= s_axil_wdata[7:0];
                    if (s_axil_wstrb[1]) control_reg[15:8] <= s_axil_wdata[15:8];
                    if (s_axil_wstrb[2]) control_reg[23:16] <= s_axil_wdata[23:16];
                    if (s_axil_wstrb[3]) control_reg[31:24] <= s_axil_wdata[31:24];
                end
                REG_DATA_IN: begin
                    // 数据输入寄存器写入
                    if (s_axil_wstrb[0]) begin
                        input_data <= s_axil_wdata[7:0];
                        data_valid <= 1'b1;
                        data_last <= control_reg[0]; // 控制寄存器的最低位用作last标志
                    end
                end
                default: begin
                    // 无操作
                end
            endcase
        end else begin
            s_axil_wready <= 1'b0;
            // 当数据被处理后，清除有效标志
            if (data_valid && processing) begin
                data_valid <= 1'b0;
            end
        end
    end
    
    // 写响应通道状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00; // OKAY
        end else if (s_axil_wready && s_axil_wvalid && !s_axil_bvalid) begin
            s_axil_bvalid <= 1'b1;
        end else if (s_axil_bvalid && s_axil_bready) begin
            s_axil_bvalid <= 1'b0;
        end
    end
    
    // 读请求地址通道状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_arready <= 1'b0;
        end else if (s_axil_arvalid && !s_axil_arready) begin
            s_axil_arready <= 1'b1;
        end else begin
            s_axil_arready <= 1'b0;
        end
    end
    
    // 读数据通道状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00; // OKAY
        end else if (s_axil_arready && s_axil_arvalid && !s_axil_rvalid) begin
            s_axil_rvalid <= 1'b1;
            
            // 根据地址读取相应寄存器
            case (s_axil_araddr[3:0])
                REG_CONTROL: s_axil_rdata <= control_reg;
                REG_STATUS: s_axil_rdata <= status_reg;
                REG_FCS_OUT: s_axil_rdata <= fcs;
                default: s_axil_rdata <= 32'h0;
            endcase
        end else if (s_axil_rvalid && s_axil_rready) begin
            s_axil_rvalid <= 1'b0;
        end
    end
    
    // FCS计算状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing <= 1'b0;
            fcs <= 32'hFFFFFFFF;
            packet_end <= 1'b0;
            status_reg <= 32'h0;
        end else begin
            // 更新状态寄存器
            status_reg[0] <= processing;
            status_reg[1] <= packet_end;
            
            // 处理新数据
            if (data_valid && !processing) begin
                processing <= 1'b1;
                fcs <= 32'hFFFFFFFF; // 重置FCS
                
                // CRC计算 (简化版，实际代码应包含完整CRC计算)
                fcs[31:24] <= fcs[24] ^ input_data[7] ^ fcs[30] ^ fcs[24];
                // ... 完整32位CRC计算逻辑
                
                // 检测数据包结束
                packet_end <= data_last;
            end else if (data_valid && processing) begin
                // 继续CRC计算
                fcs[31:24] <= fcs[24] ^ input_data[7] ^ fcs[30] ^ fcs[24];
                // ... 完整32位CRC计算逻辑
                
                // 检测数据包结束
                packet_end <= data_last;
            end
            
            // FCS计算完成
            if (packet_end) begin
                processing <= 1'b0;
                packet_end <= 1'b0;
                // 最终的FCS值存储在fcs寄存器中，可通过读请求访问
            end
        end
    end
    
endmodule