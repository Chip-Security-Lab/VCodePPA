//SystemVerilog
//IEEE 1364-2005
module i2c_layered_fsm #(
    parameter FSM_LAYERS = 2
)(
    input clk,
    input rst_n,
    inout sda,
    inout scl,
    output reg [7:0] debug_state
);
    // 分层状态机控制 - 使用独冷编码
    // 独冷编码：只有一位为0，其余位为1
    localparam [3:0] LAYER0_IDLE = 4'b1110, // 状态0
                     LAYER0_ADDR = 4'b1101, // 状态1
                     LAYER0_DATA = 4'b1011; // 状态2
                     // 第四种状态 4'b0111 未使用

    localparam [3:0] LAYER1_WRITE = 4'b1110, // 状态0
                     LAYER1_READ  = 4'b1101, // 状态1
                     LAYER1_ACK   = 4'b1011; // 状态2
                     // 第四种状态 4'b0111 未使用

    reg [3:0] layer0_state, layer0_next;
    reg [3:0] layer1_state, layer1_next;
    reg layer_activate, layer_activate_next;
    
    // 状态检测信号
    reg start_cond;
    reg addr_done;
    wire sda_falling_edge;
    
    // 优化的状态检测逻辑
    assign sda_falling_edge = scl && !sda;
    
    // 状态检测逻辑 - 使用非阻塞赋值以改善时序
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_cond <= 1'b0;
            addr_done <= 1'b0;
        end else begin
            // 使用组合逻辑检测开始条件
            start_cond <= sda_falling_edge;
            
            // 优化地址完成检测 - 使用独冷编码进行状态比较
            addr_done <= (layer0_state == LAYER0_ADDR && layer1_state == LAYER1_ACK);
        end
    end

    // 组合逻辑计算下一状态 - 分离组合逻辑和时序逻辑提高效率
    always @(*) begin
        // 默认保持当前状态
        layer0_next = layer0_state;
        layer1_next = layer1_state;
        layer_activate_next = layer_activate;
        
        // Layer 0 状态转换 - 使用独冷编码
        case(layer0_state)
            LAYER0_IDLE: begin
                if (start_cond) begin
                    layer0_next = LAYER0_ADDR;
                    layer_activate_next = 1'b1;
                end
            end
            
            LAYER0_ADDR: begin
                if (addr_done) begin
                    layer0_next = LAYER0_DATA;
                    layer_activate_next = 1'b0;
                end
            end
            
            LAYER0_DATA: begin
                // 可以添加更多状态转换逻辑
            end
            
            default: begin
                layer0_next = LAYER0_IDLE;
            end
        endcase

        // Layer 1 状态转换 - 条件优化
        if (layer_activate) begin
            case(layer1_state)
                LAYER1_WRITE: layer1_next = LAYER1_ACK;  // 简化赋值
                LAYER1_READ: begin
                    // 数据读取处理
                end
                LAYER1_ACK: layer1_next = LAYER1_WRITE;  // 简化赋值
                default: layer1_next = LAYER1_WRITE;
            endcase
        end
    end

    // 时序逻辑更新状态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer0_state <= LAYER0_IDLE;
            layer1_state <= LAYER1_WRITE;
            layer_activate <= 1'b0;
            debug_state <= 8'h00;
        end else begin
            layer0_state <= layer0_next;
            layer1_state <= layer1_next;
            layer_activate <= layer_activate_next;
            
            // 更新调试状态 - 为了保持与原代码兼容，将独冷编码转回原始形式用于debug
            debug_state <= {
                ~layer0_next[3] & ~layer0_next[2], // 第0位为0时为IDLE, 第1位为0时为ADDR
                ~layer0_next[1] & ~layer0_next[0], // 第2位为0时为DATA
                ~layer1_next[3] & ~layer1_next[2], // 第0位为0时为WRITE, 第1位为0时为READ
                ~layer1_next[1] & ~layer1_next[0], // 第2位为0时为ACK
                2'b00, sda, scl
            };
        end
    end
    
endmodule