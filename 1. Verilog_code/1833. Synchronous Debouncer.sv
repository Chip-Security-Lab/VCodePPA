module switch_debouncer #(parameter DEBOUNCE_COUNT = 1000) (
    input  wire clk,
    input  wire reset,
    input  wire switch_in,
    output reg  clean_out
);
    localparam CNT_WIDTH = $clog2(DEBOUNCE_COUNT);
    reg [CNT_WIDTH-1:0] counter;
    reg switch_ff1, switch_ff2;
    
    // Double-flop synchronizer
    always @(posedge clk) begin
        switch_ff1 <= switch_in;
        switch_ff2 <= switch_ff1;
    end
    
    // Counter-based debouncer
    always @(posedge clk) begin
        if (reset) begin
            counter <= {CNT_WIDTH{1'b0}};
            clean_out <= 1'b0;
        end else if (switch_ff2 != clean_out) begin
            if (counter == DEBOUNCE_COUNT-1) begin
                clean_out <= switch_ff2;
                counter <= {CNT_WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
        end else begin
            counter <= {CNT_WIDTH{1'b0}};
        end
    end
endmodule