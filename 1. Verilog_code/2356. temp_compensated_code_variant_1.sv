//SystemVerilog
module temp_compensated_codec_axi (
    // Clock and Reset
    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    
    // AXI4-Lite 写地址通道
    input  wire [31:0]  s_axi_awaddr,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    
    // AXI4-Lite 写数据通道
    input  wire [31:0]  s_axi_wdata,
    input  wire [3:0]   s_axi_wstrb,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,
    
    // AXI4-Lite 写响应通道
    output reg [1:0]    s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,
    
    // AXI4-Lite 读地址通道
    input  wire [31:0]  s_axi_araddr,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,
    
    // AXI4-Lite 读数据通道
    output reg [31:0]   s_axi_rdata,
    output reg [1:0]    s_axi_rresp,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready,
    
    // 输出显示数据
    output wire [15:0]  display_out
);

    // 内部寄存器
    reg [7:0] r_in_reg;
    reg [7:0] g_in_reg;
    reg [7:0] b_in_reg;
    reg [7:0] temperature_reg;
    reg       comp_enable_reg;

    // 寄存器地址映射 (字节地址)
    localparam ADDR_R_IN         = 5'h00;  // 0x00
    localparam ADDR_G_IN         = 5'h04;  // 0x04
    localparam ADDR_B_IN         = 5'h08;  // 0x08
    localparam ADDR_TEMPERATURE  = 5'h0C;  // 0x0C
    localparam ADDR_COMP_ENABLE  = 5'h10;  // 0x10
    localparam ADDR_DISPLAY_OUT  = 5'h14;  // 0x14 (只读)

    // AXI FSM 状态
    localparam IDLE          = 2'b00;
    localparam WRITE_DATA    = 2'b01;
    localparam WRITE_RESP    = 2'b10;
    localparam READ_DATA     = 2'b11;

    reg [1:0] axi_state;
    
    // 缓存地址
    reg [4:0] axi_awaddr_reg;
    reg [4:0] axi_araddr_reg;

    // 温度补偿因子计算
    wire [3:0] r_factor = temperature_reg > 8'd80 ? 4'd12 : 
                          temperature_reg > 8'd60 ? 4'd13 :
                          temperature_reg > 8'd40 ? 4'd14 :
                          temperature_reg > 8'd20 ? 4'd15 : 4'd15;
    wire [3:0] g_factor = temperature_reg > 8'd80 ? 4'd14 : 
                          temperature_reg > 8'd60 ? 4'd15 :
                          temperature_reg > 8'd40 ? 4'd15 :
                          temperature_reg > 8'd20 ? 4'd14 : 4'd13;
    wire [3:0] b_factor = temperature_reg > 8'd80 ? 4'd15 : 
                          temperature_reg > 8'd60 ? 4'd14 :
                          temperature_reg > 8'd40 ? 4'd13 :
                          temperature_reg > 8'd20 ? 4'd12 : 4'd11;
    
    // 调整后的RGB值使用Karatsuba乘法器
    wire [11:0] r_adj = comp_enable_reg ? karatsuba_mult_8x4(r_in_reg, r_factor) : {r_in_reg, 4'b0000};
    wire [11:0] g_adj = comp_enable_reg ? karatsuba_mult_8x4(g_in_reg, g_factor) : {g_in_reg, 4'b0000};
    wire [11:0] b_adj = comp_enable_reg ? karatsuba_mult_8x4(b_in_reg, b_factor) : {b_in_reg, 4'b0000};
    
    // RGB转RGB565输出寄存器
    reg [15:0] display_out_reg;
    
    // 将输出连接到经过温度补偿的RGB565
    assign display_out = display_out_reg;

    // 写地址通道处理
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            axi_awaddr_reg <= 5'h0;
            axi_state <= IDLE;
        end 
        else begin
            case (axi_state)
                IDLE: begin
                    if (s_axi_awvalid && ~s_axi_awready) begin
                        s_axi_awready <= 1'b1;
                        axi_awaddr_reg <= s_axi_awaddr[4:0]; // 保存地址
                        axi_state <= WRITE_DATA;
                    end
                    else if (s_axi_arvalid && ~s_axi_arready) begin
                        s_axi_arready <= 1'b1;
                        axi_araddr_reg <= s_axi_araddr[4:0]; // 保存地址
                        axi_state <= READ_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    s_axi_awready <= 1'b0;
                    if (s_axi_wvalid && s_axi_wready) begin
                        axi_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axi_bready && s_axi_bvalid) begin
                        axi_state <= IDLE;
                    end
                end
                
                READ_DATA: begin
                    s_axi_arready <= 1'b0;
                    if (s_axi_rvalid && s_axi_rready) begin
                        axi_state <= IDLE;
                    end
                end
            endcase
        end
    end

    // 写数据通道处理
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            r_in_reg <= 8'h0;
            g_in_reg <= 8'h0;
            b_in_reg <= 8'h0;
            temperature_reg <= 8'h0;
            comp_enable_reg <= 1'b0;
        end 
        else begin
            if (axi_state == WRITE_DATA) begin
                s_axi_wready <= 1'b1;
                
                if (s_axi_wvalid && s_axi_wready) begin
                    s_axi_wready <= 1'b0;
                    
                    case (axi_awaddr_reg)
                        ADDR_R_IN: begin
                            if (s_axi_wstrb[0]) r_in_reg <= s_axi_wdata[7:0];
                        end
                        ADDR_G_IN: begin
                            if (s_axi_wstrb[0]) g_in_reg <= s_axi_wdata[7:0];
                        end
                        ADDR_B_IN: begin
                            if (s_axi_wstrb[0]) b_in_reg <= s_axi_wdata[7:0];
                        end
                        ADDR_TEMPERATURE: begin
                            if (s_axi_wstrb[0]) temperature_reg <= s_axi_wdata[7:0];
                        end
                        ADDR_COMP_ENABLE: begin
                            if (s_axi_wstrb[0]) comp_enable_reg <= s_axi_wdata[0];
                        end
                        default: begin
                            // 写入到未映射的地址 - 不做操作
                        end
                    endcase
                end
            end
            else begin
                s_axi_wready <= 1'b0;
            end
        end
    end

    // 写响应通道处理
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00; // OKAY
        end 
        else begin
            if (axi_state == WRITE_RESP) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00; // OKAY
                
                if (s_axi_bready && s_axi_bvalid) begin
                    s_axi_bvalid <= 1'b0;
                end
            end
            else begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // 读数据通道处理
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b00; // OKAY
        end 
        else begin
            if (axi_state == READ_DATA) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00; // OKAY
                
                case (axi_araddr_reg)
                    ADDR_R_IN:        s_axi_rdata <= {24'h0, r_in_reg};
                    ADDR_G_IN:        s_axi_rdata <= {24'h0, g_in_reg};
                    ADDR_B_IN:        s_axi_rdata <= {24'h0, b_in_reg};
                    ADDR_TEMPERATURE: s_axi_rdata <= {24'h0, temperature_reg};
                    ADDR_COMP_ENABLE: s_axi_rdata <= {31'h0, comp_enable_reg};
                    ADDR_DISPLAY_OUT: s_axi_rdata <= {16'h0, display_out_reg};
                    default:          s_axi_rdata <= 32'h0;
                endcase
                
                if (s_axi_rready && s_axi_rvalid) begin
                    s_axi_rvalid <= 1'b0;
                end
            end
            else begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // RGB到RGB565转换与温度补偿
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn)
            display_out_reg <= 16'h0000;
        else
            display_out_reg <= {r_adj[11:7], g_adj[11:6], b_adj[11:7]};
    end

    // 8-bit x 4-bit Karatsuba乘法器函数
    function [11:0] karatsuba_mult_8x4;
        input [7:0] a;
        input [3:0] b;
        reg [3:0] a_high, a_low;
        reg [1:0] b_high, b_low;
        reg [5:0] p1, p2, p3;
        reg [7:0] temp;
        begin
            // 分割输入
            a_high = a[7:4];
            a_low = a[3:0];
            b_high = b[3:2];
            b_low = b[1:0];
            
            // 使用递归Karatsuba方法计算子乘积
            p1 = karatsuba_mult_4x2(a_high, b_high);
            p2 = karatsuba_mult_4x2(a_low, b_low);
            temp = karatsuba_mult_4x2((a_high + a_low), (b_high + b_low));
            p3 = temp - p1 - p2;
            
            // 合并结果
            karatsuba_mult_8x4 = {p1, 6'b0} + {p3, 2'b0} + p2;
        end
    endfunction

    // 4-bit x 2-bit Karatsuba乘法器函数
    function [5:0] karatsuba_mult_4x2;
        input [3:0] a;
        input [1:0] b;
        reg [1:0] a_high, a_low;
        reg b_high, b_low;
        reg [2:0] p1, p2, p3;
        begin
            // 分割输入
            a_high = a[3:2];
            a_low = a[1:0];
            b_high = b[1];
            b_low = b[0];
            
            // 对小操作数进行基本乘法
            p1 = a_high * b_high;
            p2 = a_low * b_low;
            p3 = (a_high + a_low) * (b_high + b_low) - p1 - p2;
            
            // 合并结果
            karatsuba_mult_4x2 = {p1, 3'b0} + {p3, 1'b0} + p2;
        end
    endfunction

endmodule