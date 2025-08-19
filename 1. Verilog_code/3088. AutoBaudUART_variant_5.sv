//SystemVerilog
module AutoBaudUART (
    input clk, rst_n,
    input rx_line,
    output reg [15:0] baud_rate,
    output reg baud_locked
);
    // 使用localparam代替typedef enum
    localparam SEARCH = 2'b00, MEASURE = 2'b01, LOCKED = 2'b10;
    reg [1:0] current_state, next_state;
    
    reg [15:0] edge_counter, next_edge_counter;
    reg last_rx;
    reg edge_detected, start_bit_detected;
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= SEARCH;
        end else begin
            current_state <= next_state;
        end
    end
    
    // 输入采样逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_rx <= 1'b1;
        end else begin
            last_rx <= rx_line;
        end
    end
    
    // 边沿检测逻辑
    always @(*) begin
        start_bit_detected = (last_rx == 1'b1 && rx_line == 1'b0);
        edge_detected = (last_rx == 1'b0 && rx_line == 1'b1);
    end
    
    // 计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_counter <= 16'h0;
        end else if (current_state == MEASURE) begin
            edge_counter <= edge_counter + 1'b1;
        end else if (current_state == SEARCH) begin
            edge_counter <= 16'h0;
        end
    end
    
    // 状态转移逻辑
    always @(*) begin
        next_state = current_state;
        
        case(current_state)
            SEARCH: begin
                if (start_bit_detected) begin
                    next_state = MEASURE;
                end
            end
            MEASURE: begin
                if (edge_detected) begin
                    next_state = LOCKED;
                end
            end
            LOCKED: begin
                next_state = LOCKED;
            end
            default: next_state = SEARCH;
        endcase
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_rate <= 16'h0;
            baud_locked <= 1'b0;
        end else if (current_state == MEASURE && edge_detected) begin
            baud_rate <= edge_counter;
        end else if (current_state == LOCKED) begin
            baud_locked <= 1'b1;
        end
    end
endmodule