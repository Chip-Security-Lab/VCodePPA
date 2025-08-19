//SystemVerilog
module capture_timer (
    input wire clk_i, rst_i, en_i, capture_i,
    output reg [31:0] value_o, capture_o,
    output reg capture_valid_o
);
    reg capture_d1;
    wire capture_event;
    reg [31:0] value_next;
    
    // Optimize edge detection with direct wire assignment
    assign capture_event = capture_d1 & ~capture_i;
    
    // Value counter logic - optimized with next value computation
    always @(*) begin
        value_next = en_i ? value_o + 32'h1 : value_o;
    end
    
    // Combined sequential logic to reduce register stages
    always @(posedge clk_i) begin
        if (rst_i) begin
            value_o <= 32'h0;
            capture_d1 <= 1'b0;
            capture_valid_o <= 1'b0;
            capture_o <= 32'h0;
        end
        else begin
            value_o <= value_next;
            capture_d1 <= capture_i;
            capture_valid_o <= capture_event;
            
            // Update capture register directly when event occurs
            if (capture_event) begin
                capture_o <= value_o;
            end
        end
    end
endmodule