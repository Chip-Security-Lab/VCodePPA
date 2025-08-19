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
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {WIDTH{1'b0}};
            timeout <= 1'b0;
        end else if (enable) begin
            if (counter >= period - 1) begin
                counter <= {WIDTH{1'b0}};
                timeout <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                timeout <= 1'b0;
            end
        end
    end
endmodule