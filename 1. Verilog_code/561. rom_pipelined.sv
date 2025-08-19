module rom_pipelined #(parameter STAGES=2)(
    input clk,
    input [9:0] addr_in,
    output [7:0] data_out
);
    reg [9:0] pipe_addr [0:STAGES-1];
    reg [7:0] pipe_data [0:STAGES-1];
    reg [7:0] mem [0:1023];
    
    integer i;
    
    // Initialize memory with some default values
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = i & 8'hFF; // Simple pattern for testing
    end
    
    always @(posedge clk) begin
        pipe_addr[0] <= addr_in;
        for(i = 1; i < STAGES; i = i + 1)
            pipe_addr[i] <= pipe_addr[i-1];
            
        pipe_data[0] <= mem[pipe_addr[0]];
        for(i = 1; i < STAGES; i = i + 1)
            pipe_data[i] <= pipe_data[i-1];
    end
    
    assign data_out = pipe_data[STAGES-1];
endmodule