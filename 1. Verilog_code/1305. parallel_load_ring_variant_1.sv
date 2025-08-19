//SystemVerilog
module parallel_load_ring (
    input clk,
    input reset,
    input load,
    input [3:0] parallel_in,
    output reg [3:0] ring
);

    // Pipeline registers with enable control
    reg load_pipe [1:0];
    reg [3:0] parallel_in_pipe [1:0];
    reg [3:0] shift_data_pipe [1:0];
    
    // First pipeline stage
    always @(posedge clk) begin
        if (reset) begin
            load_pipe[0] <= 1'b0;
            parallel_in_pipe[0] <= 4'b0;
            shift_data_pipe[0] <= 4'b0;
        end else begin
            load_pipe[0] <= load;
            parallel_in_pipe[0] <= parallel_in;
            // Pre-compute ring shift operation
            shift_data_pipe[0] <= {ring[0], ring[3:1]};
        end
    end
    
    // Second pipeline stage with forwarding logic
    always @(posedge clk) begin
        if (reset) begin
            load_pipe[1] <= 1'b0;
            parallel_in_pipe[1] <= 4'b0;
            shift_data_pipe[1] <= 4'b0;
            ring <= 4'b0;
        end else begin
            // Pipeline registers
            load_pipe[1] <= load_pipe[0];
            parallel_in_pipe[1] <= parallel_in_pipe[0];
            shift_data_pipe[1] <= shift_data_pipe[0];
            
            // Output multiplexer combined with final stage
            ring <= load_pipe[1] ? parallel_in_pipe[1] : shift_data_pipe[1];
        end
    end

endmodule