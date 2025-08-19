//SystemVerilog
module basic_timer #(
    parameter CLK_FREQ = 50000000,  // Clock frequency in Hz
    parameter WIDTH = 32            // Timer width in bits
)(
    input wire clk,                 // System clock
    input wire rst_n,               // Active-low reset
    input wire enable,              // Timer enable
    input wire [WIDTH-1:0] period,  // Timer period
    output reg timeout              // Timeout flag
);
    reg [WIDTH-1:0] counter;
    reg enable_r;
    reg [WIDTH-1:0] period_r;
    wire counter_at_period;
    
    // Register inputs to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_r <= 1'b0;
            period_r <= {WIDTH{1'b0}};
        end else begin
            enable_r <= enable;
            period_r <= period;
        end
    end
    
    // Optimize comparison with dedicated comparator logic
    // Now using registered inputs
    assign counter_at_period = (counter == period_r - 1'b1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {WIDTH{1'b0}};
            timeout <= 1'b0;
        end else begin
            case ({enable_r, counter_at_period})
                2'b11: begin
                    counter <= {WIDTH{1'b0}};
                    timeout <= 1'b1;
                end
                2'b10: begin
                    counter <= counter + 1'b1;
                    timeout <= 1'b0;
                end
                default: begin
                    counter <= counter;
                    timeout <= timeout;
                end
            endcase
        end
    end
endmodule