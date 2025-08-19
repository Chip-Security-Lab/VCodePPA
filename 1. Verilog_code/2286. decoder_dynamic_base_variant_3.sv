//SystemVerilog
//IEEE 1364-2005 Verilog
//----------------------------------------------------------------------
// 顶层模块：地址解码器 (AXI-Stream接口)
//----------------------------------------------------------------------
module decoder_dynamic_base (
    input  wire        clk,        // 时钟信号
    input  wire        rst_n,      // 复位信号，低电平有效
    
    // AXI-Stream 输入接口
    input  wire [7:0]  s_axis_tdata,  // 输入数据，包含base_addr和current_addr
    input  wire        s_axis_tvalid, // 输入数据有效
    output wire        s_axis_tready, // 模块准备好接收数据
    input  wire        s_axis_tlast,  // 输入包结束标志
    
    // AXI-Stream 输出接口
    output wire        m_axis_tdata,  // 输出数据 (sel信号)
    output wire        m_axis_tvalid, // 输出数据有效
    input  wire        m_axis_tready, // 下游模块准备好接收数据
    output wire        m_axis_tlast   // 输出包结束标志
);

    // 内部寄存器和信号
    reg  [7:0] base_addr_reg;
    reg  [7:0] current_addr_reg;
    wire       sel_wire;
    reg        data_valid;
    reg        tlast_reg;
    
    // 状态机状态定义
    localparam IDLE = 2'b00;
    localparam RECEIVE_BASE = 2'b01;
    localparam RECEIVE_CURRENT = 2'b10;
    localparam PROCESSING = 2'b11;
    
    reg [1:0] state, next_state;
    
    // 生成s_axis_tready信号
    assign s_axis_tready = (state == IDLE || state == RECEIVE_BASE) && !data_valid;
    
    // 状态机：接收和处理数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            base_addr_reg <= 8'h0;
            current_addr_reg <= 8'h0;
            data_valid <= 1'b0;
            tlast_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        base_addr_reg <= s_axis_tdata;
                        tlast_reg <= s_axis_tlast;
                        state <= RECEIVE_BASE;
                    end
                end
                
                RECEIVE_BASE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        current_addr_reg <= s_axis_tdata;
                        tlast_reg <= s_axis_tlast;
                        state <= PROCESSING;
                        data_valid <= 1'b1;
                    end
                end
                
                PROCESSING: begin
                    if (m_axis_tready && m_axis_tvalid) begin
                        data_valid <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // 连接到子模块
    wire [3:0] base_high;
    wire [3:0] current_high;
    
    // 实例化地址提取子模块
    address_extractor addr_extract (
        .addr_in1(base_addr_reg),
        .addr_in2(current_addr_reg),
        .high_bits1(base_high),
        .high_bits2(current_high)
    );
    
    // 实例化地址比较子模块
    address_comparator addr_compare (
        .addr1(base_high),
        .addr2(current_high),
        .match(sel_wire)
    );
    
    // 连接AXI-Stream输出接口
    assign m_axis_tdata = sel_wire;
    assign m_axis_tvalid = data_valid;
    assign m_axis_tlast = tlast_reg;
    
endmodule

//----------------------------------------------------------------------
// 子模块：地址高位提取 (优化版)
//----------------------------------------------------------------------
module address_extractor (
    input  wire [7:0] addr_in1,
    input  wire [7:0] addr_in2,
    output wire [3:0] high_bits1,
    output wire [3:0] high_bits2
);
    // 提取输入地址的高4位
    assign high_bits1 = addr_in1[7:4];
    assign high_bits2 = addr_in2[7:4];
    
endmodule

//----------------------------------------------------------------------
// 子模块：地址比较器 (优化版)
//----------------------------------------------------------------------
module address_comparator (
    input  wire [3:0] addr1,
    input  wire [3:0] addr2,
    output wire       match
);
    // 使用连续赋值而非always块，提高性能
    assign match = (addr1 == addr2);
    
endmodule