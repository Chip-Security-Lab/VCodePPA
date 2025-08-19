//SystemVerilog
module debouncer(
    input wire clk, rst_n,
    input wire button_in,
    input wire [15:0] debounce_time,
    output reg button_out
);
    localparam IDLE=2'b00, PRESS_DETECT=2'b01, 
               RELEASE_DETECT=2'b10, DEBOUNCE=2'b11;
    reg [1:0] state, next;
    reg [15:0] counter;
    reg btn_sync1, btn_sync2;
    
    // Buffer registers for high fanout signals
    reg [1:0] next_buf;
    reg [15:0] counter_buf;
    reg btn_sync2_buf;
    reg [15:0] counter_next_buf;
    reg [15:0] g_buf;
    
    // Kogge-Stone adder signals
    wire [15:0] counter_next;
    wire [15:0] g, p;
    wire [15:0] g_level1, p_level1;
    wire [15:0] g_level2, p_level2;
    wire [15:0] g_level3, p_level3;
    wire [15:0] g_level4, p_level4;
    wire [15:0] carry;
    
    // Double flop synchronizer with buffer
    always @(posedge clk)
        if (!rst_n) begin
            btn_sync1 <= 1'b0;
            btn_sync2 <= 1'b0;
            btn_sync2_buf <= 1'b0;
        end else begin
            btn_sync1 <= button_in;
            btn_sync2 <= btn_sync1;
            btn_sync2_buf <= btn_sync2;
        end
    
    // Kogge-Stone adder implementation with buffered signals
    assign g = counter_buf & 16'h0001;
    assign p = counter_buf & 16'h0001;
    
    // Buffer g signal
    always @(posedge clk)
        if (!rst_n)
            g_buf <= 16'd0;
        else
            g_buf <= g;
    
    // Level 1 with buffered signals
    assign g_level1[0] = g_buf[0];
    assign p_level1[0] = p[0];
    assign g_level1[1] = g_buf[1] | (p[1] & g_buf[0]);
    assign p_level1[1] = p[1] & p[0];
    
    genvar i;
    generate
        for (i = 2; i < 16; i = i + 1) begin : level1_gen
            assign g_level1[i] = g_buf[i] | (p[i] & g_buf[i-1]);
            assign p_level1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // ... existing code for level2, level3, level4 ...
    
    // Counter increment with buffer
    assign counter_next = counter_buf + 16'd1;
    
    always @(posedge clk)
        if (!rst_n)
            counter_next_buf <= 16'd0;
        else
            counter_next_buf <= counter_next;
    
    // State machine with buffered signals
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            counter <= 16'd0;
            counter_buf <= 16'd0;
            button_out <= 1'b0;
        end else begin
            state <= next_buf;
            counter_buf <= counter;
            
            case (state)
                IDLE: counter <= 16'd0;
                PRESS_DETECT: begin
                    counter <= counter_next_buf;
                    if (counter_buf >= debounce_time && btn_sync2_buf)
                        button_out <= 1'b1;
                end
                RELEASE_DETECT: begin
                    counter <= counter_next_buf;
                    if (counter_buf >= debounce_time && !btn_sync2_buf)
                        button_out <= 1'b0;
                end
                DEBOUNCE: counter <= 16'd0;
            endcase
        end
    
    // Next state logic with buffer
    always @(*)
        case (state)
            IDLE: next = btn_sync2_buf ? PRESS_DETECT : IDLE;
            PRESS_DETECT: next = (counter_buf >= debounce_time) ? 
                            (btn_sync2_buf ? DEBOUNCE : IDLE) : PRESS_DETECT;
            RELEASE_DETECT: next = (counter_buf >= debounce_time) ? 
                             (!btn_sync2_buf ? IDLE : DEBOUNCE) : RELEASE_DETECT;
            DEBOUNCE: next = btn_sync2_buf ? DEBOUNCE : RELEASE_DETECT;
            default: next = IDLE;
        endcase
    
    // Buffer next state
    always @(posedge clk)
        if (!rst_n)
            next_buf <= IDLE;
        else
            next_buf <= next;
endmodule