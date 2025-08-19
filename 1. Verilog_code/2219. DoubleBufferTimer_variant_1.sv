//SystemVerilog
module DoubleBufferTimer #(
    parameter DW = 8  // Data width parameter
) (
    input                clk,          // System clock
    input                rst_n,        // Active low reset
    input      [DW-1:0] next_period,   // Next timer period value
    output reg [DW-1:0] current        // Current countdown value
);

    // Period buffer registers - moved before combinational logic
    reg [DW-1:0] period_buffer;
    reg [DW-1:0] next_current;
    
    // Reload detection logic
    wire period_reload;
    assign period_reload = (current == 0);
    
    // Current counter update logic - retimed
    always @(posedge clk) begin
        if (!rst_n) begin
            current <= {DW{1'b0}};
        end else begin
            current <= next_current;
        end
    end
    
    // Moved combinational logic before register
    always @(*) begin
        if (period_reload) begin
            next_current = period_buffer;
        end else begin
            next_current = current - 1'b1;
        end
    end
    
    // Period buffer update logic
    always @(posedge clk) begin
        if (!rst_n) begin
            period_buffer <= {DW{1'b0}};
        end else if (period_reload) begin
            period_buffer <= next_period;
        end
    end

endmodule