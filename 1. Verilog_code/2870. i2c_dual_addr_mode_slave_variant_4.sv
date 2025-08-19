//SystemVerilog
module i2c_dual_addr_slave(
    input wire clk, rst_n,
    input wire [6:0] addr_7bit,
    input wire [9:0] addr_10bit,
    input wire addr_mode, // 0=7bit, 1=10bit
    output reg [7:0] data_rx,
    output reg data_valid,
    inout wire sda, scl
);
    // 状态定义
    localparam IDLE = 3'b000;
    localparam ADDR_RECEIVE = 3'b001;
    localparam DATA_RECEIVE = 3'b010;
    localparam ACK_SEND = 3'b011;
    localparam ADDR_10BIT = 3'b100;
    
    reg [2:0] state, next_state;
    reg [9:0] addr_buffer;
    reg [7:0] data_buffer;
    reg [3:0] bit_count;
    reg sda_out, sda_oe;
    
    // SDA线控制
    assign sda = sda_oe ? 1'bz : sda_out;
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                // 检测开始条件后进入地址接收状态
                if (scl && sda_oe && !sda) begin
                    next_state = ADDR_RECEIVE;
                end
            end
            
            ADDR_RECEIVE: begin
                if (bit_count == 4'd8) begin
                    if (!addr_mode) begin
                        if (addr_buffer[7:1] == addr_7bit) begin
                            next_state = DATA_RECEIVE;
                        end else begin
                            next_state = IDLE; // 地址不匹配
                        end
                    end else begin
                        if (addr_buffer[7:1] == 10'b1111000000) begin
                            next_state = ADDR_10BIT; // 10-bit地址第一个字节
                        end else begin
                            next_state = IDLE; // 地址不匹配
                        end
                    end
                end
            end
            
            ADDR_10BIT: begin
                // 处理10位地址的第二个字节
                if (bit_count == 4'd8) begin
                    if (addr_buffer[7:0] == addr_10bit[7:0]) begin
                        next_state = DATA_RECEIVE;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            
            DATA_RECEIVE: begin
                if (bit_count == 4'd8) begin
                    next_state = ACK_SEND;
                end
            end
            
            ACK_SEND: begin
                next_state = DATA_RECEIVE;
                // 检测停止条件
                if (scl && !sda_oe && sda) begin
                    next_state = IDLE;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // 位计数器控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 4'd0;
        end else begin
            if (state == IDLE) begin
                bit_count <= 4'd0;
            end else if (scl) begin
                if (bit_count < 4'd8) begin
                    bit_count <= bit_count + 1'b1;
                end else begin
                    bit_count <= 4'd0;
                end
            end
        end
    end
    
    // 数据接收逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_buffer <= 10'b0;
            data_buffer <= 8'b0;
        end else if (scl && bit_count < 4'd8) begin
            if (state == ADDR_RECEIVE) begin
                addr_buffer <= {addr_buffer[8:0], sda};
            end else if (state == ADDR_10BIT) begin
                addr_buffer <= {addr_buffer[8:0], sda};
            end else if (state == DATA_RECEIVE) begin
                data_buffer <= {data_buffer[6:0], sda};
            end
        end
    end
    
    // 输出数据有效标志控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
            data_rx <= 8'b0;
        end else begin
            if (state == ACK_SEND && next_state == DATA_RECEIVE) begin
                data_valid <= 1'b1;
                data_rx <= data_buffer;
            end else begin
                data_valid <= 1'b0;
            end
        end
    end
    
    // SDA输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_out <= 1'b1;
            sda_oe <= 1'b1;
        end else begin
            if (state == ACK_SEND && bit_count == 4'd8) begin
                sda_out <= 1'b0; // 发送ACK
                sda_oe <= 1'b0;
            end else begin
                sda_out <= 1'b1;
                sda_oe <= 1'b1; // 高阻态，允许外部设备驱动SDA
            end
        end
    end
    
endmodule