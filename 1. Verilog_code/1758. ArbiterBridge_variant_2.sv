//SystemVerilog
module ArbiterBridge #(
    parameter MASTERS = 4
)(
    input clk, rst_n,
    input [MASTERS-1:0] req,
    output reg [MASTERS-1:0] grant
);
    reg [1:0] priority_ptr;
    
    // Registered input requests to reduce fanout
    reg [MASTERS-1:0] req_buffer;
    
    // One-hot priority encoder signals
    reg [MASTERS-1:0] req_shifted;
    reg [MASTERS-1:0] grant_next;
    wire has_request;
    
    // Calculate has_request (OR reduction)
    assign has_request = |req_buffer;
    
    always @(*) begin
        // Create rotated request vector based on priority pointer
        req_shifted = {req_buffer, req_buffer} >> priority_ptr;
        
        // Priority encoder implemented as efficient cascaded structure
        if (req_shifted[0])
            grant_next = 1'b1 << ((priority_ptr+0) % MASTERS);
        else if (req_shifted[1])
            grant_next = 1'b1 << ((priority_ptr+1) % MASTERS);
        else if (req_shifted[2])
            grant_next = 1'b1 << ((priority_ptr+2) % MASTERS);
        else if (req_shifted[3])
            grant_next = 1'b1 << ((priority_ptr+3) % MASTERS);
        else
            grant_next = {MASTERS{1'b0}};
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= {MASTERS{1'b0}};
            priority_ptr <= 2'b00;
            req_buffer <= {MASTERS{1'b0}};
        end else begin
            // Register request signals to reduce fanout
            req_buffer <= req;
            
            // Update grant based on priority encoding
            grant <= has_request ? grant_next : {MASTERS{1'b0}};
            
            // Update priority pointer when a grant is issued
            if (has_request) begin
                casez (grant_next)
                    4'b0001: priority_ptr <= 2'd1;
                    4'b0010: priority_ptr <= 2'd2;
                    4'b0100: priority_ptr <= 2'd3;
                    4'b1000: priority_ptr <= 2'd0;
                    default: priority_ptr <= priority_ptr;
                endcase
            end
        end
    end
endmodule