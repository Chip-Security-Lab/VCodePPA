//SystemVerilog
module dual_edge_divider (
    input wire clkin,
    input wire rst,
    // Valid-Ready handshake interface
    input wire ready,   // Receiver is ready to accept clock
    output reg valid,   // Valid divided clock is available
    output reg clkout
);
    reg [1:0] pos_count, neg_count;
    reg pos_toggle, neg_toggle;
    
    // Predictive logic for positive edge counter
    wire pos_will_overflow;
    wire next_pos_toggle;
    wire [1:0] next_pos_count;
    
    assign pos_will_overflow = (pos_count == 2'b11);
    assign next_pos_count = pos_will_overflow ? 2'b00 : (pos_count + 1'b1);
    assign next_pos_toggle = pos_will_overflow ? ~pos_toggle : pos_toggle;
    
    // Predictive logic for negative edge counter
    wire neg_will_overflow;
    wire next_neg_toggle;
    wire [1:0] next_neg_count;
    
    assign neg_will_overflow = (neg_count == 2'b11);
    assign next_neg_count = neg_will_overflow ? 2'b00 : (neg_count + 1'b1);
    assign next_neg_toggle = neg_will_overflow ? ~neg_toggle : neg_toggle;
    
    // Positive edge triggered logic
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            pos_count <= 2'b00;
            pos_toggle <= 1'b0;
            valid <= 1'b0;
        end else begin
            pos_count <= next_pos_count;
            pos_toggle <= next_pos_toggle;
            
            if (pos_will_overflow) begin
                valid <= 1'b1;  // Signal that new clock edge is available
            end else if (valid && ready) begin
                valid <= 1'b0;  // Clear valid when handshake completes
            end
        end
    end
    
    // Negative edge triggered logic
    always @(negedge clkin or posedge rst) begin
        if (rst) begin
            neg_count <= 2'b00;
            neg_toggle <= 1'b0;
        end else begin
            neg_count <= next_neg_count;
            neg_toggle <= next_neg_toggle;
        end
    end
    
    // Registered output to reduce glitches and improve timing
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            clkout <= 1'b0;
        end else begin
            clkout <= next_pos_toggle ^ next_neg_toggle;
        end
    end
endmodule