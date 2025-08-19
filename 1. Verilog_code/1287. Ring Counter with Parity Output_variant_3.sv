//SystemVerilog
module parity_ring_counter(
    input wire clk,
    input wire rst_n,
    input wire ready,
    output reg valid,
    output reg [3:0] count,
    output wire parity
);
    reg [3:0] count_internal;
    reg ready_q;
    reg valid_internal;
    
    // Pre-compute next state to improve timing
    wire [3:0] next_count = {count[2:0], count[3]};
    
    // Moved parity calculation after register for better timing
    assign parity = ^count;
    
    // Register retiming: moved registers forward through combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_internal <= 4'b0001;
            valid_internal <= 1'b0;
            ready_q <= 1'b0;
            count <= 4'b0001;
            valid <= 1'b0;
        end else begin
            // Input register stage
            ready_q <= ready;
            
            // Internal processing
            if (ready && valid_internal) begin
                count_internal <= next_count;
                valid_internal <= 1'b1;
            end else if (!valid_internal) begin
                valid_internal <= 1'b1;
            end
            
            // Output register stage - moved forward through combinational logic
            count <= count_internal;
            valid <= valid_internal;
        end
    end
endmodule