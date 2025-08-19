//SystemVerilog
module des_cbc_async (
    input wire clk,         // 时钟信号
    input wire rst_n,       // 复位信号，低电平有效
    
    // 输入数据接口 - Valid-Ready握手
    input wire [63:0] din,  // 输入数据
    input wire [63:0] iv,   // 初始向量
    input wire [55:0] key,  // 密钥
    input wire       din_valid, // 输入数据有效信号
    output reg       din_ready, // 输入数据就绪信号
    
    // 输出数据接口 - Valid-Ready握手
    output reg [63:0] dout,     // 输出数据
    output reg        dout_valid, // 输出数据有效信号
    input wire        dout_ready   // 输出数据就绪信号
);

    // 内部信号和寄存器
    reg [63:0] xor_stage;
    reg [63:0] xor_stage_reg; // 流水线寄存器1
    reg [31:0] feistel_key_xor; // 流水线寄存器2
    reg [63:0] feistel_out;
    reg        processing;

    // 状态机定义
    localparam IDLE = 2'b00;
    localparam PROCESS_STAGE1 = 2'b01;
    localparam PROCESS_STAGE2 = 2'b11;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 状态机转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= IDLE;
        else 
            state <= next_state;
    end
    
    // 状态转换和信号控制
    always @(*) begin
        next_state = state;
        din_ready = 1'b0;
        dout_valid = 1'b0;
        
        case (state)
            IDLE: begin
                din_ready = 1'b1;
                if (din_valid && din_ready) begin
                    next_state = PROCESS_STAGE1;
                end
            end
            
            PROCESS_STAGE1: begin
                next_state = PROCESS_STAGE2;
            end
            
            PROCESS_STAGE2: begin
                next_state = DONE;
            end
            
            DONE: begin
                dout_valid = 1'b1;
                if (dout_valid && dout_ready) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理逻辑 - 流水线化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage <= 64'b0;
            xor_stage_reg <= 64'b0;
            feistel_key_xor <= 32'b0;
            feistel_out <= 64'b0;
            dout <= 64'b0;
            processing <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (din_valid && din_ready) begin
                        // 第一阶段：计算XOR
                        xor_stage <= din ^ iv;
                        processing <= 1'b1;
                    end
                end
                
                PROCESS_STAGE1: begin
                    if (processing) begin
                        // 存储第一阶段结果到流水线寄存器
                        xor_stage_reg <= xor_stage;
                        // 开始第二阶段计算的一部分
                        feistel_key_xor <= xor_stage[63:32] ^ key[31:0];
                    end
                end
                
                PROCESS_STAGE2: begin
                    // 完成Feistel网络计算
                    feistel_out <= {xor_stage_reg[31:0], feistel_key_xor};
                    // 计算最终输出
                    dout <= {feistel_out[15:0], feistel_out[63:16]};
                end
                
                DONE: begin
                    if (dout_valid && dout_ready) begin
                        // 重置处理状态
                        processing <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule