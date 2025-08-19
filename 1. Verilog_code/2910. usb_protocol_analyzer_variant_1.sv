//SystemVerilog
module usb_protocol_analyzer(
    input wire clk,
    input wire reset,
    input wire dp,
    input wire dm,
    input wire start_capture,
    output reg [7:0] capture_data,
    output reg data_valid,
    output reg [2:0] packet_type,
    output reg [7:0] capture_count
);
    // One-cold encoding for states
    // Only one bit will be 0, others will be 1
    localparam IDLE = 5'b11110;
    localparam SYNC = 5'b11101;
    localparam PID = 5'b11011;
    localparam DATA = 5'b10111;
    localparam EOP = 5'b01111;
    
    reg [4:0] state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    
    // 将输入信号寄存后再进行处理，减小输入到第一级寄存器的延迟
    reg dp_reg, dm_reg, start_capture_reg;
    
    // Line state definitions - 移到寄存器之后
    wire j_state, k_state, se0;
    
    // 将输入信号寄存化
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            dp_reg <= 1'b0;
            dm_reg <= 1'b0;
            start_capture_reg <= 1'b0;
        end else begin
            dp_reg <= dp;
            dm_reg <= dm;
            start_capture_reg <= start_capture;
        end
    end
    
    // 使用寄存后的信号定义线路状态
    assign j_state = dp_reg & ~dm_reg;
    assign k_state = ~dp_reg & dm_reg;
    assign se0 = ~dp_reg & ~dm_reg;
    
    // 下一状态逻辑与组合逻辑预计算
    reg [4:0] next_state;
    reg [2:0] next_bit_count;
    reg [7:0] next_shift_reg;
    reg next_data_valid;
    reg [2:0] next_packet_type;
    reg [7:0] next_capture_count;
    reg [7:0] next_capture_data;

    // 组合逻辑部分 - 计算下一状态
    always @(*) begin
        next_state = state;
        next_bit_count = bit_count;
        next_shift_reg = shift_reg;
        next_data_valid = 1'b0;  // 默认不输出有效数据
        next_packet_type = packet_type;
        next_capture_count = capture_count;
        next_capture_data = capture_data;
        
        case (1'b0)
            state[0]: begin // IDLE
                if (start_capture_reg && k_state)
                    next_state = SYNC;
                next_capture_count = 8'd0;
            end
            state[1]: begin // SYNC
                next_bit_count = bit_count + 3'd1;
                next_shift_reg = {k_state, shift_reg[7:1]};
                if (bit_count == 3'd7) begin
                    next_state = PID;
                    next_bit_count = 3'd0;
                    if (shift_reg == 8'b01010100)  // SYNC pattern (reversed)
                        next_packet_type = 3'd1;   // Valid SYNC found
                end
            end
            state[2]: begin // PID
                next_bit_count = bit_count + 3'd1;
                next_shift_reg = {j_state, shift_reg[7:1]};
                if (bit_count == 3'd7) begin
                    next_capture_data = shift_reg;
                    next_data_valid = 1'b1;
                    next_capture_count = capture_count + 8'd1;
                    next_state = DATA;
                    next_bit_count = 3'd0;
                end
            end
            state[3]: begin // DATA
                if (se0) begin
                    next_state = EOP;
                end else begin
                    next_bit_count = bit_count + 3'd1;
                    next_shift_reg = {j_state, shift_reg[7:1]};
                    if (bit_count == 3'd7) begin
                        next_capture_data = shift_reg;
                        next_data_valid = 1'b1;
                        next_capture_count = capture_count + 8'd1;
                        next_bit_count = 3'd0;
                    end
                end
            end
            state[4]: begin // EOP
                next_state = IDLE;
            end
        endcase
    end
    
    // 寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 3'd0;
            shift_reg <= 8'd0;
            data_valid <= 1'b0;
            packet_type <= 3'd0;
            capture_count <= 8'd0;
            capture_data <= 8'd0;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            shift_reg <= next_shift_reg;
            data_valid <= next_data_valid;
            packet_type <= next_packet_type;
            capture_count <= next_capture_count;
            capture_data <= next_capture_data;
        end
    end
endmodule