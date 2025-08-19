//SystemVerilog
//IEEE 1364-2005 Verilog标准
`timescale 1ns / 1ps
module freq_synthesizer(
    // 时钟与复位信号
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite写地址通道
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite写数据通道
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite写响应通道
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // AXI4-Lite读地址通道
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite读数据通道
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // 输出时钟
    output reg clk_out
);

    // 内部寄存器定义
    reg [1:0] mult_sel;       // 乘法器选择：00:x1, 01:x2, 10:x4, 11:x8
    reg [1:0] counter;        // 计数器
    reg [3:0] phase_vector;   // 相位向量：{phase_270, phase_180, phase_90, phase_0}
    reg toggle_clk;           // 切换时钟
    
    // 控制寄存器地址参数
    localparam CTRL_REG_ADDR = 32'h0000_0000;    // 控制寄存器地址
    localparam STATUS_REG_ADDR = 32'h0000_0004;  // 状态寄存器地址
    
    // AXI4-Lite写地址通道状态机
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    reg [1:0] write_state;
    reg [31:0] write_addr;
    
    // AXI4-Lite读地址通道状态机
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    reg [1:0] read_state;
    reg [31:0] read_addr;
    
    // AXI4-Lite写操作状态机
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
            write_addr <= 32'h0;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;  // OKAY
            mult_sel <= 2'b00;      // 默认1x
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    if (s_axil_awvalid && s_axil_awready) begin
                        write_addr <= s_axil_awaddr;
                        write_state <= WRITE_ADDR;
                        s_axil_awready <= 1'b0;
                    end
                end
                
                WRITE_ADDR: begin
                    s_axil_wready <= 1'b1;
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        write_state <= WRITE_RESP;
                        s_axil_bvalid <= 1'b1;
                        
                        // 根据地址写入相应寄存器
                        if (write_addr == CTRL_REG_ADDR) begin
                            if (s_axil_wstrb[0]) begin
                                mult_sel <= s_axil_wdata[1:0];
                                s_axil_bresp <= 2'b00;  // OKAY
                            end
                        end else begin
                            s_axil_bresp <= 2'b10;  // SLVERR - 不支持的地址
                        end
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI4-Lite读操作状态机
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            read_addr <= 32'h0;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;  // OKAY
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    if (s_axil_arvalid && s_axil_arready) begin
                        read_addr <= s_axil_araddr;
                        read_state <= READ_ADDR;
                        s_axil_arready <= 1'b0;
                    end
                end
                
                READ_ADDR: begin
                    s_axil_rvalid <= 1'b1;
                    
                    // 根据地址读取相应寄存器
                    if (read_addr == CTRL_REG_ADDR) begin
                        s_axil_rdata <= {30'b0, mult_sel};  // 控制寄存器
                        s_axil_rresp <= 2'b00;  // OKAY
                    end else if (read_addr == STATUS_REG_ADDR) begin
                        s_axil_rdata <= {28'b0, counter, 1'b0, clk_out};  // 状态寄存器
                        s_axil_rresp <= 2'b00;  // OKAY
                    end else begin
                        s_axil_rdata <= 32'h0;
                        s_axil_rresp <= 2'b10;  // SLVERR - 不支持的地址
                    end
                    
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // 频率合成器核心逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            counter <= 2'b00;
            phase_vector <= 4'b0001;
            clk_out <= 1'b0;
            toggle_clk <= 1'b0;
        end else begin
            // 计数器更新 - 优化为自然循环
            counter <= (counter == 2'b11) ? 2'b00 : counter + 2'b01;
            
            // 相位生成 - 优化为循环移位寄存器
            phase_vector <= {phase_vector[2:0], phase_vector[3]};
            
            // 分频时钟生成逻辑 - 使用参数化切换
            toggle_clk <= (mult_sel == 2'b11) ? ~toggle_clk : toggle_clk;
            
            // 频率合成逻辑 - 优化比较结构
            case (mult_sel)
                2'b00: clk_out <= phase_vector[0]; // x1
                2'b01: clk_out <= phase_vector[0] | phase_vector[2]; // x2
                2'b10: clk_out <= |phase_vector; // x4
                2'b11: clk_out <= toggle_clk; // x8
            endcase
        end
    end

endmodule