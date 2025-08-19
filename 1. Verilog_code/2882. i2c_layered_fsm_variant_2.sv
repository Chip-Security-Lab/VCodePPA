//SystemVerilog
module i2c_layered_fsm #(
    parameter FSM_LAYERS = 2
)(
    input wire clk,
    input wire rst_n,
    inout wire sda,
    inout wire scl,
    output reg [7:0] debug_state
);
    // 分层状态机控制
    localparam LAYER0_IDLE = 2'b00;
    localparam LAYER0_ADDR = 2'b01;
    localparam LAYER0_DATA = 2'b10;

    localparam LAYER1_WRITE = 2'b00;
    localparam LAYER1_READ = 2'b01;
    localparam LAYER1_ACK = 2'b10;

    // 流水线阶段寄存器 - 重定时后的状态寄存器
    reg [1:0] layer0_state;
    reg [1:0] layer1_state;
    reg layer_activate;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 信号检测寄存器 - 移动到组合逻辑之前
    reg start_cond;
    reg addr_done;
    
    // SDA/SCL 寄存器 - 移动到组合逻辑之前
    reg sda_in;
    reg scl_in;
    
    // 下一状态组合逻辑信号 - 取代了流水线寄存器
    reg [1:0] next_layer0_state;
    reg [1:0] next_layer1_state;
    reg next_layer_activate;
    
    // 调试状态组合逻辑
    reg [7:0] next_debug_state;

    // 输入采样 - 移动寄存器到组合逻辑之前
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_in <= 1'b1;
            scl_in <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            // 采样I2C信号
            sda_in <= sda;
            scl_in <= scl;
            
            // 总是有效
            valid_stage1 <= 1'b1;
        end
    end

    // 信号检测 - 使用组合逻辑替代流水线
    always @(*) begin
        // SDA下降沿检测 (当SCL为高时)
        start_cond = (scl_in && !sda_in);
        
        // 地址完成检测
        addr_done = (layer0_state == LAYER0_ADDR && layer1_state == LAYER1_ACK);
    end

    // 状态计算组合逻辑 - 替代流水线寄存器
    always @(*) begin
        // 默认保持当前状态
        next_layer0_state = layer0_state;
        next_layer1_state = layer1_state;
        next_layer_activate = layer_activate;
        
        // 状态计算逻辑
        case(layer0_state)
            LAYER0_IDLE: begin
                if (start_cond) begin
                    next_layer0_state = LAYER0_ADDR;
                    next_layer_activate = 1'b1;
                end
            end
            LAYER0_ADDR: begin
                if (addr_done) begin
                    next_layer0_state = LAYER0_DATA;
                    next_layer_activate = 1'b0;
                end
            end
            LAYER0_DATA: begin
                // 可以添加更多状态转换逻辑
            end
            default: begin
                next_layer0_state = LAYER0_IDLE;
                next_layer_activate = 1'b0;
            end
        endcase

        if (layer_activate) begin
            case(layer1_state)
                LAYER1_WRITE: begin
                    // 数据写入处理
                    next_layer1_state = LAYER1_ACK;
                end
                LAYER1_READ: begin
                    // 数据读取处理
                end
                LAYER1_ACK: begin
                    next_layer1_state = LAYER1_WRITE;
                end
                default: begin
                    next_layer1_state = LAYER1_WRITE;
                end
            endcase
        end
        
        // 生成调试输出组合逻辑
        next_debug_state = {next_layer0_state, next_layer1_state, 2'b00, sda_in, scl_in};
    end
    
    // 状态更新和输出生成 - 合并流水线阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer0_state <= LAYER0_IDLE;
            layer1_state <= LAYER1_WRITE;
            layer_activate <= 1'b0;
            debug_state <= 8'h00;
        end else if (valid_stage1) begin
            // 更新状态寄存器
            layer0_state <= next_layer0_state;
            layer1_state <= next_layer1_state;
            layer_activate <= next_layer_activate;
            
            // 更新调试输出
            debug_state <= next_debug_state;
        end
    end
    
    // 初始化状态
    initial begin
        layer0_state = LAYER0_IDLE;
        layer1_state = LAYER1_WRITE;
        layer_activate = 1'b0;
        valid_stage1 = 1'b0;
        valid_stage2 = 1'b0;
        debug_state = 8'h00;
    end
endmodule