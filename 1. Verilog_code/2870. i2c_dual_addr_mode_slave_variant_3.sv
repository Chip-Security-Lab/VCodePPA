//SystemVerilog
module i2c_dual_addr_mode_slave(
    input wire clk, rst_n,
    input wire [6:0] addr_7bit,
    input wire [9:0] addr_10bit,
    input wire addr_mode, // 0=7bit, 1=10bit
    output reg [7:0] data_rx,
    output reg data_valid,
    inout wire sda, scl
);
    // 状态定义
    localparam IDLE        = 3'b000;
    localparam ADDR_DETECT = 3'b001;
    localparam DATA_RX     = 3'b010;
    localparam ADDR_10BIT  = 3'b100;
    
    reg [2:0] state;
    reg [9:0] addr_buffer;
    reg [7:0] data_buffer;
    reg [3:0] bit_count;
    reg sda_out, sda_oe;
    
    // SDA 总线控制
    assign sda = sda_oe ? 1'bz : sda_out;
    
    // 状态机控制块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    // 在下一个块中处理 IDLE 状态转换
                end
                
                ADDR_DETECT: begin
                    if (bit_count == 4'd8) begin
                        if (!addr_mode && addr_buffer[7:1] == addr_7bit)
                            state <= DATA_RX;
                        else if (addr_mode && addr_buffer[7:1] == 10'b1111000000)
                            state <= ADDR_10BIT; // 10-bit addr first byte
                        else
                            state <= IDLE;
                    end
                end
                
                DATA_RX: begin
                    // 在下一个块中处理 DATA_RX 状态转换
                end
                
                ADDR_10BIT: begin
                    // 在下一个块中处理 ADDR_10BIT 状态转换
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // 数据有效信号控制块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
        end else begin
            case (state)
                DATA_RX: begin
                    if (bit_count == 4'd8) 
                        data_valid <= 1'b1;
                    else
                        data_valid <= 1'b0;
                end
                
                default: data_valid <= 1'b0;
            endcase
        end
    end
    
    // 位计数器控制块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_count <= 4'd0;
        end else begin
            case (state)
                IDLE: begin
                    bit_count <= 4'd0;
                end
                
                ADDR_DETECT, DATA_RX, ADDR_10BIT: begin
                    if (scl) 
                        bit_count <= (bit_count == 4'd8) ? 4'd0 : bit_count + 4'd1;
                end
                
                default: bit_count <= 4'd0;
            endcase
        end
    end
    
    // 地址和数据缓冲控制块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_buffer <= 10'd0;
            data_buffer <= 8'd0;
        end else begin
            case (state)
                ADDR_DETECT: begin
                    if (scl && bit_count < 4'd8)
                        addr_buffer[7-bit_count] <= sda;
                end
                
                ADDR_10BIT: begin
                    if (scl && bit_count < 4'd8)
                        addr_buffer[9:8] <= {addr_buffer[0], sda};
                end
                
                DATA_RX: begin
                    if (scl && bit_count < 4'd8)
                        data_buffer[7-bit_count] <= sda;
                end
                
                default: begin
                    // 保持当前值
                end
            endcase
        end
    end
    
    // 数据输出控制块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_rx <= 8'd0;
        end else if (state == DATA_RX && bit_count == 4'd8) begin
            data_rx <= data_buffer;
        end
    end
    
    // SDA 输出控制块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_out <= 1'b1;
            sda_oe <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    sda_out <= 1'b1;
                    sda_oe <= 1'b1;
                end
                
                ADDR_DETECT: begin
                    if (bit_count == 4'd8) begin
                        sda_oe <= 1'b0;
                        if ((!addr_mode && addr_buffer[7:1] == addr_7bit) ||
                            (addr_mode && addr_buffer[7:1] == 10'b1111000000))
                            sda_out <= 1'b0;  // ACK
                        else
                            sda_out <= 1'b1;  // NACK
                    end else begin
                        sda_oe <= 1'b1;
                    end
                end
                
                DATA_RX, ADDR_10BIT: begin
                    if (bit_count == 4'd8) begin
                        sda_oe <= 1'b0;
                        sda_out <= 1'b0;  // ACK
                    end else begin
                        sda_oe <= 1'b1;
                    end
                end
                
                default: begin
                    sda_oe <= 1'b1;
                    sda_out <= 1'b1;
                end
            endcase
        end
    end
endmodule