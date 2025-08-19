module multi_mode_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [1:0] mode,
    input wire [WIDTH-1:0] period,
    output reg out
);
    reg [WIDTH-1:0] counter;
    
    // Mode: 0-OneShot, 1-Periodic, 2-PWM, 3-Toggle
    always @(posedge clk) begin
        if (rst) begin
            counter <= {WIDTH{1'b0}};
            out <= 1'b0;
        end else begin
            case (mode)
                2'd0: begin // One-Shot Mode
                    if (counter < period) begin
                        counter <= counter + 1'b1;
                        out <= 1'b1;
                    end else begin
                        out <= 1'b0;
                    end
                end
                2'd1: begin // Periodic Mode
                    if (counter >= period - 1) begin
                        counter <= {WIDTH{1'b0}};
                        out <= 1'b1;
                    end else begin
                        counter <= counter + 1'b1;
                        out <= 1'b0;
                    end
                end
                2'd2: begin // PWM Mode (50% duty)
                    if (counter >= period - 1) begin
                        counter <= {WIDTH{1'b0}};
                    end else begin
                        counter <= counter + 1'b1;
                    end
                    out <= (counter < (period >> 1)) ? 1'b1 : 1'b0;
                end
                2'd3: begin // Toggle Mode
                    if (counter >= period - 1) begin
                        counter <= {WIDTH{1'b0}};
                        out <= ~out;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule