module i2c_layered_fsm #(
    parameter FSM_LAYERS = 2
)(
    input clk,
    input rst_n,
    inout sda,
    inout scl,
    output reg [7:0] debug_state
);
    // 分层状态机控制 - 替换枚举类型
    localparam LAYER0_IDLE = 2'b00;
    localparam LAYER0_ADDR = 2'b01;
    localparam LAYER0_DATA = 2'b10;

    localparam LAYER1_WRITE = 2'b00;
    localparam LAYER1_READ = 2'b01;
    localparam LAYER1_ACK = 2'b10;

    reg [1:0] layer0_state;
    reg [1:0] layer1_state;
    reg layer_activate;
    
    // 添加缺失的信号
    reg start_cond;
    reg addr_done;
    
    // 初始化状态
    initial begin
        layer0_state = LAYER0_IDLE;
        layer1_state = LAYER1_WRITE;
        layer_activate = 1'b0;
        debug_state = 8'h00;
    end

    // 添加状态检测逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_cond <= 1'b0;
            addr_done <= 1'b0;
        end else begin
            // SDA下降沿检测 (当SCL为高时)
            start_cond <= (scl && !sda);
            
            // 地址完成检测
            addr_done <= (layer0_state == LAYER0_ADDR && layer1_state == LAYER1_ACK);
        end
    end

    // 分层状态转换
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer0_state <= LAYER0_IDLE;
            layer1_state <= LAYER1_WRITE;
            layer_activate <= 1'b0;
            debug_state <= 8'h00;
        end else begin
            case(layer0_state)
                LAYER0_IDLE: begin
                    if (start_cond) begin
                        layer0_state <= LAYER0_ADDR;
                        layer_activate <= 1'b1;
                    end
                end
                LAYER0_ADDR: begin
                    if (addr_done) begin
                        layer0_state <= LAYER0_DATA;
                        layer_activate <= 1'b0;
                    end
                end
                LAYER0_DATA: begin
                    // 可以添加更多状态转换逻辑
                end
                default: begin
                    layer0_state <= LAYER0_IDLE;
                end
            endcase

            if (layer_activate) begin
                case(layer1_state)
                    LAYER1_WRITE: begin
                        // 数据写入处理
                        layer1_state <= LAYER1_ACK;
                    end
                    LAYER1_READ: begin
                        // 数据读取处理
                    end
                    LAYER1_ACK: begin
                        layer1_state <= LAYER1_WRITE;
                    end
                    default: begin
                        layer1_state <= LAYER1_WRITE;
                    end
                endcase
            end
            
            // 更新调试状态
            debug_state <= {layer0_state, layer1_state, 2'b00, sda, scl};
        end
    end
endmodule