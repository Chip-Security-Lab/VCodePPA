//SystemVerilog
module sync_decim_filter #(
    parameter WIDTH = 8,
    parameter RATIO = 4
)(
    input clock, reset,
    input [WIDTH-1:0] in_data,
    input in_valid,
    output reg [WIDTH-1:0] out_data,
    output reg out_valid
);
    reg [$clog2(RATIO)-1:0] counter;
    reg [WIDTH+$clog2(RATIO)-1:0] sum;  // Extended width to prevent overflow
    
    wire counter_full = (counter == RATIO-1);
    wire [WIDTH+$clog2(RATIO)-1:0] sum_next = sum + in_data;
    
    always @(posedge clock) begin
        if (reset) begin
            counter <= 0;
            sum <= 0;
            out_valid <= 0;
        end else if (in_valid) begin
            if (counter_full) begin
                out_data <= sum_next[WIDTH+$clog2(RATIO)-1:$clog2(RATIO)];  // Division by RATIO using right shift
                out_valid <= 1;
                counter <= 0;
                sum <= 0;
            end else begin
                sum <= sum_next;
                counter <= counter + 1;
                out_valid <= 0;
            end
        end else begin
            out_valid <= 0;
        end
    end
endmodule