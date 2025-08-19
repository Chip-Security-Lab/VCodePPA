//SystemVerilog
module ring_divider (
    input  wire clk_in,
    input  wire rst_n,
    output wire clk_out
);
    // Main ring counter registers
    reg [4:0] ring;
    
    // Pipelined buffer registers to reduce critical path
    reg [4:0] ring_buf1;
    reg [4:0] ring_buf2;
    
    // Intermediate signal for pipelining the rotation operation
    reg [4:0] ring_rotated;
    
    // Pipeline stage 1: Calculate rotation
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            ring_rotated <= 5'b00001;
        else
            ring_rotated <= {ring[0], ring[4:1]};
    end
    
    // Pipeline stage 2: Update main ring
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            ring <= 5'b00001;
        else
            ring <= ring_rotated;
    end
    
    // First level buffer with reduced load
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            ring_buf1 <= 5'b00001;
        else
            ring_buf1 <= ring;
    end
    
    // Second level buffer for final fan-out optimization
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            ring_buf2 <= 5'b00001;
        else
            ring_buf2 <= ring_buf1;
    end
    
    // Output assignment
    assign clk_out = ring_buf2[0];
endmodule