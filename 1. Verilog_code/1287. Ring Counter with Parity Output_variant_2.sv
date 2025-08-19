//SystemVerilog
module parity_ring_counter(
    input wire clk,
    input wire rst_n,
    output reg [3:0] count,
    output wire parity
);
    // Internal signals for the ring counter implementation
    reg [3:0] next_count;
    reg [3:0] count_buf1;
    
    // Calculate next count value - moved before register for retiming
    always @(*) begin
        next_count = {count[2:0], count[3]};
    end
    
    // Main counter logic - retimed to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 4'b0001;
        else
            count <= next_count;
    end
    
    // Buffer register for parity calculation with retimed input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count_buf1 <= 4'b0001;
        else
            count_buf1 <= count;
    end
    
    // Parity calculation using buffered count
    assign parity = ^count_buf1;
    
endmodule