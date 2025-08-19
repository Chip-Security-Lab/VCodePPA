//SystemVerilog
module grouped_ismu(
    input clk, rstn,
    input [15:0] int_sources,
    input [3:0] group_mask,
    input req,
    output reg ack,
    output reg [3:0] group_int
);
    reg [3:0] group_int_next;
    reg req_r;
    
    // Optimized group calculation using direct bit slicing and efficient reduction operations
    wire [3:0] group_active;
    
    // Determine which groups have active interrupts (optimized reduction)
    assign group_active[0] = |int_sources[3:0];
    assign group_active[1] = |int_sources[7:4];
    assign group_active[2] = |int_sources[11:8];
    assign group_active[3] = |int_sources[15:12];
    
    // Calculate masked group interrupts with single operation
    always @(*) begin
        group_int_next = group_active & ~group_mask;
    end
    
    // Edge detection for req signal with single register
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            req_r <= 1'b0;
        else
            req_r <= req;
    end
    
    // Optimized handshaking logic with reduced conditions
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            group_int <= 4'h0;
            ack <= 1'b0;
        end
        else begin
            // Use edge detection for control
            if (req & ~req_r) begin
                // Rising edge of request
                group_int <= group_int_next;
                ack <= 1'b1;
            end
            else if (~req & req_r) begin
                // Falling edge of request
                ack <= 1'b0;
            end
        end
    end
endmodule