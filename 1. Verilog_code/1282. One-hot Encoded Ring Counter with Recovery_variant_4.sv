//SystemVerilog
module one_hot_ring_counter(
    input wire clk,
    input wire rst_n,
    input wire ready,         // Receiver is ready to accept data
    output reg valid,         // Data is valid
    output reg [3:0] one_hot  // Data output
);
    // Pre-compute next state logic without pipelining
    wire [3:0] next_value;
    assign next_value = (one_hot == 4'b0000) ? 4'b0001 : {one_hot[2:0], one_hot[3]};
    
    // Control logic without intermediate pipeline stage
    reg update_counter;
    
    always @(*) begin
        if (!valid)
            update_counter = 1'b1;
        else if (valid && ready)
            update_counter = 1'b1;
        else
            update_counter = 1'b0;
    end
    
    // Single stage register update with forward retiming
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_hot <= 4'b0001; // Start with bit 0 active
            valid <= 1'b0;      // No valid data on reset
        end
        else begin
            if (update_counter) begin
                one_hot <= next_value;
                valid <= 1'b1;
            end
            else begin
                one_hot <= one_hot;
                valid <= valid;
            end
        end
    end
endmodule