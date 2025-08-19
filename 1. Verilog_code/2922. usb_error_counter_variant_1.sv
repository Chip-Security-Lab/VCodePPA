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
    localparam NO_ERRORS = 2'b00;
    localparam WARNING = 2'b01;
    localparam CRITICAL = 2'b10;
    
    // 组合所有错误信号为单个wire，减少门延迟和逻辑资源
    wire any_error;
    assign any_error = crc_error | pid_error | timeout_error | bitstuff_error | babble_detected;
    
    // 临时寄存器用于并行更新计数器
    reg [7:0] crc_count_next;
    reg [7:0] pid_count_next;
    reg [7:0] timeout_count_next;
    reg [7:0] bitstuff_count_next;
    reg [7:0] babble_count_next;
    reg [1:0] status_next;
    
    always @(*) begin
        // 默认值为当前值
        crc_count_next = crc_error_count;
        pid_count_next = pid_error_count;
        timeout_count_next = timeout_error_count;
        bitstuff_count_next = bitstuff_error_count;
        babble_count_next = babble_error_count;
        
        // 并行计算所有下一个计数值，减少关键路径
        if (crc_error && (crc_error_count != 8'hFF))
            crc_count_next = crc_error_count + 8'd1;
            
        if (pid_error && (pid_error_count != 8'hFF))
            pid_count_next = pid_error_count + 8'd1;
            
        if (timeout_error && (timeout_error_count != 8'hFF))
            timeout_count_next = timeout_error_count + 8'd1;
            
        if (bitstuff_error && (bitstuff_error_count != 8'hFF))
            bitstuff_count_next = bitstuff_error_count + 8'd1;
            
        if (babble_detected && (babble_error_count != 8'hFF))
            babble_count_next = babble_error_count + 8'd1;
        
        // 优化状态逻辑，使用简化的比较
        if (babble_count_next > 8'd3 || timeout_count_next > 8'd10)
            status_next = CRITICAL;
        else if (any_error)
            status_next = WARNING;
        else
            status_next = error_status;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_error_count <= 8'd0;
            pid_error_count <= 8'd0;
            timeout_error_count <= 8'd0;
            bitstuff_error_count <= 8'd0;
            babble_error_count <= 8'd0;
            error_status <= NO_ERRORS;
        end else if (clear_counters) begin
            crc_error_count <= 8'd0;
            pid_error_count <= 8'd0;
            timeout_error_count <= 8'd0;
            bitstuff_error_count <= 8'd0;
            babble_error_count <= 8'd0;
            error_status <= NO_ERRORS;
        end else begin
            // 使用预先计算的值更新计数器
            crc_error_count <= crc_count_next;
            pid_error_count <= pid_count_next;
            timeout_error_count <= timeout_count_next;
            bitstuff_error_count <= bitstuff_count_next;
            babble_error_count <= babble_count_next;
            error_status <= status_next;
        end
    end
endmodule