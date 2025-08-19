//SystemVerilog - IEEE 1364-2005
module decoder_delay_comp #(parameter STAGES=3) (
    input clk,
    input [4:0] addr,
    output [31:0] decoded
);
    reg [4:0] addr_pipe [0:STAGES-1];
    reg [4:0] addr_pipe_buf1_a, addr_pipe_buf1_b;
    reg [4:0] addr_pipe_buf2_a, addr_pipe_buf2_b;
    reg [31:0] decoded_reg;
    integer i;
    
    always @(posedge clk) begin
        addr_pipe[0] <= addr;
        for(i=1; i<STAGES; i=i+1)
            addr_pipe[i] <= addr_pipe[i-1];
    end
    
    // Distributed buffer registers for high fanout signal
    // Split the load between two parallel buffering paths
    always @(posedge clk) begin
        addr_pipe_buf1_a <= addr_pipe[STAGES-1];
        addr_pipe_buf1_b <= addr_pipe[STAGES-1];
        addr_pipe_buf2_a <= addr_pipe_buf1_a;
        addr_pipe_buf2_b <= addr_pipe_buf1_b;
    end
    
    // Split decoder logic into two parts to balance load
    reg [15:0] decoded_low, decoded_high;
    always @(posedge clk) begin
        // Lower 16 bits handled by first buffer path
        if (addr_pipe_buf2_a < 5'd16)
            decoded_low <= 1'b1 << addr_pipe_buf2_a;
        else
            decoded_low <= 16'h0;
            
        // Upper 16 bits handled by second buffer path
        if (addr_pipe_buf2_b >= 5'd16)
            decoded_high <= 1'b1 << (addr_pipe_buf2_b - 5'd16);
        else
            decoded_high <= 16'h0;
    end
    
    // Combine the decoded outputs
    always @(posedge clk) begin
        decoded_reg <= {decoded_high, decoded_low};
    end
    
    assign decoded = decoded_reg;
endmodule