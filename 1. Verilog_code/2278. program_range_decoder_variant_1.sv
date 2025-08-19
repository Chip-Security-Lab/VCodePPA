//SystemVerilog
module program_range_decoder(
    input [7:0] addr,
    input [7:0] base_addr,
    input [7:0] limit,
    output reg in_range
);
    // Compute relative position for table lookup
    wire [8:0] rel_pos;
    wire [8:0] upper_bound;
    
    assign upper_bound = {1'b0, base_addr} + {1'b0, limit};
    assign rel_pos = {1'b0, addr} - {1'b0, base_addr};
    
    // Use lookup table approach for range checking
    reg [1:0] range_status;
    
    always @(*) begin
        // Status encoding:
        // 0: below base_addr
        // 1: within range
        // 2: above or equal to upper_bound
        
        if ({1'b0, addr} < {1'b0, base_addr})
            range_status = 2'd0;
        else if (rel_pos < {1'b0, limit})
            range_status = 2'd1;
        else
            range_status = 2'd2;
            
        // Lookup table for final decision
        case (range_status)
            2'd0: in_range = 1'b0;  // Below base
            2'd1: in_range = 1'b1;  // Within range
            2'd2: in_range = 1'b0;  // Above range
            default: in_range = 1'b0;
        endcase
    end
endmodule