module capture_timer (
    input wire clk_i, rst_i, en_i, capture_i,
    output reg [31:0] value_o, capture_o,
    output reg capture_valid_o
);
    reg capture_d1, capture_d2;
    wire capture_event;
    always @(posedge clk_i) begin
        if (rst_i) value_o <= 32'h0;
        else if (en_i) value_o <= value_o + 32'h1;
    end
    always @(posedge clk_i) begin
        if (rst_i) begin capture_d1 <= 1'b0; capture_d2 <= 1'b0; end
        else begin capture_d1 <= capture_i; capture_d2 <= capture_d1; end
    end
    assign capture_event = capture_d1 & ~capture_d2; // Rising edge
    always @(posedge clk_i) begin
        if (rst_i) begin capture_o <= 32'h0; capture_valid_o <= 1'b0; end
        else begin
            capture_valid_o <= capture_event;
            if (capture_event) capture_o <= value_o;
        end
    end
endmodule