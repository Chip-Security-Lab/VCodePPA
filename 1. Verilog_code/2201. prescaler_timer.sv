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
    
    // Prescaler logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_count <= 16'h0000;
            tick_enable <= 1'b0;
        end else begin
            case (prescale_sel)
                4'd0: tick_enable <= 1'b1;
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
        end
    end
    
    // Timer logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_count <= 16'h0000;
            tick_out <= 1'b0;
        end else if (tick_enable) begin
            if (timer_count >= period - 1) begin
                timer_count <= 16'h0000;
                tick_out <= 1'b1;
            end else begin
                timer_count <= timer_count + 1'b1;
                tick_out <= 1'b0;
            end
        end
    end
endmodule