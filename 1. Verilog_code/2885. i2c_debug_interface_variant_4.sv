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
    reg [4:0] trace_ptr_next;
    
    // 中间寄存器（重定时）
    reg scl_reg, sda_reg;
    reg scl_reg2, sda_reg2; // 附加的重定时寄存器
    reg [1:0] state_reg;
    reg [2:0] bit_counter_reg;
    
    // 信号
    reg data_valid;
    reg data_valid_pipe; // 流水线寄存器
    reg [1:0] state;
    reg [2:0] bit_counter;
    reg [2:0] bit_counter_incr; // 流水线寄存器
    wire [3:0] debug_state_comb;
    reg [3:0] debug_state_pipe; // 流水线寄存器
    wire [TRACE_DEPTH*8-1:0] trace_data_flat_comb;
    reg [TRACE_DEPTH*8-1:0] trace_data_flat_pipe; // 流水线寄存器
    
    // 初始化
    integer i;
    initial begin
        for (i = 0; i < TRACE_DEPTH; i = i + 1) begin
            trace_buffer[i] = 8'h0;
        end
        trace_ptr = 5'h0;
        trace_ptr_next = 5'h0;
        debug_state = 4'h0;
        debug_state_pipe = 4'h0;
        data_valid = 1'b0;
        data_valid_pipe = 1'b0;
        state = 2'b00;
        bit_counter = 3'b000;
        bit_counter_incr = 3'b000;
        scl_reg = 1'b0;
        sda_reg = 1'b0;
        scl_reg2 = 1'b0;
        sda_reg2 = 1'b0;
        state_reg = 2'b00;
        bit_counter_reg = 3'b000;
        trace_data_flat_pipe = {(TRACE_DEPTH*8){1'b0}};
    end
    
    // 输入寄存（两级流水线重定时以减少关键路径延迟）
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            scl_reg <= 1'b0;
            sda_reg <= 1'b0;
            scl_reg2 <= 1'b0;
            sda_reg2 <= 1'b0;
            state_reg <= 2'b00;
            bit_counter_reg <= 3'b000;
        end else begin
            // 第一级管道寄存
            scl_reg <= scl;
            sda_reg <= sda;
            
            // 第二级管道寄存
            scl_reg2 <= scl_reg;
            sda_reg2 <= sda_reg;
            state_reg <= state;
            bit_counter_reg <= bit_counter;
        end
    end
    
    // 计算bit_counter的增量值（拆分长路径）
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            bit_counter_incr <= 3'b000;
        end else begin
            bit_counter_incr <= bit_counter + 1;
        end
    end
    
    // I2C总线状态检测（使用流水线的计算结果）
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            data_valid <= 1'b0;
            state <= 2'b00;
            bit_counter <= 3'b000;
        end else begin
            // SCL上升沿检测，使用寄存器后移的信号
            if (scl_reg == 1'b1) begin
                bit_counter <= bit_counter_incr; // 使用预先计算的值
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

    // 计算下一个trace_ptr值（拆分长路径）
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            trace_ptr_next <= 5'h0;
        end else begin
            trace_ptr_next <= (trace_ptr == TRACE_DEPTH-1) ? 0 : trace_ptr + 1;
        end
    end

    // 流水线寄存data_valid信号
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            data_valid_pipe <= 1'b0;
        end else begin
            data_valid_pipe <= data_valid;
        end
    end

    // 轨迹缓冲区更新（使用流水线的data_valid信号）
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            trace_ptr <= 0;
            for (i = 0; i < TRACE_DEPTH; i = i + 1) begin
                trace_buffer[i] <= 8'h0;
            end
        end else if (trace_enable && data_valid_pipe) begin
            trace_buffer[trace_ptr] <= {scl_reg2, sda_reg2, state_reg, bit_counter_reg[2:0]};
            trace_ptr <= trace_ptr_next; // 使用预先计算的值
        end
    end

    // 调试状态组合逻辑
    assign debug_state_comb = {scl_reg2, sda_reg2, state_reg};
    
    // 扁平化trace_buffer到trace_data_flat_comb
    genvar g;
    generate
        for (g = 0; g < TRACE_DEPTH; g = g + 1) begin : gen_trace_flat
            assign trace_data_flat_comb[g*8 +: 8] = trace_buffer[g];
        end
    endgenerate
    
    // 流水线寄存组合逻辑输出
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            debug_state_pipe <= 4'h0;
            trace_data_flat_pipe <= {(TRACE_DEPTH*8){1'b0}};
        end else begin
            debug_state_pipe <= debug_state_comb;
            trace_data_flat_pipe <= trace_data_flat_comb;
        end
    end
    
    // 最终输出寄存
    always @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            debug_state <= 4'h0;
            trace_data_flat <= {(TRACE_DEPTH*8){1'b0}};
        end else begin
            debug_state <= debug_state_pipe;
            trace_data_flat <= trace_data_flat_pipe;
        end
    end
    
endmodule