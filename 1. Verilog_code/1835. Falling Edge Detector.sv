module falling_edge_detector (
    input  wire clock,
    input  wire async_reset,
    input  wire signal_input,
    output reg  edge_out,
    output reg  auto_reset_out
);
    reg signal_delayed;
    reg [3:0] auto_reset_counter;
    
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            signal_delayed <= 1'b0;
            edge_out <= 1'b0;
            auto_reset_counter <= 4'b0;
            auto_reset_out <= 1'b0;
        end else begin
            signal_delayed <= signal_input;
            edge_out <= ~signal_input & signal_delayed;
            
            if (edge_out) begin
                auto_reset_counter <= 4'b1111;
                auto_reset_out <= 1'b1;
            end else if (|auto_reset_counter) begin
                auto_reset_counter <= auto_reset_counter - 1'b1;
            end else begin
                auto_reset_out <= 1'b0;
            end
        end
    end
endmodule