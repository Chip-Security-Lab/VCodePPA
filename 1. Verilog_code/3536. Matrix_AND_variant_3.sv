//SystemVerilog

module Matrix_AND (
    // AXI-Stream接口 - 输入
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [7:0]  s_axis_tdata,  // 包含row[3:0]和col[3:0]
    input  wire        s_axis_tlast,
    
    // AXI-Stream接口 - 输出
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [7:0]  m_axis_tdata,  // 包含结果
    output wire        m_axis_tlast,
    
    // 系统信号
    input  wire        clk,
    input  wire        rst_n
);
    
    // 内部信号
    wire [3:0] row, col;
    wire [7:0] combined_inputs;
    wire [7:0] pattern;
    wire [7:0] result;
    
    // 状态机状态
    reg [1:0] state, next_state;
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;
    localparam DONE = 2'b10;
    
    // 输入准备就绪信号
    assign s_axis_tready = (state == IDLE);
    
    // 从AXI-Stream输入提取row和col
    assign row = s_axis_tdata[7:4];
    assign col = s_axis_tdata[3:0];
    
    // 状态机逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: 
                if (s_axis_tvalid)
                    next_state = PROCESSING;
            
            PROCESSING: 
                next_state = DONE;
            
            DONE: 
                if (m_axis_tready)
                    next_state = IDLE;
            
            default: 
                next_state = IDLE;
        endcase
    end
    
    // 输出有效信号
    assign m_axis_tvalid = (state == DONE);
    
    // TLAST信号传递
    reg tlast_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tlast_reg <= 1'b0;
        end else if (state == IDLE && s_axis_tvalid) begin
            tlast_reg <= s_axis_tlast;
        end
    end
    assign m_axis_tlast = tlast_reg;
    
    // 原始模块实例化
    InputCombiner input_combiner (
        .row(row),
        .col(col),
        .combined_out(combined_inputs)
    );
    
    PatternGenerator pattern_gen (
        .pattern_out(pattern)
    );
    
    BitwiseOperator bit_operator (
        .input_a(combined_inputs),
        .input_b(pattern),
        .result(result)
    );
    
    // 将结果连接到输出
    assign m_axis_tdata = result;
    
endmodule

module InputCombiner(
    input [3:0] row,
    input [3:0] col,
    output [7:0] combined_out
);
    // 组合行列输入为一个8位向量
    assign combined_out = {row, col};
endmodule

module PatternGenerator(
    output [7:0] pattern_out
);
    // 生成固定模式
    assign pattern_out = 8'h55; // 01010101二进制模式
endmodule

module BitwiseOperator(
    input [7:0] input_a,
    input [7:0] input_b,
    output [7:0] result
);
    // 执行按位与操作
    assign result = input_a & input_b;
endmodule