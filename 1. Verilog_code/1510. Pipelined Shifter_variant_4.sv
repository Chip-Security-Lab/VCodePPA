//SystemVerilog
// IEEE 1364-2005
module pipelined_shifter #(parameter STAGES = 4, WIDTH = 8) (
    input wire clk, rst_n,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // Main pipeline registers
    reg [WIDTH-1:0] pipe [0:STAGES-1];
    
    // Fan-out buffering for integer i control signal
    reg [2:0] i_buf1, i_buf2; // Buffered copies of loop index
    
    // Buffered reset signal to reduce fan-out
    reg rst_n_buf1, rst_n_buf2;
    
    // Data buffering for high fan-out paths
    reg [WIDTH-1:0] data_in_buf;
    reg [WIDTH-1:0] pipe_buf [0:STAGES-2]; // Buffered version of pipe for driving next stage
    
    integer i;
    
    // Reset signal buffering
    always @(posedge clk) begin
        rst_n_buf1 <= rst_n;
        rst_n_buf2 <= rst_n_buf1;
    end
    
    // Input data buffering
    always @(posedge clk) begin
        if (!rst_n_buf1)
            data_in_buf <= {WIDTH{1'b0}};
        else
            data_in_buf <= data_in;
    end
    
    // Main pipeline logic with reduced fan-out
    always @(posedge clk or negedge rst_n_buf2) begin
        for (i = 0; i < STAGES; i = i + 1) begin
            // Buffer the loop index for better timing
            i_buf1 <= i;
            i_buf2 <= i_buf1;
            
            pipe[i] <= (!rst_n_buf2) ? {WIDTH{1'b0}} : 
                      (i_buf2 == 0) ? data_in_buf : pipe_buf[i-1];
        end
    end
    
    // Create buffered copies of pipe registers to reduce fan-out
    genvar j;
    generate
        for (j = 0; j < STAGES-1; j = j + 1) begin : pipe_buffers
            always @(posedge clk) begin
                if (!rst_n_buf2)
                    pipe_buf[j] <= {WIDTH{1'b0}};
                else
                    pipe_buf[j] <= pipe[j];
            end
        end
    endgenerate
    
    assign data_out = pipe[STAGES-1];
endmodule