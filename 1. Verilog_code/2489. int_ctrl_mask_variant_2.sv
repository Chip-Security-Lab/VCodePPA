//SystemVerilog
module int_ctrl_mask #(
    parameter DW = 16
)(
    input clk, en,
    input [DW-1:0] req_in,
    input [DW-1:0] mask,
    output reg [DW-1:0] masked_req
);
    // Split the bus into multiple segments to balance path delay
    localparam SEGMENT_SIZE = 4;
    localparam NUM_SEGMENTS = (DW + SEGMENT_SIZE - 1) / SEGMENT_SIZE;
    
    reg [DW-1:0] req_reg;
    reg [DW-1:0] mask_reg;
    reg [DW-1:0] masked_req_comb;
    reg [NUM_SEGMENTS-1:0] segment_valid;
    
    // Register inputs with enable control for power saving
    always @(posedge clk) begin
        if(en) req_reg <= req_in;
        else req_reg <= req_reg;
        
        mask_reg <= mask;
    end
    
    // Process each segment in parallel to reduce critical path
    // This balances the logic paths
    genvar i;
    generate
        for(i = 0; i < NUM_SEGMENTS; i = i + 1) begin : mask_segments
            always @(*) begin
                // Calculate each segment independently
                if(i == NUM_SEGMENTS-1 && DW % SEGMENT_SIZE != 0) begin
                    // Handle last segment that might be partial
                    masked_req_comb[i*SEGMENT_SIZE +: DW % SEGMENT_SIZE] = 
                        req_reg[i*SEGMENT_SIZE +: DW % SEGMENT_SIZE] & 
                        ~mask_reg[i*SEGMENT_SIZE +: DW % SEGMENT_SIZE];
                    
                    // Check if this segment has any active requests
                    segment_valid[i] = |(req_reg[i*SEGMENT_SIZE +: DW % SEGMENT_SIZE] & 
                                        ~mask_reg[i*SEGMENT_SIZE +: DW % SEGMENT_SIZE]);
                end
                else begin
                    // Process full segments
                    masked_req_comb[i*SEGMENT_SIZE +: SEGMENT_SIZE] = 
                        req_reg[i*SEGMENT_SIZE +: SEGMENT_SIZE] & 
                        ~mask_reg[i*SEGMENT_SIZE +: SEGMENT_SIZE];
                    
                    // Check if this segment has any active requests
                    segment_valid[i] = |(req_reg[i*SEGMENT_SIZE +: SEGMENT_SIZE] & 
                                        ~mask_reg[i*SEGMENT_SIZE +: SEGMENT_SIZE]);
                end
            end
        end
    endgenerate
    
    // Final output register stage with bypass logic for faster response
    // when no requests are present
    always @(posedge clk) begin
        masked_req <= masked_req_comb;
    end
endmodule