//SystemVerilog
module usb_pid_decoder(
    // AXI-Stream 输入接口
    input wire aclk,                    // 时钟信号
    input wire aresetn,                 // 异步复位信号，低电平有效
    
    // S_AXIS 输入接口
    input wire s_axis_tvalid,           // 输入数据有效
    output reg s_axis_tready,           // 模块准备好接收数据
    input wire [7:0] s_axis_tdata,      // 输入数据通道
    input wire s_axis_tlast,            // 指示最后一个传输数据
    
    // M_AXIS 输出接口
    output reg m_axis_tvalid,           // 输出数据有效
    input wire m_axis_tready,           // 下游模块准备好接收数据
    output reg [7:0] m_axis_tdata,      // 输出数据通道
    output reg m_axis_tlast             // 指示最后一个传输数据
);

    // 内部信号
    reg [3:0] pid;
    reg [3:0] multiplier_a;
    reg [3:0] multiplier_b;
    wire [7:0] product;
    
    // 预解码PID类型信号 - 分解关键路径
    reg token_type;
    reg data_type;
    reg handshake_type;
    reg special_type;
    reg [1:0] pid_type;
    
    // 输入接口处理状态机
    localparam IDLE = 2'b00;
    localparam GET_PID = 2'b01;
    localparam GET_MULT_A = 2'b10;
    localparam GET_MULT_B = 2'b11;
    
    reg [1:0] state, next_state;
    
    // 状态转换优化 - 简化组合路径
    wire idle_to_pid = (state == IDLE) && s_axis_tvalid && s_axis_tready;
    wire pid_to_mult_a = (state == GET_PID) && s_axis_tvalid && s_axis_tready;
    wire mult_a_to_mult_b = (state == GET_MULT_A) && s_axis_tvalid && s_axis_tready;
    wire mult_b_to_idle = (state == GET_MULT_B) && s_axis_tvalid && s_axis_tready;
    
    // 优化状态机组合逻辑 - 减少关键路径长度
    always @(*) begin
        case (state)
            IDLE:      next_state = idle_to_pid ? GET_PID : IDLE;
            GET_PID:   next_state = pid_to_mult_a ? GET_MULT_A : GET_PID;
            GET_MULT_A: next_state = mult_a_to_mult_b ? GET_MULT_B : GET_MULT_A;
            GET_MULT_B: next_state = mult_b_to_idle ? IDLE : GET_MULT_B;
            default:   next_state = IDLE;
        endcase
    end
    
    // 状态机时序逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
            pid <= 4'b0000;
            multiplier_a <= 4'b0000;
            multiplier_b <= 4'b0000;
            s_axis_tready <= 1'b0;
        end else begin
            state <= next_state;
            
            // 优化条件逻辑 - 减少嵌套
            s_axis_tready <= (state == IDLE) || (state == GET_PID) || 
                             (state == GET_MULT_A) || 
                             ((state == GET_MULT_B) && !(s_axis_tvalid && s_axis_tready));
            
            // 数据捕获 - 减少条件判断链
            if (state == GET_PID && s_axis_tvalid && s_axis_tready)
                pid <= s_axis_tdata[3:0];
                
            if (state == GET_MULT_A && s_axis_tvalid && s_axis_tready)
                multiplier_a <= s_axis_tdata[3:0];
                
            if (state == GET_MULT_B && s_axis_tvalid && s_axis_tready)
                multiplier_b <= s_axis_tdata[3:0];
        end
    end
    
    // PID 解码逻辑优化 - 使用查找表减少关键路径长度
    reg [3:0] pid_decoded;
    always @(*) begin
        // 通过查找表方式优化pid解码
        case(pid[3:0])
            4'b0001: pid_decoded = 4'b1000; // OUT (token_type=1)
            4'b1001: pid_decoded = 4'b1000; // IN (token_type=1)
            4'b0101: pid_decoded = 4'b1000; // SOF (token_type=1)
            4'b1101: pid_decoded = 4'b1000; // SETUP (token_type=1)
            4'b0011: pid_decoded = 4'b0100; // DATA0 (data_type=1)
            4'b1011: pid_decoded = 4'b0100; // DATA1 (data_type=1)
            4'b0010: pid_decoded = 4'b0010; // ACK (handshake_type=1)
            4'b1010: pid_decoded = 4'b0010; // NAK (handshake_type=1)
            4'b0110: pid_decoded = 4'b0001; // SPLIT (special_type=1)
            default: pid_decoded = 4'b0000; // None
        endcase
        
        // 并行解码输出信号
        token_type = pid_decoded[3];
        data_type = pid_decoded[2];
        handshake_type = pid_decoded[1];
        special_type = pid_decoded[0];
        pid_type = pid[1:0];
    end
    
    // 输出接口管理
    reg output_ready;
    reg [2:0] output_state;
    
    localparam OUT_IDLE = 3'b000;
    localparam OUT_TOKEN = 3'b001;
    localparam OUT_DATA = 3'b010;
    localparam OUT_HANDSHAKE = 3'b011;
    localparam OUT_SPECIAL = 3'b100;
    localparam OUT_PRODUCT = 3'b101;
    
    // 输出状态转换条件 - 优化关键路径
    wire start_output = (state == GET_MULT_B) && s_axis_tvalid && s_axis_tready;
    wire next_output_stage = m_axis_tready && m_axis_tvalid;
    
    // 输出状态机时序逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            output_state <= OUT_IDLE;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 8'b0;
            m_axis_tlast <= 1'b0;
            output_ready <= 1'b0;
        end else begin
            case (output_state)
                OUT_IDLE: begin
                    if (start_output) begin
                        output_state <= OUT_TOKEN;
                        output_ready <= 1'b1;
                        m_axis_tvalid <= 1'b0;
                    end
                end
                
                OUT_TOKEN: begin
                    m_axis_tvalid <= output_ready;
                    m_axis_tdata <= {7'b0, token_type};
                    m_axis_tlast <= 1'b0;
                    
                    if (next_output_stage) begin
                        output_state <= OUT_DATA;
                    end
                end
                
                OUT_DATA: begin
                    m_axis_tvalid <= 1'b1;
                    m_axis_tdata <= {7'b0, data_type};
                    m_axis_tlast <= 1'b0;
                    
                    if (next_output_stage) begin
                        output_state <= OUT_HANDSHAKE;
                    end
                end
                
                OUT_HANDSHAKE: begin
                    m_axis_tvalid <= 1'b1;
                    m_axis_tdata <= {7'b0, handshake_type};
                    m_axis_tlast <= 1'b0;
                    
                    if (next_output_stage) begin
                        output_state <= OUT_SPECIAL;
                    end
                end
                
                OUT_SPECIAL: begin
                    m_axis_tvalid <= 1'b1;
                    m_axis_tdata <= {6'b0, pid_type};
                    m_axis_tlast <= 1'b0;
                    
                    if (next_output_stage) begin
                        output_state <= OUT_PRODUCT;
                    end
                end
                
                OUT_PRODUCT: begin
                    m_axis_tvalid <= 1'b1;
                    m_axis_tdata <= product;
                    m_axis_tlast <= 1'b1;
                    
                    if (next_output_stage) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        output_ready <= 1'b0;
                        output_state <= OUT_IDLE;
                    end
                end
                
                default: output_state <= OUT_IDLE;
            endcase
        end
    end
    
    // 实例化优化后的 Karatsuba 乘法器
    optimized_karatsuba_multiplier_4bit kmult(
        .a(multiplier_a),
        .b(multiplier_b),
        .product(product)
    );
endmodule

// 优化的 Karatsuba 乘法器 - 4-bit输入
module optimized_karatsuba_multiplier_4bit(
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] product
);
    // 将输入分割为高位和低位部分（各2位）
    wire [1:0] a_high, a_low, b_high, b_low;
    assign a_high = a[3:2];
    assign a_low  = a[1:0];
    assign b_high = b[3:2];
    assign b_low  = b[1:0];
    
    // 并行计算部分积，减少关键路径
    wire [3:0] z0, z2;
    wire [3:0] a_sum, b_sum, sum_product;
    
    // 直接乘法 - 并行处理
    assign z0 = a_low * b_low;    // 低位 * 低位
    assign z2 = a_high * b_high;  // 高位 * 高位
    
    // 优化a_sum和b_sum的计算 - 并行直接计算
    assign a_sum = {2'b0, a_low} + {2'b0, a_high};
    assign b_sum = {2'b0, b_low} + {2'b0, b_high};
    assign sum_product = a_sum * b_sum;
    
    // 优化z1计算 - 减少运算深度
    wire [3:0] z1 = sum_product - z0 - z2;
    
    // 优化最终乘积计算 - 减少关键路径延迟
    // 并行处理三个部分，然后合并
    wire [7:0] part0 = {4'b0, z0};
    wire [7:0] part1 = {2'b0, z1, 2'b0};
    wire [7:0] part2 = {z2, 4'b0};
    
    // 两级加法树 - 平衡关键路径
    wire [7:0] sum_stage1 = part0 + part1;
    assign product = sum_stage1 + part2;
endmodule