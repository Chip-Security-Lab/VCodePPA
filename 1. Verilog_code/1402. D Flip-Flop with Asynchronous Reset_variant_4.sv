//SystemVerilog - IEEE 1364-2005
module d_ff_async_reset_axi (
    input  wire        s_axi_aclk,      // AXI时钟信号
    input  wire        s_axi_aresetn,   // AXI异步低电平复位信号
    
    // AXI4-Lite写地址通道
    input  wire        s_axi_awvalid,   // 写地址有效
    output wire        s_axi_awready,   // 写地址就绪
    input  wire [31:0] s_axi_awaddr,    // 写地址
    input  wire [2:0]  s_axi_awprot,    // 写保护类型
    
    // AXI4-Lite写数据通道
    input  wire        s_axi_wvalid,    // 写数据有效
    output wire        s_axi_wready,    // 写数据就绪
    input  wire [31:0] s_axi_wdata,     // 写数据
    input  wire [3:0]  s_axi_wstrb,     // 写数据字节选通
    
    // AXI4-Lite写响应通道
    output wire        s_axi_bvalid,    // 写响应有效
    input  wire        s_axi_bready,    // 写响应就绪
    output wire [1:0]  s_axi_bresp,     // 写响应状态
    
    // AXI4-Lite读地址通道
    input  wire        s_axi_arvalid,   // 读地址有效
    output wire        s_axi_arready,   // 读地址就绪
    input  wire [31:0] s_axi_araddr,    // 读地址
    input  wire [2:0]  s_axi_arprot,    // 读保护类型
    
    // AXI4-Lite读数据通道
    output wire        s_axi_rvalid,    // 读数据有效
    input  wire        s_axi_rready,    // 读数据就绪
    output wire [31:0] s_axi_rdata,     // 读数据
    output wire [1:0]  s_axi_rresp      // 读响应状态
);

    // 内部寄存器
    wire d_value;           // 存储D触发器的输入值
    reg  q_value;           // 存储D触发器的输出值
    reg  d_buffered;        // 缓冲的输入值

    // 寄存器地址映射
    localparam D_REG_ADDR = 8'h00;  // D寄存器地址
    localparam Q_REG_ADDR = 8'h04;  // Q寄存器地址

    // 写逻辑控制信号
    wire write_valid;       // 写操作有效信号
    wire [31:0] write_data; // 写入的数据
    wire [31:0] write_addr; // 写入的地址
    wire [3:0]  write_strb; // 写入的字节选通信号

    // 读逻辑控制信号
    wire read_valid;        // 读操作有效信号
    wire [31:0] read_addr;  // 读取的地址
    wire [31:0] read_data;  // 读取的数据

    // 地址解码器
    wire is_d_reg_write = (write_addr[7:0] == D_REG_ADDR) && write_valid;
    wire is_q_reg_read  = (read_addr[7:0] == Q_REG_ADDR) && read_valid;
    
    // 实例化AXI写通道控制器
    axi_write_channel write_ctrl (
        .clk(s_axi_aclk),
        .resetn(s_axi_aresetn),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_bresp(s_axi_bresp),
        .write_valid(write_valid),
        .write_data(write_data),
        .write_addr(write_addr),
        .write_strb(write_strb)
    );

    // 实例化AXI读通道控制器
    axi_read_channel read_ctrl (
        .clk(s_axi_aclk),
        .resetn(s_axi_aresetn),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .read_valid(read_valid),
        .read_addr(read_addr),
        .read_data(read_data)
    );
    
    // D寄存器写逻辑
    assign d_value = is_d_reg_write && write_strb[0] ? write_data[0] : d_buffered;
    
    // Q寄存器读逻辑
    assign read_data = is_q_reg_read ? {31'b0, q_value} : 32'h0;

    // 两级D触发器逻辑实现
    dff_with_async_reset d_buffer_stage (
        .clk(s_axi_aclk),
        .resetn(s_axi_aresetn),
        .d(d_value),
        .q(d_buffered)
    );
    
    dff_with_async_reset q_output_stage (
        .clk(s_axi_aclk),
        .resetn(s_axi_aresetn),
        .d(d_buffered),
        .q(q_value)
    );
    
endmodule

//---------------------------------------------------------------------
// AXI写通道控制器模块
//---------------------------------------------------------------------
module axi_write_channel (
    input  wire        clk,
    input  wire        resetn,
    
    // AXI写接口
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    output reg  [1:0]  s_axi_bresp,
    
    // 内部控制接口
    output wire        write_valid,
    output reg  [31:0] write_addr,
    output reg  [31:0] write_data,
    output reg  [3:0]  write_strb
);

    // 状态定义
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    reg [1:0] state;
    
    // 控制信号
    assign write_valid = (state == DATA);
    
    // FSM实现
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state          <= IDLE;
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            write_addr     <= 32'h0;
            write_data     <= 32'h0;
            write_strb     <= 4'h0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axi_awvalid) begin
                        s_axi_awready <= 1'b1;
                        write_addr    <= s_axi_awaddr;
                        state         <= ADDR;
                    end
                end
                
                ADDR: begin
                    s_axi_awready <= 1'b0;
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        write_data   <= s_axi_wdata;
                        write_strb   <= s_axi_wstrb;
                        state        <= DATA;
                    end
                end
                
                DATA: begin
                    s_axi_wready  <= 1'b0;
                    s_axi_bvalid  <= 1'b1;
                    s_axi_bresp   <= 2'b00;  // OKAY响应
                    state         <= RESP;
                end
                
                RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        state        <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule

//---------------------------------------------------------------------
// AXI读通道控制器模块
//---------------------------------------------------------------------
module axi_read_channel (
    input  wire        clk,
    input  wire        resetn,
    
    // AXI读接口
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    input  wire [31:0] s_axi_araddr,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    
    // 内部控制接口
    output wire        read_valid,
    output reg  [31:0] read_addr,
    input  wire [31:0] read_data
);

    // 状态定义
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    
    reg [1:0] state;
    
    // 控制信号
    assign read_valid = (state == ADDR);
    
    // FSM实现
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state          <= IDLE;
            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rresp    <= 2'b00;
            s_axi_rdata    <= 32'h0;
            read_addr      <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axi_arvalid) begin
                        s_axi_arready <= 1'b1;
                        read_addr     <= s_axi_araddr;
                        state         <= ADDR;
                    end
                end
                
                ADDR: begin
                    s_axi_arready <= 1'b0;
                    s_axi_rvalid  <= 1'b1;
                    s_axi_rresp   <= 2'b00;  // OKAY响应
                    s_axi_rdata   <= read_data;
                    state         <= DATA;
                end
                
                DATA: begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        state        <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule

//---------------------------------------------------------------------
// 带异步复位的D触发器模块
//---------------------------------------------------------------------
module dff_with_async_reset (
    input  wire clk,
    input  wire resetn,
    input  wire d,
    output reg  q
);
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            q <= 1'b0;
        else
            q <= d;
    end
    
endmodule