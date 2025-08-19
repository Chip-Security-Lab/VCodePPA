//SystemVerilog
module gray_ring_counter (
    input clk, rst_n,
    output reg [3:0] gray_out
);
    reg [3:0] internal_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            internal_state <= 4'b0001;
        else 
            internal_state <= {internal_state[0], internal_state[3:1] ^ {2'b00, internal_state[0]}};
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gray_out <= 4'b0001;
        else
            gray_out <= internal_state;
    end
endmodule