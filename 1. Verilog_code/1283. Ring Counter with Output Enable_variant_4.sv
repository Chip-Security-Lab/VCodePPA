//SystemVerilog
module output_enabled_ring_counter(
    input wire clock,
    input wire reset,
    input wire oe, // Output enable
    output wire [3:0] data
);
    reg [3:0] count_pre;
    reg [3:0] count_pre_buf1;  // Buffer register for count_pre
    reg [3:0] count_pre_buf2;  // Second buffer register for balanced distribution
    reg [3:0] count;
    reg oe_reg;
    
    // Retimed logic with fanout buffering for count_pre
    always @(posedge clock) begin
        if (reset) begin
            count_pre <= 4'b0001;
            count_pre_buf1 <= 4'b0001;
            count_pre_buf2 <= 4'b0001;
            count <= 4'b0001;
            oe_reg <= 1'b0;
        end
        else begin
            // Original count_pre update
            count_pre <= {count_pre[2:0], count_pre[3]};
            
            // Buffer registers to reduce fanout load
            count_pre_buf1 <= count_pre;
            count_pre_buf2 <= count_pre;
            
            // Use buffered version for count update
            count <= count_pre_buf1;
            
            // Output enable logic remains the same
            oe_reg <= oe;
        end
    end
    
    // Use the second buffer for the shift operation to balance loads
    wire [3:0] next_count_pre;
    assign next_count_pre = {count_pre_buf2[2:0], count_pre_buf2[3]};
    
    // Tri-state output with registered oe and count values
    assign data = oe_reg ? count : 4'bz;
    
endmodule