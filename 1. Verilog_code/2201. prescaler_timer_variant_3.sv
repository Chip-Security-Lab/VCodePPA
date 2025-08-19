//SystemVerilog
module prescaler_timer (
    input wire clk,
    input wire rst_n,
    input wire [3:0] prescale_sel,
    input wire [15:0] period,
    output reg tick_out
);
    reg [15:0] prescale_count;
    reg [15:0] timer_count;
    reg tick_enable;
    
    // Pre-calculation signals for retiming
    reg timer_at_max;
    reg timer_will_tick;
    
    // Prescaler logic with flattened if-else structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_count <= 16'h0000;
            tick_enable <= 1'b0;
        end else if (prescale_sel == 4'd0) begin
            prescale_count <= 16'h0000;
            tick_enable <= 1'b1;
        end else if (prescale_sel == 4'd1 && prescale_count >= 16'd1) begin
            prescale_count <= 16'h0000;
            tick_enable <= 1'b1;
        end else if (prescale_sel == 4'd2 && prescale_count >= 16'd3) begin
            prescale_count <= 16'h0000;
            tick_enable <= 1'b1;
        end else if (prescale_sel > 4'd2 && prescale_count >= (16'd1 << prescale_sel) - 1) begin
            prescale_count <= 16'h0000;
            tick_enable <= 1'b1;
        end else begin
            prescale_count <= prescale_count + 1'b1;
            tick_enable <= 1'b0;
        end
    end
    
    // Pre-calculation logic for next timer state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_at_max <= 1'b0;
        end else begin
            timer_at_max <= (timer_count == period - 1);
        end
    end
    
    // Timer logic with flattened if-else structure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_count <= 16'h0000;
            timer_will_tick <= 1'b0;
            tick_out <= 1'b0;
        end else if (tick_enable && timer_at_max) begin
            timer_count <= 16'h0000;
            timer_will_tick <= 1'b1;
            tick_out <= timer_will_tick;
        end else if (tick_enable) begin
            timer_count <= timer_count + 1'b1;
            timer_will_tick <= 1'b0;
            tick_out <= timer_will_tick;
        end else begin
            timer_count <= timer_count;
            timer_will_tick <= 1'b0;
            tick_out <= timer_will_tick;
        end
    end
endmodule