//SystemVerilog
module rs232_codec #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200
) (
    input wire clk, rstn,
    input wire rx, tx_valid,
    input wire [7:0] tx_data,
    output reg tx, rx_valid,
    output reg [7:0] rx_data
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    reg [1:0] tx_state, rx_state;
    reg [$clog2(CLKS_PER_BIT)-1:0] tx_clk_count, rx_clk_count;
    reg [2:0] tx_bit_idx, rx_bit_idx;
    reg [7:0] tx_shift_reg, rx_shift_reg;
    reg rx_d1, rx_d2; // Double-flop synchronizer
    
    // 使用条件反相减法器算法 - 减法器实现
    function [$clog2(CLKS_PER_BIT)-1:0] cond_inverse_sub;
        input [$clog2(CLKS_PER_BIT)-1:0] minuend;
        input [$clog2(CLKS_PER_BIT)-1:0] subtrahend;
        
        reg [$clog2(CLKS_PER_BIT)-1:0] inverted_subtrahend;
        reg [$clog2(CLKS_PER_BIT):0] sum;
        reg carry;
        
        begin
            // 反相减数
            inverted_subtrahend = ~subtrahend;
            
            // 执行加法 (minuend + ~subtrahend + 1)
            {carry, sum} = minuend + inverted_subtrahend + 1'b1;
            
            cond_inverse_sub = sum[$clog2(CLKS_PER_BIT)-1:0];
        end
    endfunction
    
    // 比较器函数，使用条件反相减法器实现
    function is_equal;
        input [$clog2(CLKS_PER_BIT)-1:0] a;
        input [$clog2(CLKS_PER_BIT)-1:0] b;
        
        begin
            is_equal = (cond_inverse_sub(a, b) == 0);
        end
    endfunction
    
    // 比较器函数，使用条件反相减法器实现
    function is_less;
        input [$clog2(CLKS_PER_BIT)-1:0] a;
        input [$clog2(CLKS_PER_BIT)-1:0] b;
        
        reg [$clog2(CLKS_PER_BIT)-1:0] diff;
        begin
            diff = cond_inverse_sub(a, b);
            is_less = diff[$clog2(CLKS_PER_BIT)-1]; // 检查最高位判断符号
        end
    endfunction
    
    // Synchronize RX input
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin 
            rx_d1 <= 1'b1; 
            rx_d2 <= 1'b1; 
        end else begin 
            rx_d1 <= rx; 
            rx_d2 <= rx_d1; 
        end
    end
    
    // TX state machine
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tx_state <= IDLE;
            tx <= 1'b1; // Idle high
            tx_clk_count <= 0;
            tx_bit_idx <= 0;
            tx_shift_reg <= 8'h00;
        end else begin
            case (tx_state)
                IDLE: begin
                    if (tx_valid) begin
                        tx_state <= START;
                        tx <= 1'b0; // Start bit
                        tx_clk_count <= 0;
                        tx_shift_reg <= tx_data;
                    end else begin
                        tx <= 1'b1; // Keep idle high
                    end
                end
                
                START: begin
                    if (is_less(tx_clk_count, CLKS_PER_BIT-1)) begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end else begin
                        tx_state <= DATA;
                        tx <= tx_shift_reg[0]; // First data bit
                        tx_clk_count <= 0;
                        tx_bit_idx <= 0;
                    end
                end
                
                DATA: begin
                    if (is_less(tx_bit_idx, 7)) begin
                        if (is_less(tx_clk_count, CLKS_PER_BIT-1)) begin
                            tx_clk_count <= tx_clk_count + 1'b1;
                        end else begin
                            tx_shift_reg <= {1'b0, tx_shift_reg[7:1]};
                            tx <= tx_shift_reg[1];
                            tx_clk_count <= 0;
                            tx_bit_idx <= tx_bit_idx + 1'b1;
                        end
                    end else begin
                        if (is_less(tx_clk_count, CLKS_PER_BIT-1)) begin
                            tx_clk_count <= tx_clk_count + 1'b1;
                        end else begin
                            tx_state <= STOP;
                            tx <= 1'b1; // Stop bit
                            tx_clk_count <= 0;
                        end
                    end
                end
                
                STOP: begin
                    if (is_less(tx_clk_count, CLKS_PER_BIT-1)) begin
                        tx_clk_count <= tx_clk_count + 1'b1;
                    end else begin
                        tx_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // RX state machine
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rx_state <= IDLE;
            rx_clk_count <= 0;
            rx_bit_idx <= 0;
            rx_valid <= 1'b0;
            rx_data <= 8'h00;
            rx_shift_reg <= 8'h00;
        end else begin
            case (rx_state)
                IDLE: begin
                    rx_valid <= 1'b0;
                    if (rx_d2 == 1'b0) begin
                        // Start bit detected
                        rx_state <= START;
                        rx_clk_count <= 0;
                    end
                end
                
                START: begin
                    if (is_less(rx_clk_count, CLKS_PER_BIT/2-1)) begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end else begin
                        if (rx_d2 == 1'b0) begin
                            // Confirm start bit
                            rx_state <= DATA;
                            rx_clk_count <= 0;
                            rx_bit_idx <= 0;
                        end else begin
                            // False start bit
                            rx_state <= IDLE;
                        end
                    end
                end
                
                DATA: begin
                    if (is_less(rx_clk_count, CLKS_PER_BIT-1)) begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end else begin
                        rx_shift_reg <= {rx_d2, rx_shift_reg[7:1]};
                        rx_clk_count <= 0;
                        
                        if (is_less(rx_bit_idx, 7)) begin
                            rx_bit_idx <= rx_bit_idx + 1'b1;
                        end else begin
                            rx_state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    if (is_less(rx_clk_count, CLKS_PER_BIT-1)) begin
                        rx_clk_count <= rx_clk_count + 1'b1;
                    end else begin
                        rx_state <= IDLE;
                        if (rx_d2 == 1'b1) begin
                            // Valid stop bit
                            rx_valid <= 1'b1;
                            rx_data <= rx_shift_reg;
                        end
                    end
                end
            endcase
        end
    end
endmodule