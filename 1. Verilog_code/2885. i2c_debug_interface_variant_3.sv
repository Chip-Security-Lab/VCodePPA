//SystemVerilog
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
    
    // 前向寄存器重定时：将直接连接到输入的信号寄存
    reg scl_r, sda_r;
    reg trace_enable_r;
    
    // 重定时后的信号
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
        scl_r = 1'b0;
        sda_r = 1'b0;
        trace_enable_r = 1'b0;
    end
    
    // 输入信号寄存 - 前向寄存器重定时
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            scl_r <= 1'b0;
            sda_r <= 1'b0;
            trace_enable_r <= 1'b0;
        end else begin
            scl_r <= scl;
            sda_r <= sda;
            trace_enable_r <= trace_enable;
        end
    end
    
    // I2C位计数和状态控制
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            bit_counter <= 3'b000;
        end else if (scl_r == 1'b1) begin
            bit_counter <= bit_counter + 1;
        end
    end
    
    // 数据有效性监测
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            data_valid <= 1'b0;
            state <= 2'b00;
        end else begin
            if (scl_r == 1'b1 && bit_counter == 3'b111) begin
                data_valid <= 1'b1;
                state <= state + 1;
            end else begin
                data_valid <= 1'b0;
            end
        end
    end

    // 轨迹指针控制
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            trace_ptr <= 0;
        end else if (trace_enable_r && data_valid) begin
            trace_ptr <= (trace_ptr == TRACE_DEPTH-1) ? 0 : trace_ptr + 1;
        end
    end
    
    // 轨迹缓冲区数据更新
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            for (i = 0; i < TRACE_DEPTH; i = i + 1) begin
                trace_buffer[i] <= 8'h0;
            end
        end else if (trace_enable_r && data_valid) begin
            trace_buffer[trace_ptr] <= {scl_r, sda_r, state, bit_counter[2:0]};
        end
    end

    // 调试状态输出更新
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            debug_state <= 4'h0;
        end else begin
            debug_state <= {scl_r, sda_r, state};
        end
    end
    
    // 扁平化轨迹数据输出
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            trace_data_flat <= {(TRACE_DEPTH*8){1'b0}};
        end else begin
            for (i = 0; i < TRACE_DEPTH; i = i + 1) begin
                trace_data_flat[i*8 +: 8] <= trace_buffer[i];
            end
        end
    end
endmodule