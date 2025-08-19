//SystemVerilog
module johnson_counter (
    input wire clk, arst,
    input wire req,           // Request signal
    output wire ack,          // Acknowledge signal
    output wire [3:0] count_out
);
    // Input stage - capture req directly
    reg req_sampled;
    
    // Counter state registers
    reg [3:0] count;
    
    // Acknowledgment register
    reg ack_reg;
    
    // Captured request signal (moved after combinational logic)
    always @(posedge clk or posedge arst) begin
        if (arst)
            req_sampled <= 1'b0;
        else
            req_sampled <= req;
    end
    
    // Edge detection signal (combinational)
    wire req_edge = req && !req_sampled;
    
    // Johnson counter logic - updates on valid handshake
    always @(posedge clk or posedge arst) begin
        if (arst)
            count <= 4'b0000;
        else if (req_edge)  // Process data on detected edge
            count <= {count[2:0], ~count[3]};
    end
    
    // Acknowledge generation logic (simplified)
    always @(posedge clk or posedge arst) begin
        if (arst)
            ack_reg <= 1'b0;
        else if (req_edge)  // Rising edge of req
            ack_reg <= 1'b1;
        else if (!req)
            ack_reg <= 1'b0;
    end
    
    // Output assignments
    assign count_out = count;
    assign ack = ack_reg;
endmodule