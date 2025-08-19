//SystemVerilog
module one_hot_counter (
    input wire clock, reset_n,
    output reg [7:0] one_hot
);
    reg [7:0] pre_one_hot;
    reg [7:0] pre_one_hot_buf1;
    reg [7:0] pre_one_hot_buf2;
    
    // Generate next one-hot state
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            pre_one_hot <= 8'b00000001;
        else
            pre_one_hot <= {pre_one_hot[6:0], pre_one_hot[7]};
    end
    
    // First level buffer for high fanout signal
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            pre_one_hot_buf1 <= 8'b00000001;
        else
            pre_one_hot_buf1 <= pre_one_hot;
    end
    
    // Second level buffer for high fanout signal
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            pre_one_hot_buf2 <= 8'b00000001;
        else
            pre_one_hot_buf2 <= pre_one_hot;
    end
    
    // Output stage - use buffered signals
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            one_hot <= 8'b00000001;
        else
            one_hot <= pre_one_hot_buf1[3:0] | pre_one_hot_buf2[7:4];
    end
endmodule