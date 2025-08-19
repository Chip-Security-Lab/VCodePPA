//SystemVerilog
module usb_endpoint_buffer_mgr #(
    parameter NUM_ENDPOINTS = 4,
    parameter BUFFER_SIZE = 64
)(
    input wire clk,
    input wire rst_b,
    input wire [3:0] endpoint_select,
    input wire write_enable,
    input wire read_enable,
    input wire [7:0] write_data,
    output reg [7:0] read_data,
    output reg buffer_full,
    output reg buffer_empty,
    output reg [7:0] buffer_count
);
    // RAM for each endpoint buffer
    reg [7:0] buffers [0:NUM_ENDPOINTS-1][0:BUFFER_SIZE-1];
    
    // Pointers and counters for each endpoint
    reg [7:0] write_ptr [0:NUM_ENDPOINTS-1];
    reg [7:0] read_ptr [0:NUM_ENDPOINTS-1];
    reg [7:0] count [0:NUM_ENDPOINTS-1];
    
    // 直接处理输入，减少输入到第一级寄存器的延迟
    wire [7:0] curr_write_ptr = write_ptr[endpoint_select];
    wire [7:0] curr_read_ptr = read_ptr[endpoint_select];
    wire [7:0] curr_count = count[endpoint_select];
    wire buffer_full_comb = (curr_count == BUFFER_SIZE);
    wire buffer_empty_comb = (curr_count == 8'd0);
    wire actual_write_enable = write_enable && !buffer_full_comb;
    wire actual_read_enable = read_enable && !buffer_empty_comb;
    
    // 计算下一个指针和计数值
    wire [7:0] next_write_ptr = (curr_write_ptr + 8'd1) % BUFFER_SIZE;
    wire [7:0] next_read_ptr = (curr_read_ptr + 8'd1) % BUFFER_SIZE;
    wire [7:0] next_count = actual_write_enable && actual_read_enable ? curr_count :
                           actual_write_enable ? curr_count + 8'd1 :
                           actual_read_enable ? curr_count - 8'd1 : curr_count;
    
    // Pipeline stage 1: 缓存组合逻辑结果
    reg [3:0] endpoint_select_stage1;
    reg write_enable_stage1, read_enable_stage1;
    reg [7:0] write_data_stage1;
    reg buffer_full_stage1, buffer_empty_stage1;
    reg [7:0] buffer_count_stage1;
    reg [7:0] next_write_ptr_stage1, next_read_ptr_stage1, next_count_stage1;
    reg actual_write_enable_stage1, actual_read_enable_stage1;
    
    // Pipeline stage 2: 操作准备
    reg [3:0] endpoint_select_stage2;
    reg actual_write_enable_stage2, actual_read_enable_stage2;
    reg [7:0] write_data_stage2;
    reg [7:0] curr_write_ptr_stage2, curr_read_ptr_stage2;
    reg [7:0] next_write_ptr_stage2, next_read_ptr_stage2, next_count_stage2;
    reg buffer_full_stage2, buffer_empty_stage2;
    reg [7:0] buffer_count_stage2;
    
    // Read data from memory combinationally
    wire [7:0] read_data_comb = buffers[endpoint_select_stage2][curr_read_ptr_stage2];
    
    integer i;
    
    // Stage 1: 直接缓存组合逻辑结果，而不是原始输入
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            endpoint_select_stage1 <= 4'd0;
            write_enable_stage1 <= 1'b0;
            read_enable_stage1 <= 1'b0;
            write_data_stage1 <= 8'd0;
            buffer_full_stage1 <= 1'b0;
            buffer_empty_stage1 <= 1'b1;
            buffer_count_stage1 <= 8'd0;
            next_write_ptr_stage1 <= 8'd0;
            next_read_ptr_stage1 <= 8'd0;
            next_count_stage1 <= 8'd0;
            actual_write_enable_stage1 <= 1'b0;
            actual_read_enable_stage1 <= 1'b0;
        end else begin
            endpoint_select_stage1 <= endpoint_select;
            write_enable_stage1 <= write_enable;
            read_enable_stage1 <= read_enable;
            write_data_stage1 <= write_data;
            buffer_full_stage1 <= buffer_full_comb;
            buffer_empty_stage1 <= buffer_empty_comb;
            buffer_count_stage1 <= curr_count;
            next_write_ptr_stage1 <= next_write_ptr;
            next_read_ptr_stage1 <= next_read_ptr;
            next_count_stage1 <= next_count;
            actual_write_enable_stage1 <= actual_write_enable;
            actual_read_enable_stage1 <= actual_read_enable;
        end
    end
    
    // Stage 2: 准备内存操作
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            endpoint_select_stage2 <= 4'd0;
            actual_write_enable_stage2 <= 1'b0;
            actual_read_enable_stage2 <= 1'b0;
            write_data_stage2 <= 8'd0;
            curr_write_ptr_stage2 <= 8'd0;
            curr_read_ptr_stage2 <= 8'd0;
            next_write_ptr_stage2 <= 8'd0;
            next_read_ptr_stage2 <= 8'd0;
            next_count_stage2 <= 8'd0;
            buffer_full_stage2 <= 1'b0;
            buffer_empty_stage2 <= 1'b1;
            buffer_count_stage2 <= 8'd0;
        end else begin
            endpoint_select_stage2 <= endpoint_select_stage1;
            actual_write_enable_stage2 <= actual_write_enable_stage1;
            actual_read_enable_stage2 <= actual_read_enable_stage1;
            write_data_stage2 <= write_data_stage1;
            curr_write_ptr_stage2 <= write_ptr[endpoint_select_stage1];
            curr_read_ptr_stage2 <= read_ptr[endpoint_select_stage1];
            next_write_ptr_stage2 <= next_write_ptr_stage1;
            next_read_ptr_stage2 <= next_read_ptr_stage1;
            next_count_stage2 <= next_count_stage1;
            buffer_full_stage2 <= buffer_full_stage1;
            buffer_empty_stage2 <= buffer_empty_stage1;
            buffer_count_stage2 <= buffer_count_stage1;
        end
    end
    
    // Final stage: 执行内存操作和更新状态
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                write_ptr[i] <= 8'd0;
                read_ptr[i] <= 8'd0;
                count[i] <= 8'd0;
            end
            read_data <= 8'd0;
            buffer_full <= 1'b0;
            buffer_empty <= 1'b1;
            buffer_count <= 8'd0;
        end else begin
            // 更新输出信号
            buffer_full <= buffer_full_stage2;
            buffer_empty <= buffer_empty_stage2;
            buffer_count <= buffer_count_stage2;
            
            // 执行内存操作
            if (actual_write_enable_stage2) begin
                buffers[endpoint_select_stage2][curr_write_ptr_stage2] <= write_data_stage2;
                write_ptr[endpoint_select_stage2] <= next_write_ptr_stage2;
            end
            
            if (actual_read_enable_stage2) begin
                read_data <= read_data_comb;  // 使用组合逻辑读取的数据
                read_ptr[endpoint_select_stage2] <= next_read_ptr_stage2;
            end
            
            // 更新计数寄存器
            count[endpoint_select_stage2] <= next_count_stage2;
        end
    end
endmodule