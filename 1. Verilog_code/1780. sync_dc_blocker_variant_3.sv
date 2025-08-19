//SystemVerilog
module sync_dc_blocker #(
    parameter WIDTH = 16
)(
    input clk, reset,
    input [WIDTH-1:0] signal_in,
    output reg [WIDTH-1:0] signal_out
);

    // Register declarations
    reg [WIDTH-1:0] prev_in, prev_out;
    reg [WIDTH-1:0] temp_buf1, temp_buf2;
    
    // Combinational logic
    wire [WIDTH-1:0] temp;
    assign temp = signal_in - prev_in + ((prev_out * 7) >> 3);
    
    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            prev_in <= 0;
            prev_out <= 0;
            signal_out <= 0;
            temp_buf1 <= 0;
            temp_buf2 <= 0;
        end else begin
            prev_in <= signal_in;
            temp_buf1 <= temp;
            temp_buf2 <= temp;
            prev_out <= temp_buf1;
            signal_out <= temp_buf2;
        end
    end
endmodule