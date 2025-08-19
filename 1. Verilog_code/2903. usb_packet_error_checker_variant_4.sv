//SystemVerilog
//IEEE 1364-2005 Verilog
module usb_packet_error_checker(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire packet_end,
    input wire [15:0] received_crc,
    output reg crc_error,
    output reg timeout_error,
    output reg bitstuff_error
);
    // 主状态寄存器
    reg [15:0] calculated_crc;
    reg [15:0] next_calculated_crc;
    reg [7:0] timeout_counter;
    reg [7:0] next_timeout_counter;
    reg receiving;
    reg next_receiving;
    reg next_crc_error;
    reg next_timeout_error;
    
    // 扇出缓冲寄存器
    reg [15:0] calculated_crc_buf1, calculated_crc_buf2;
    reg [15:0] next_calculated_crc_buf1, next_calculated_crc_buf2;
    reg [7:0] timeout_counter_buf1, timeout_counter_buf2;
    reg [7:0] next_timeout_counter_buf;
    reg receiving_buf1, receiving_buf2;
    reg next_receiving_buf;
    
    // 组合逻辑: 计算下一周期的值
    always @(*) begin
        // 默认保持当前值
        next_calculated_crc = calculated_crc;
        next_timeout_counter = timeout_counter;
        next_receiving = receiving;
        next_crc_error = crc_error;
        next_timeout_error = timeout_error;
        
        if (data_valid) begin
            next_calculated_crc = calculated_crc ^ {8'h00, data_in};
            next_timeout_counter = 8'd0;
            next_receiving = 1'b1;
        end else if (receiving_buf1) begin  // 使用缓冲后的receiving信号
            next_timeout_counter = timeout_counter + 1'b1;
            if (timeout_counter_buf1 == 8'd200) begin  // 使用缓冲后的timeout_counter
                next_timeout_error = 1'b1;
                next_receiving = 1'b0;
            end
        end
        
        if (packet_end) begin
            next_crc_error = (calculated_crc_buf1 != received_crc);  // 使用缓冲后的calculated_crc
            next_calculated_crc = 16'hFFFF;
            next_receiving = 1'b0;
        end
        
        // 为高扇出信号准备缓冲值
        next_calculated_crc_buf1 = calculated_crc;
        next_calculated_crc_buf2 = calculated_crc;
        next_timeout_counter_buf = timeout_counter;
        next_receiving_buf = receiving;
    end
    
    // 时序逻辑: 在时钟边沿更新寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calculated_crc <= 16'hFFFF;
            timeout_counter <= 8'd0;
            crc_error <= 1'b0;
            timeout_error <= 1'b0;
            bitstuff_error <= 1'b0;
            receiving <= 1'b0;
            
            // 复位缓冲寄存器
            calculated_crc_buf1 <= 16'hFFFF;
            calculated_crc_buf2 <= 16'hFFFF;
            timeout_counter_buf1 <= 8'd0;
            timeout_counter_buf2 <= 8'd0;
            receiving_buf1 <= 1'b0;
            receiving_buf2 <= 1'b0;
        end else begin
            calculated_crc <= next_calculated_crc;
            timeout_counter <= next_timeout_counter;
            crc_error <= next_crc_error;
            timeout_error <= next_timeout_error;
            receiving <= next_receiving;
            
            // 更新缓冲寄存器
            calculated_crc_buf1 <= next_calculated_crc_buf1;
            calculated_crc_buf2 <= next_calculated_crc_buf2;
            timeout_counter_buf1 <= next_timeout_counter_buf;
            timeout_counter_buf2 <= timeout_counter_buf1;
            receiving_buf1 <= next_receiving_buf;
            receiving_buf2 <= receiving_buf1;
        end
    end
endmodule