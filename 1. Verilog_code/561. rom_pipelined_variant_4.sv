//SystemVerilog
module rom_pipelined #(parameter STAGES=2)(
    input clk,
    input [9:0] addr_in,
    output [7:0] data_out
);
    // Buffered pipeline registers with reduced fanout
    reg [9:0] pipe_addr [0:STAGES-1];
    reg [9:0] pipe_addr_buf1 [0:STAGES-1]; // Buffer for pipe_addr
    reg [9:0] pipe_addr_buf2 [0:STAGES-1]; // Additional buffer for higher fanout

    reg [7:0] pipe_data [0:STAGES-1];
    reg [7:0] pipe_data_buf [0:STAGES-1]; // Buffer for pipe_data

    // Memory array
    reg [7:0] mem [0:1023];
    
    // Loop counters with buffers
    integer i;
    reg [4:0] i_buf1, i_buf2; // Buffered loop counters
    
    // Initialize memory with some default values
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = i & 8'hFF; // Simple pattern for testing
    end
    
    // Buffer the input address
    reg [9:0] addr_in_buf;
    always @(posedge clk) begin
        addr_in_buf <= addr_in;
    end

    // First pipeline stage with buffered signals
    always @(posedge clk) begin
        pipe_addr[0] <= addr_in_buf;
        pipe_addr_buf1[0] <= pipe_addr[0];
        pipe_addr_buf2[0] <= pipe_addr[0];
    end
    
    // Pipeline stages with buffer distribution
    always @(posedge clk) begin
        // Generate i_buf signals to reduce fanout of i
        i_buf1 <= 1;
        i_buf2 <= 1;
        
        // Use buffered values for pipe_addr propagation
        for(i = 1; i < STAGES; i = i + 1) begin
            if (i < (STAGES+1)/2) begin
                // Use first buffer for first half of stages
                pipe_addr[i] <= pipe_addr_buf1[i-1];
            end else begin
                // Use second buffer for second half of stages
                pipe_addr[i] <= pipe_addr_buf2[i-1];
            end
            pipe_addr_buf1[i] <= pipe_addr[i];
            pipe_addr_buf2[i] <= pipe_addr[i];
        end
    end
    
    // Memory read with buffered address
    always @(posedge clk) begin
        pipe_data[0] <= mem[pipe_addr_buf1[0]];
        pipe_data_buf[0] <= pipe_data[0];
    end
    
    // Data pipeline stages with buffer distribution
    always @(posedge clk) begin
        for(i = 1; i < STAGES; i = i + 1) begin
            pipe_data[i] <= pipe_data_buf[i-1];
            pipe_data_buf[i] <= pipe_data[i];
        end
    end
    
    // Output assignment using buffered data
    assign data_out = pipe_data_buf[STAGES-1];
endmodule