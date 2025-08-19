//SystemVerilog
//IEEE 1364-2005
module and_xor_xnor_gate (
    input  wire        clk,           // 时钟信号
    input  wire        rst_n,         // 复位信号，低电平有效
    
    // AXI4-Lite 接口
    // 写地址通道
    input  wire        s_axil_awvalid,
    output reg         s_axil_awready,
    input  wire [31:0] s_axil_awaddr,
    input  wire [2:0]  s_axil_awprot,
    
    // 写数据通道
    input  wire        s_axil_wvalid,
    output reg         s_axil_wready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    
    // 写响应通道
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    output reg [1:0]   s_axil_bresp,
    
    // 读地址通道
    input  wire        s_axil_arvalid,
    output reg         s_axil_arready,
    input  wire [31:0] s_axil_araddr,
    input  wire [2:0]  s_axil_arprot,
    
    // 读数据通道
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready,
    output reg [31:0]  s_axil_rdata,
    output reg [1:0]   s_axil_rresp,
    
    // 输出结果
    output wire        Y
);

    // 内部寄存器
    reg  A, B, C;
    reg  and_result;
    reg  xnor_result;
    reg  xor_result;
    reg  y_reg;
    
    // 寄存器地址
    localparam ADDR_A         = 4'h0; // 输入A寄存器
    localparam ADDR_B         = 4'h4; // 输入B寄存器
    localparam ADDR_C         = 4'h8; // 输入C寄存器
    localparam ADDR_RESULT    = 4'hC; // 结果寄存器
    
    // AXI-Lite 写状态机
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    reg [1:0] write_state;
    reg [3:0] write_addr;
    
    // AXI-Lite 读状态机
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    reg [1:0] read_state;
    reg [3:0] read_addr;
    
    // 输出连接
    assign Y = y_reg;
    
    // AXI4-Lite 写状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state    <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            s_axil_bvalid  <= 1'b0;
            s_axil_bresp   <= 2'b00;
            write_addr     <= 4'h0;
            A              <= 1'b0;
            B              <= 1'b0;
            C              <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (s_axil_awvalid) begin
                        s_axil_awready <= 1'b1;
                        write_addr     <= s_axil_awaddr[3:0];
                        write_state    <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    s_axil_awready <= 1'b0;
                    if (s_axil_wvalid) begin
                        s_axil_wready <= 1'b1;
                        write_state   <= WRITE_DATA;
                        
                        // 写入寄存器
                        case (write_addr)
                            ADDR_A: A <= s_axil_wdata[0];
                            ADDR_B: B <= s_axil_wdata[0];
                            ADDR_C: C <= s_axil_wdata[0];
                            default: ; // 其他地址不处理
                        endcase
                    end
                end
                
                WRITE_DATA: begin
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b1;
                    s_axil_bresp  <= 2'b00; // OKAY响应
                    write_state   <= WRITE_RESP;
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        write_state   <= WRITE_IDLE;
                    end
                end
            endcase
        end
    end
    
    // AXI4-Lite 读状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state     <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid  <= 1'b0;
            s_axil_rdata   <= 32'h0;
            s_axil_rresp   <= 2'b00;
            read_addr      <= 4'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b1;
                        read_addr      <= s_axil_araddr[3:0];
                        read_state     <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    s_axil_arready <= 1'b0;
                    s_axil_rvalid  <= 1'b1;
                    s_axil_rresp   <= 2'b00; // OKAY响应
                    
                    // 读取寄存器
                    case (read_addr)
                        ADDR_A:      s_axil_rdata <= {31'b0, A};
                        ADDR_B:      s_axil_rdata <= {31'b0, B};
                        ADDR_C:      s_axil_rdata <= {31'b0, C};
                        ADDR_RESULT: s_axil_rdata <= {31'b0, y_reg};
                        default:     s_axil_rdata <= 32'h0;
                    endcase
                    
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state    <= READ_IDLE;
                    end
                end
            endcase
        end
    end
    
    // 第一级流水线 - 计算基本逻辑运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result  <= 1'b0;
            xnor_result <= 1'b0;
        end else begin
            and_result  <= A & B;           // 计算A和B的与运算
            xnor_result <= ~(C ^ A);        // 计算C和A的同或运算
        end
    end

    // 第二级流水线 - 组合中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result <= 1'b0;
        end else begin
            xor_result <= and_result ^ xnor_result; // 计算最终的异或运算
        end
    end

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_reg <= 1'b0;
        end else begin
            y_reg <= xor_result;            // 将结果输出到Y
        end
    end

endmodule