//SystemVerilog
module cascaded_timer (
    input wire clk_i,
    input wire rst_n_i,
    input wire enable_i,
    input wire [7:0] timer1_max_i,
    input wire [7:0] timer2_max_i,
    output wire timer1_tick_o,
    output wire timer2_tick_o
);
    // Timer 1 signals
    reg [7:0] timer1_count;
    reg timer1_tick_r;
    
    // Timer 2 signals
    reg [7:0] timer2_count;
    reg timer2_tick_r;
    
    // Buffered signals for high fanout
    reg timer1_tick_buf1, timer1_tick_buf2;
    reg enable_buf1, enable_buf2;
    reg [7:0] timer1_max_buf1, timer1_max_buf2;
    reg [7:0] timer2_max_buf1, timer2_max_buf2;
    
    // Output assignments
    assign timer1_tick_o = timer1_tick_r;
    assign timer2_tick_o = timer2_tick_r;
    
    // Buffer registers for high fanout signals
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            timer1_tick_buf1 <= 1'b0;
            timer1_tick_buf2 <= 1'b0;
            enable_buf1 <= 1'b0;
            enable_buf2 <= 1'b0;
            timer1_max_buf1 <= 8'd0;
            timer1_max_buf2 <= 8'd0;
            timer2_max_buf1 <= 8'd0;
            timer2_max_buf2 <= 8'd0;
        end else begin
            timer1_tick_buf1 <= timer1_tick_r;
            timer1_tick_buf2 <= timer1_tick_r;
            enable_buf1 <= enable_i;
            enable_buf2 <= enable_i;
            timer1_max_buf1 <= timer1_max_i;
            timer1_max_buf2 <= timer1_max_i;
            timer2_max_buf1 <= timer2_max_i;
            timer2_max_buf2 <= timer2_max_i;
        end
    end
    
    // Timer 1 logic with buffered signals
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            timer1_count <= 8'd0;
            timer1_tick_r <= 1'b0;
        end else if (enable_buf1) begin
            if (timer1_count >= timer1_max_buf1 - 1) begin
                timer1_count <= 8'd0;
                timer1_tick_r <= 1'b1;
            end else begin
                timer1_count <= timer1_count + 1'b1;
                timer1_tick_r <= 1'b0;
            end
        end
    end
    
    // Timer 2 logic with buffered signals
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            timer2_count <= 8'd0;
            timer2_tick_r <= 1'b0;
        end else if (timer1_tick_buf2) begin
            if (timer2_count >= timer2_max_buf2 - 1) begin
                timer2_count <= 8'd0;
                timer2_tick_r <= 1'b1;
            end else begin
                timer2_count <= timer2_count + 1'b1;
                timer2_tick_r <= 1'b0;
            end
        end else begin
            timer2_tick_r <= 1'b0;
        end
    end
endmodule