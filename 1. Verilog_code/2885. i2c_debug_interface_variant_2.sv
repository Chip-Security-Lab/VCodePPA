//SystemVerilog
module i2c_debug_interface #(
    parameter TRACE_DEPTH = 16
)(
    input wire clk,
    input wire rst_async_n,
    inout wire sda,
    inout wire scl,
    // 调试接口
    output reg [3:0] debug_state,
    output reg [TRACE_DEPTH*8-1:0] trace_data_flat, // 扁平化输出
    input wire trace_enable,
    // Valid-Ready 握手接口
    output wire debug_valid,
    input wire debug_ready,
    output wire trace_valid,
    input wire trace_ready
);
    // 传输过程追踪
    reg [7:0] trace_buffer [0:TRACE_DEPTH-1];
    reg [4:0] trace_ptr;
    
    // 添加信号
    reg data_valid;
    reg [1:0] state;
    reg [2:0] bit_counter;
    
    // 状态检测输出信号
    wire status_valid;
    wire [2:0] next_bit_counter;
    wire [1:0] next_state;
    
    // 握手信号逻辑
    reg debug_data_ready;
    reg trace_data_ready;
    wire monitor_valid;
    wire monitor_ready;
    wire buffer_valid;
    wire buffer_ready;
    
    assign debug_valid = debug_data_ready;
    assign trace_valid = trace_data_ready;
    assign monitor_ready = 1'b1; // 总是准备接收总线监控的数据
    assign buffer_ready = trace_ready & trace_enable;
    
    // 总线状态检测模块实例化
    i2c_bus_monitor i2c_monitor (
        .clk(clk),
        .rst_n(rst_async_n),
        .scl(scl),
        .bit_counter_in(bit_counter),
        .state_in(state),
        .data_valid(status_valid),
        .bit_counter_out(next_bit_counter),
        .state_out(next_state),
        .valid(monitor_valid),
        .ready(monitor_ready)
    );
    
    // 数据缓冲模块实例化
    trace_buffer_manager #(
        .BUFFER_DEPTH(TRACE_DEPTH),
        .DATA_WIDTH(8)
    ) trace_manager (
        .clk(clk),
        .rst_n(rst_async_n),
        .enable(trace_enable),
        .data_valid(data_valid),
        .data_in({scl, sda, state, bit_counter[2:0]}),
        .buffer_out(trace_buffer),
        .ptr_out(trace_ptr),
        .valid(buffer_valid),
        .ready(buffer_ready)
    );
    
    // 状态更新
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            data_valid <= 1'b0;
            state <= 2'b00;
            bit_counter <= 3'b000;
            debug_data_ready <= 1'b0;
            trace_data_ready <= 1'b0;
        end else begin
            data_valid <= status_valid & monitor_valid & monitor_ready;
            
            if (monitor_valid & monitor_ready) begin
                bit_counter <= next_bit_counter;
                state <= next_state;
            end
            
            // 调试状态有效性控制
            debug_data_ready <= 1'b1;
            if (debug_valid & debug_ready) begin
                debug_data_ready <= 1'b0;
            end
            
            // 轨迹数据有效性控制
            if (buffer_valid) begin
                trace_data_ready <= 1'b1;
            end else if (trace_valid & trace_ready) begin
                trace_data_ready <= 1'b0;
            end
        end
    end

    // 调试状态输出和扁平化
    integer i;
    always @(*) begin
        debug_state = {scl, sda, state};
        
        // 扁平化trace_buffer到trace_data_flat
        for (i = 0; i < TRACE_DEPTH; i = i + 1) begin
            trace_data_flat[i*8 +: 8] = trace_buffer[i];
        end
    end
endmodule

// I2C总线状态监控模块
module i2c_bus_monitor (
    input wire clk,
    input wire rst_n,
    input wire scl,
    input wire [2:0] bit_counter_in,
    input wire [1:0] state_in,
    output reg data_valid,
    output reg [2:0] bit_counter_out,
    output reg [1:0] state_out,
    // Valid-Ready 握手接口
    output wire valid,
    input wire ready
);
    reg valid_r;
    
    assign valid = valid_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_r <= 1'b0;
        end else begin
            if (ready) begin
                valid_r <= scl;  // 在SCL高电平时有效
            end
        end
    end
    
    always @(*) begin
        data_valid = 1'b0;
        bit_counter_out = bit_counter_in;
        state_out = state_in;
        
        if (scl == 1'b1 && valid && ready) begin
            bit_counter_out = bit_counter_in + 1;
            if (bit_counter_in == 3'b111) begin
                data_valid = 1'b1;
                state_out = state_in + 1;
            end
        end
    end
endmodule

// 参数化的轨迹缓冲管理模块
module trace_buffer_manager #(
    parameter BUFFER_DEPTH = 16,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire data_valid,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] buffer_out [0:BUFFER_DEPTH-1],
    output reg [$clog2(BUFFER_DEPTH):0] ptr_out,
    // Valid-Ready 握手接口
    output wire valid,
    input wire ready
);
    integer i;
    reg valid_r;
    reg [DATA_WIDTH-1:0] data_buffer;
    reg data_pending;
    
    assign valid = valid_r;
    
    // 初始化
    initial begin
        for (i = 0; i < BUFFER_DEPTH; i = i + 1) begin
            buffer_out[i] = {DATA_WIDTH{1'b0}};
        end
        ptr_out = 0;
        valid_r = 1'b0;
        data_pending = 1'b0;
        data_buffer = {DATA_WIDTH{1'b0}};
    end
    
    // 握手状态管理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_r <= 1'b0;
            data_pending <= 1'b0;
            data_buffer <= {DATA_WIDTH{1'b0}};
        end else begin
            // 收到新数据时设置valid
            if (data_valid && enable && !data_pending) begin
                valid_r <= 1'b1;
                data_buffer <= data_in;
                data_pending <= 1'b1;
            end
            
            // 握手完成后清除valid
            if (valid && ready) begin
                valid_r <= 1'b0;
                data_pending <= 1'b0;
            end
        end
    end
    
    // 轨迹缓冲区更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ptr_out <= 0;
            for (i = 0; i < BUFFER_DEPTH; i = i + 1) begin
                buffer_out[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (enable && valid && ready) begin
            buffer_out[ptr_out] <= data_buffer;
            ptr_out <= (ptr_out == BUFFER_DEPTH-1) ? 0 : ptr_out + 1;
        end
    end
endmodule