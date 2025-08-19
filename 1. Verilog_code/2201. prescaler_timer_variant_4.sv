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
    
    // Combined prescaler and timer logic in a single always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_count <= 16'h0000;
            tick_enable <= 1'b0;
            timer_count <= 16'h0000;
            tick_out <= 1'b0;
        end else begin
            // Default value for tick_out
            tick_out <= 1'b0;
            
            // Prescaler logic
            case (prescale_sel)
                4'd0: begin
                    tick_enable <= 1'b1;
                end
                4'd1: begin
                    if (prescale_count >= 16'd1) begin
                        prescale_count <= 16'h0000;
                        tick_enable <= 1'b1;
                    end else begin
                        prescale_count <= prescale_count + 1'b1;
                        tick_enable <= 1'b0;
                    end
                end
                4'd2: begin
                    if (prescale_count >= 16'd3) begin
                        prescale_count <= 16'h0000;
                        tick_enable <= 1'b1;
                    end else begin
                        prescale_count <= prescale_count + 1'b1;
                        tick_enable <= 1'b0;
                    end
                end
                default: begin
                    if (prescale_count >= (16'd1 << prescale_sel) - 1) begin
                        prescale_count <= 16'h0000;
                        tick_enable <= 1'b1;
                    end else begin
                        prescale_count <= prescale_count + 1'b1;
                        tick_enable <= 1'b0;
                    end
                end
            endcase
            
            // Timer logic - only active when tick_enable is true
            if (tick_enable) begin
                if (timer_count >= period - 1) begin
                    timer_count <= 16'h0000;
                    tick_out <= 1'b1;
                end else begin
                    timer_count <= timer_count + 1'b1;
                end
            end
        end
    end
endmodule