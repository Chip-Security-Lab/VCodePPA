//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
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
    
    // 前向寄存器重定时 - 提前捕获输入信号
    reg sda_reg, scl_reg;
    
    // 移动后的信号检测逻辑
    reg start_cond;
    reg addr_done;
    
    // 扇出缓冲寄存器
    reg [1:0] layer0_state_buf1, layer0_state_buf2;
    reg [1:0] layer1_state_buf1, layer1_state_buf2;
    reg LAYER0_IDLE_buf1, LAYER0_IDLE_buf2;
    reg LAYER1_WRITE_buf1, LAYER1_WRITE_buf2;
    reg b0; // 高扇出信号示例
    reg b0_buf1, b0_buf2, b0_buf3;
    
    // 初始化状态
    initial begin
        layer0_state = LAYER0_IDLE;
        layer1_state = LAYER1_WRITE;
        layer_activate = 1'b0;
        debug_state = 8'h00;
        
        // 初始化输入寄存器
        sda_reg = 1'b1;
        scl_reg = 1'b1;
        
        // 缓冲寄存器初始化
        layer0_state_buf1 = LAYER0_IDLE;
        layer0_state_buf2 = LAYER0_IDLE;
        layer1_state_buf1 = LAYER1_WRITE;
        layer1_state_buf2 = LAYER1_WRITE;
        LAYER0_IDLE_buf1 = 1'b1;
        LAYER0_IDLE_buf2 = 1'b1;
        LAYER1_WRITE_buf1 = 1'b1;
        LAYER1_WRITE_buf2 = 1'b1;
        b0 = 1'b0;
        b0_buf1 = 1'b0;
        b0_buf2 = 1'b0;
        b0_buf3 = 1'b0;
    end

    // 前向寄存器重定时 - 在前端捕获输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_reg <= 1'b1;
            scl_reg <= 1'b1;
        end else begin
            sda_reg <= sda;
            scl_reg <= scl;
        end
    end

    // 高扇出信号缓冲器
    always @(posedge clk) begin
        // 状态信号缓冲
        layer0_state_buf1 <= layer0_state;
        layer0_state_buf2 <= layer0_state_buf1;
        layer1_state_buf1 <= layer1_state;
        layer1_state_buf2 <= layer1_state_buf1;
        
        // 常量缓冲
        LAYER0_IDLE_buf1 <= LAYER0_IDLE;
        LAYER0_IDLE_buf2 <= LAYER0_IDLE_buf1;
        LAYER1_WRITE_buf1 <= LAYER1_WRITE;
        LAYER1_WRITE_buf2 <= LAYER1_WRITE_buf1;
        
        // 其他高扇出信号缓冲
        b0_buf1 <= b0;
        b0_buf2 <= b0_buf1;
        b0_buf3 <= b0_buf2;
    end

    // 添加状态检测逻辑 - 现在使用已寄存的输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_cond <= 1'b0;
            addr_done <= 1'b0;
        end else begin
            // SDA下降沿检测 (当SCL为高时) - 使用寄存的输入
            start_cond <= (scl_reg && !sda_reg);
            
            // 地址完成检测 - 使用缓冲的状态信号减少负载
            addr_done <= (layer0_state_buf1 == LAYER0_ADDR && layer1_state_buf1 == LAYER1_ACK);
        end
    end

    // 分层状态转换
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            layer0_state <= LAYER0_IDLE;
            layer1_state <= LAYER1_WRITE;
            layer_activate <= 1'b0;
            debug_state <= 8'h00;
            b0 <= 1'b0;
        end else begin
            case(layer0_state)
                LAYER0_IDLE_buf1: begin  // 使用缓冲的常量
                    if (start_cond) begin
                        layer0_state <= LAYER0_ADDR;
                        layer_activate <= 1'b1;
                        b0 <= 1'b1;
                    end
                end
                LAYER0_ADDR: begin
                    if (addr_done) begin
                        layer0_state <= LAYER0_DATA;
                        layer_activate <= 1'b0;
                        b0 <= 1'b0;
                    end
                end
                LAYER0_DATA: begin
                    // 可以添加更多状态转换逻辑
                end
                default: begin
                    layer0_state <= LAYER0_IDLE_buf2;  // 使用缓冲的常量
                end
            endcase

            if (layer_activate) begin
                case(layer1_state)
                    LAYER1_WRITE_buf1: begin  // 使用缓冲的常量
                        // 数据写入处理
                        layer1_state <= LAYER1_ACK;
                    end
                    LAYER1_READ: begin
                        // 数据读取处理
                    end
                    LAYER1_ACK: begin
                        layer1_state <= LAYER1_WRITE_buf2;  // 使用缓冲的常量
                    end
                    default: begin
                        layer1_state <= LAYER1_WRITE_buf2;  // 使用缓冲的常量
                    end
                endcase
            end
            
            // 更新调试状态 - 使用寄存的输入信号和缓冲的信号
            debug_state <= {layer0_state_buf2, layer1_state_buf2, b0_buf3, b0_buf2, sda_reg, scl_reg};
        end
    end
endmodule