//SystemVerilog
// 顶层模块 - 使用AXI4-Lite接口
module or_gate_2input_8bit (
    // 时钟和复位
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite写地址通道
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
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
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite读数据通道
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);
    // 内部寄存器
    reg [7:0] reg_a;
    reg [7:0] reg_b;
    wire [7:0] reg_y;
    
    // 写操作状态机
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    reg [1:0] write_state;
    reg [31:0] write_addr;
    
    // 读操作状态机
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    reg [1:0] read_state;
    reg [31:0] read_addr;
    
    // AXI4-Lite写通道处理
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
            write_addr <= 32'h0;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            reg_a <= 8'h0;
            reg_b <= 8'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    
                    if (s_axil_awvalid && s_axil_awready) begin
                        write_addr <= s_axil_awaddr;
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                        write_state <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00; // OKAY响应
                        
                        // 根据地址写入相应寄存器
                        case (write_addr[3:2])
                            2'b00: begin
                                if (s_axil_wstrb[0]) reg_a[7:0] <= s_axil_wdata[7:0];
                            end
                            2'b01: begin
                                if (s_axil_wstrb[0]) reg_b[7:0] <= s_axil_wdata[7:0];
                            end
                            default: begin
                                // 无效地址，但仍然返回OKAY以简化设计
                            end
                        endcase
                        
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
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI4-Lite读通道处理
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            read_addr <= 32'h0;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    
                    if (s_axil_arvalid && s_axil_arready) begin
                        read_addr <= s_axil_araddr;
                        s_axil_arready <= 1'b0;
                        read_state <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // OKAY响应
                    
                    // 根据地址读取相应寄存器
                    case (read_addr[3:2])
                        2'b00: s_axil_rdata <= {24'h0, reg_a};
                        2'b01: s_axil_rdata <= {24'h0, reg_b};
                        2'b10: s_axil_rdata <= {24'h0, reg_y};
                        default: s_axil_rdata <= 32'h0;
                    endcase
                    
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        s_axil_arready <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // 实例化子模块处理不同位组
    wire [3:0] lower_result;
    wire [3:0] upper_result;
    
    // 低4位或操作
    or_gate_4bit lower_bits (
        .a_in(reg_a[3:0]),
        .b_in(reg_b[3:0]),
        .y_out(lower_result)
    );
    
    // 高4位或操作
    or_gate_4bit upper_bits (
        .a_in(reg_a[7:4]),
        .b_in(reg_b[7:4]),
        .y_out(upper_result)
    );
    
    // 组合结果
    assign reg_y = {upper_result, lower_result};
endmodule

// 4位或操作子模块
module or_gate_4bit (
    input wire [3:0] a_in,
    input wire [3:0] b_in,
    output wire [3:0] y_out
);
    // 实例化2位或门处理不同位组
    wire [1:0] lower_result;
    wire [1:0] upper_result;
    
    // 低2位或操作
    or_gate_2bit lower_bits (
        .a_in(a_in[1:0]),
        .b_in(b_in[1:0]),
        .y_out(lower_result)
    );
    
    // 高2位或操作
    or_gate_2bit upper_bits (
        .a_in(a_in[3:2]),
        .b_in(b_in[3:2]),
        .y_out(upper_result)
    );
    
    // 组合结果
    assign y_out = {upper_result, lower_result};
endmodule

// 2位或操作子模块
module or_gate_2bit (
    input wire [1:0] a_in,
    input wire [1:0] b_in,
    output wire [1:0] y_out
);
    // 实例化单比特或门
    or_gate_1bit bit0 (
        .a(a_in[0]),
        .b(b_in[0]),
        .y(y_out[0])
    );
    
    or_gate_1bit bit1 (
        .a(a_in[1]),
        .b(b_in[1]),
        .y(y_out[1])
    );
endmodule

// 基本1位或门子模块 - 优化PPA特性
module or_gate_1bit (
    input wire a,
    input wire b,
    output wire y
);
    // 使用三态逻辑实现或门以改变PPA特性
    wire temp;
    
    // 条件逻辑实现或操作
    assign temp = a ? 1'b1 : 1'bz;
    assign y = (b || temp === 1'b1) ? 1'b1 : 1'b0;
endmodule