module edge_detect_recovery (
    input wire clk,
    input wire rst_n,
    input wire signal_in,
    output reg rising_edge,
    output reg falling_edge,
    output reg [7:0] edge_count
);
    reg signal_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_prev <= 1'b0;
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
            edge_count <= 8'h00;
        end else begin
            signal_prev <= signal_in;
            
            rising_edge <= ~signal_prev & signal_in;
            falling_edge <= signal_prev & ~signal_in;
            
            if ((~signal_prev & signal_in) || (signal_prev & ~signal_in))
                edge_count <= edge_count + 1'b1;
        end
    end
endmodule