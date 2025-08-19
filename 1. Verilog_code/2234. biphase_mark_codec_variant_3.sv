//SystemVerilog
//IEEE 1364-2005
module biphase_mark_codec (
    input wire clk, rst,
    input wire encode, decode,
    input wire data_in,
    input wire biphase_in,
    output reg biphase_out,
    output reg data_out,
    output reg data_valid
);
    reg last_bit;
    reg [1:0] bit_timer;
    reg data_in_reg; // Register for input data
    
    // 添加扇出缓冲寄存器
    reg [1:0] bit_timer_buf1, bit_timer_buf2;
    reg [1:0] current_timer_reg;
    reg [1:0] next_timer_reg;
    reg [1:0] p_stage0_buf1, p_stage0_buf2;
    reg [1:0] g_stage0_buf1, g_stage0_buf2;

    // Register the input data first
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            data_in_reg <= 1'b0;
        end else if (encode) begin
            data_in_reg <= data_in;
        end
    end
    
    // 缓冲高扇出信号 bit_timer
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            bit_timer_buf1 <= 2'b00;
            bit_timer_buf2 <= 2'b00;
        end else begin
            bit_timer_buf1 <= bit_timer;
            bit_timer_buf2 <= bit_timer;
        end
    end
    
    // Signals for Kogge-Stone adder implementation
    wire [1:0] current_timer;  // Current timer value
    wire [1:0] next_timer;     // Next timer value after addition
    wire [1:0] p_stage0;       // Propagate signals stage 0
    wire [1:0] g_stage0;       // Generate signals stage 0
    wire [1:0] p_stage1;       // Propagate signals stage 1
    wire [1:0] g_stage1;       // Generate signals stage 1
    wire [1:0] carry;          // Carry signals
    
    // Map current timer to internal signal with buffer
    assign current_timer = bit_timer_buf1;
    
    // 缓冲 current_timer 信号
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_timer_reg <= 2'b00;
        end else begin
            current_timer_reg <= current_timer;
        end
    end
    
    // Kogge-Stone adder stage 0 - Generate propagate and generate signals
    assign p_stage0 = current_timer_reg | 2'b01; // Propagate = a OR b
    assign g_stage0 = current_timer_reg & 2'b01; // Generate = a AND b
    
    // 缓冲 p_stage0 和 g_stage0 信号
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            p_stage0_buf1 <= 2'b00;
            p_stage0_buf2 <= 2'b00;
            g_stage0_buf1 <= 2'b00;
            g_stage0_buf2 <= 2'b00;
        end else begin
            p_stage0_buf1 <= p_stage0;
            p_stage0_buf2 <= p_stage0;
            g_stage0_buf1 <= g_stage0;
            g_stage0_buf2 <= g_stage0;
        end
    end
    
    // Kogge-Stone adder stage 1 - Compute carries
    assign p_stage1[0] = p_stage0_buf1[0];
    assign g_stage1[0] = g_stage0_buf1[0];
    
    assign p_stage1[1] = p_stage0_buf1[1] & p_stage0_buf2[0];
    assign g_stage1[1] = g_stage0_buf1[1] | (p_stage0_buf2[1] & g_stage0_buf2[0]);
    
    // Compute carries
    assign carry[0] = g_stage1[0];
    assign carry[1] = g_stage1[1];
    
    // Compute sum
    assign next_timer[0] = current_timer_reg[0] ^ 1'b1; // a XOR b
    assign next_timer[1] = current_timer_reg[1] ^ carry[0];
    
    // 缓冲 next_timer 信号
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            next_timer_reg <= 2'b00;
        end else begin
            next_timer_reg <= next_timer;
        end
    end
    
    // Bi-phase mark encoding with retimed input and Kogge-Stone adder
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            biphase_out <= 1'b0;
            bit_timer <= 2'b00;
            last_bit <= 1'b0;
        end else if (encode) begin
            bit_timer <= next_timer_reg; // Use buffered Kogge-Stone adder result
            if (bit_timer_buf2 == 2'b00) // Start of bit time
                biphase_out <= ~biphase_out; // Always transition
            else if (bit_timer_buf2 == 2'b10 && data_in_reg) // Mid-bit & data is '1'
                biphase_out <= ~biphase_out; // Additional transition
        end
    end
    
    // Bi-phase mark decoding logic would be implemented here
endmodule