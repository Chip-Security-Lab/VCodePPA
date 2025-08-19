//SystemVerilog
module usb_error_counter(
    input wire clk,
    input wire rst_n,
    input wire crc_error,
    input wire pid_error,
    input wire timeout_error,
    input wire bitstuff_error,
    input wire babble_detected,
    input wire clear_counters,
    output reg [7:0] crc_error_count,
    output reg [7:0] pid_error_count,
    output reg [7:0] timeout_error_count,
    output reg [7:0] bitstuff_error_count,
    output reg [7:0] babble_error_count,
    output reg [1:0] error_status
);
    // 参数定义
    localparam NO_ERRORS = 2'b00;
    localparam WARNING = 2'b01;
    localparam CRITICAL = 2'b10;
    
    // 内部信号声明
    reg any_error_detected;
    wire [4:0] error_flags;
    
    // 组合逻辑信号
    wire [7:0] next_crc_error_count;
    wire [7:0] next_pid_error_count;
    wire [7:0] next_timeout_error_count;
    wire [7:0] next_bitstuff_error_count;
    wire [7:0] next_babble_error_count;
    wire [1:0] next_error_status;
    wire next_any_error_detected;
    
    //============ 组合逻辑部分 ============
    
    // 错误标志组合
    assign error_flags = {crc_error, pid_error, timeout_error, bitstuff_error, babble_detected};
    
    // 检测是否有任何错误
    assign next_any_error_detected = |error_flags;
    
    // CRC错误计数器的组合逻辑
    assign next_crc_error_count = clear_counters ? 8'd0 :
                                (crc_error && crc_error_count < 8'hFF) ? 
                                crc_error_count + 8'd1 : crc_error_count;
    
    // PID错误计数器的组合逻辑
    assign next_pid_error_count = clear_counters ? 8'd0 :
                                (pid_error && pid_error_count < 8'hFF) ? 
                                pid_error_count + 8'd1 : pid_error_count;
    
    // 超时错误计数器的组合逻辑
    assign next_timeout_error_count = clear_counters ? 8'd0 :
                                    (timeout_error && timeout_error_count < 8'hFF) ? 
                                    timeout_error_count + 8'd1 : timeout_error_count;
    
    // 比特填充错误计数器的组合逻辑
    assign next_bitstuff_error_count = clear_counters ? 8'd0 :
                                     (bitstuff_error && bitstuff_error_count < 8'hFF) ? 
                                     bitstuff_error_count + 8'd1 : bitstuff_error_count;
    
    // Babble错误计数器的组合逻辑
    assign next_babble_error_count = clear_counters ? 8'd0 :
                                   (babble_detected && babble_error_count < 8'hFF) ? 
                                   babble_error_count + 8'd1 : babble_error_count;
    
    // 错误状态的组合逻辑
    assign next_error_status = clear_counters ? NO_ERRORS :
                             (babble_error_count > 8'd3 || timeout_error_count > 8'd10) ? CRITICAL :
                             any_error_detected ? WARNING : NO_ERRORS;
    
    //============ 时序逻辑部分 ============
    
    // 寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_error_count <= 8'd0;
            pid_error_count <= 8'd0;
            timeout_error_count <= 8'd0;
            bitstuff_error_count <= 8'd0;
            babble_error_count <= 8'd0;
            error_status <= NO_ERRORS;
            any_error_detected <= 1'b0;
        end else begin
            crc_error_count <= next_crc_error_count;
            pid_error_count <= next_pid_error_count;
            timeout_error_count <= next_timeout_error_count;
            bitstuff_error_count <= next_bitstuff_error_count;
            babble_error_count <= next_babble_error_count;
            error_status <= next_error_status;
            any_error_detected <= next_any_error_detected;
        end
    end

endmodule