module windowed_signal_recovery #(
    parameter DATA_WIDTH = 10,
    parameter WINDOW_SIZE = 5
)(
    input wire clk,
    input wire window_enable,
    input wire [DATA_WIDTH-1:0] signal_in,
    output reg [DATA_WIDTH-1:0] signal_out,
    output reg valid
);
    reg [DATA_WIDTH-1:0] window [0:WINDOW_SIZE-1];
    reg [DATA_WIDTH+3:0] sum;
    integer i;
    
    always @(posedge clk) begin
        if (window_enable) begin
            // Shift window values
            for (i = WINDOW_SIZE-1; i > 0; i = i-1)
                window[i] <= window[i-1];
            window[0] <= signal_in;
            
            // Sum window values
            sum = 0;
            for (i = 0; i < WINDOW_SIZE; i = i+1)
                sum = sum + window[i];
                
            // Calculate windowed average
            signal_out <= sum / WINDOW_SIZE;
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
endmodule