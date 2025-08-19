//SystemVerilog
`timescale 1ns / 1ps

module pwm_timer (
    // AXI4-Lite接口
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // 写地址通道
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    // 写数据通道
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    // 写响应通道
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    // 读地址通道
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    // 读数据通道
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // PWM输出
    output wire        pwm_out
);

    // 参数定义
    localparam ADDR_LSB = 2;  // 字节寻址
    localparam ADDR_BITS = 4;
    
    // 寄存器地址映射 (字偏移)
    localparam REG_CTRL    = 4'h0;  // 控制寄存器: 使能位
    localparam REG_PERIOD  = 4'h1;  // PWM周期设置寄存器
    localparam REG_DUTY    = 4'h2;  // PWM占空比设置寄存器
    localparam REG_STATUS  = 4'h3;  // 状态寄存器
    
    // AXI信号
    reg  [ADDR_BITS-1:0] axi_awaddr;
    reg                  axi_awready;
    reg                  axi_wready;
    reg  [1:0]           axi_bresp;
    reg                  axi_bvalid;
    reg  [ADDR_BITS-1:0] axi_araddr;
    reg                  axi_arready;
    reg  [31:0]          axi_rdata;
    reg  [1:0]           axi_rresp;
    reg                  axi_rvalid;
    
    // 内部寄存器
    reg  [15:0]          reg_period;
    reg  [15:0]          reg_duty;
    reg                  reg_enable;
    
    // 内部信号
    wire [15:0]          counter_value;
    wire                 counter_reset;
    
    // AXI输出信号赋值
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = axi_bresp;
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = axi_rresp;
    assign s_axi_rvalid  = axi_rvalid;
    
    // 复位和时钟映射
    wire clk = s_axi_aclk;
    wire rst = ~s_axi_aresetn;

    // 写地址通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_awready <= 1'b0;
            axi_awaddr  <= 'd0;
        end else begin
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                axi_awready <= 1'b1;
                axi_awaddr  <= s_axi_awaddr[ADDR_LSB+ADDR_BITS-1:ADDR_LSB];
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // 写数据通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_wready <= 1'b0;
            reg_enable <= 1'b0;
            reg_period <= 16'd1000; // 默认值
            reg_duty   <= 16'd500;  // 默认值
        end else begin
            if (~axi_wready && s_axi_wvalid && s_axi_awvalid && axi_awready) begin
                axi_wready <= 1'b1;
                
                case (axi_awaddr)
                    REG_CTRL: begin
                        if (s_axi_wstrb[0]) 
                            reg_enable <= s_axi_wdata[0];
                    end
                    REG_PERIOD: begin
                        if (s_axi_wstrb[0]) 
                            reg_period[7:0] <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) 
                            reg_period[15:8] <= s_axi_wdata[15:8];
                    end
                    REG_DUTY: begin
                        if (s_axi_wstrb[0]) 
                            reg_duty[7:0] <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) 
                            reg_duty[15:8] <= s_axi_wdata[15:8];
                    end
                    default: begin
                        // 未使用的地址空间
                    end
                endcase
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // 写响应通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00; // OKAY响应
        end else begin
            if (axi_wready && s_axi_wvalid && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00; // OKAY响应
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // 读地址通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 'd0;
        end else begin
            if (~axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
                axi_araddr  <= s_axi_araddr[ADDR_LSB+ADDR_BITS-1:ADDR_LSB];
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // 读数据通道处理
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;
            axi_rdata  <= 32'd0;
        end else begin
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b00; // OKAY响应
                
                case (axi_araddr)
                    REG_CTRL: begin
                        axi_rdata <= {31'd0, reg_enable};
                    end
                    REG_PERIOD: begin
                        axi_rdata <= {16'd0, reg_period};
                    end
                    REG_DUTY: begin
                        axi_rdata <= {16'd0, reg_duty};
                    end
                    REG_STATUS: begin
                        axi_rdata <= {16'd0, counter_value};
                    end
                    default: begin
                        axi_rdata <= 32'd0;
                    end
                endcase
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // 计数器子模块实例化
    counter_module counter_inst (
        .clk(clk),
        .rst(rst),
        .enable(reg_enable),
        .period(reg_period),
        .counter_value(counter_value),
        .counter_reset(counter_reset)
    );

    // 比较器子模块实例化
    comparator_module comparator_inst (
        .clk(clk),
        .rst(rst),
        .enable(reg_enable),
        .counter_value(counter_value),
        .duty(reg_duty),
        .pwm_out(pwm_out)
    );

endmodule

// 计数器子模块
module counter_module (
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [15:0] period,
    output reg [15:0] counter_value,
    output wire counter_reset
);
    // 计数器达到周期值时的复位信号
    assign counter_reset = (counter_value >= period - 1);

    // 计数器逻辑
    always @(posedge clk) begin
        if (rst) begin
            counter_value <= 16'd0;
        end
        else if (enable) begin
            if (counter_reset) begin
                counter_value <= 16'd0;
            end
            else begin
                counter_value <= counter_value + 16'd1;
            end
        end
    end
endmodule

// 比较器子模块
module comparator_module (
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [15:0] counter_value,
    input wire [15:0] duty,
    output reg pwm_out
);
    // PWM输出比较逻辑
    always @(posedge clk) begin
        if (rst) begin
            pwm_out <= 1'b0;
        end
        else if (enable) begin
            pwm_out <= (counter_value < duty);
        end
    end
endmodule