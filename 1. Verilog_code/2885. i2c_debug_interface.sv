module i2c_debug_interface #(
    parameter TRACE_DEPTH = 16
)(
    input clk,
    input rst_async_n,
    inout sda,
    inout scl,
    // 调试接口
    output reg [3:0] debug_state,
    output reg [TRACE_DEPTH*8-1:0] trace_data_flat, // 扁平化输出
    input trace_enable
);
    // 传输过程追踪
    reg [7:0] trace_buffer [0:TRACE_DEPTH-1];
    reg [4:0] trace_ptr;
    
    // 添加缺失的信号
    reg data_valid;
    reg [1:0] state;
    reg [2:0] bit_counter;
    
    // 初始化
    integer i;
    initial begin
        for (i = 0; i < TRACE_DEPTH; i = i + 1) begin
            trace_buffer[i] = 8'h0;
        end
        trace_ptr = 5'h0;
        debug_state = 4'h0;
        data_valid = 1'b0;
        state = 2'b00;
        bit_counter = 3'b000;
    end
    
    // I2C总线状态检测
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            data_valid <= 1'b0;
            state <= 2'b00;
            bit_counter <= 3'b000;
        end else begin
            // SCL上升沿检测
            if (scl == 1'b1) begin
                bit_counter <= bit_counter + 1;
                if (bit_counter == 3'b111) begin
                    data_valid <= 1'b1;
                    state <= state + 1;
                end else begin
                    data_valid <= 1'b0;
                end
            end else begin
                data_valid <= 1'b0;
            end
        end
    end

    // 轨迹缓冲区更新
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            trace_ptr <= 0;
            for (i = 0; i < TRACE_DEPTH; i = i + 1) begin
                trace_buffer[i] <= 8'h0;
            end
        end else if (trace_enable && data_valid) begin
            trace_buffer[trace_ptr] <= {scl, sda, state, bit_counter[2:0]};
            trace_ptr <= (trace_ptr == TRACE_DEPTH-1) ? 0 : trace_ptr + 1;
        end
    end

    // 调试状态输出
    always @(*) begin
        debug_state = {scl, sda, state};
        
        // 扁平化trace_buffer到trace_data_flat
        for (i = 0; i < TRACE_DEPTH; i = i + 1) begin
            trace_data_flat[i*8 +: 8] = trace_buffer[i];
        end
    end
endmodule