//SystemVerilog
module sync_down_counter #(parameter WIDTH = 8) (
    input wire clk, rst, enable,
    output reg [WIDTH-1:0] q_out
);
    // Optimized pipeline registers with enable logic integration
    reg enable_pipe [1:0];
    reg [WIDTH-1:0] q_pipe [1:0];
    
    // Optimized Stage 1: Register inputs with single-cycle latency
    always @(posedge clk) begin
        if (rst) begin
            enable_pipe[0] <= 1'b0;
            q_pipe[0] <= {WIDTH{1'b1}};
        end else begin
            enable_pipe[0] <= enable;
            q_pipe[0] <= q_out;
        end
    end
    
    // Optimized Stage 2: Efficient decrement logic
    always @(posedge clk) begin
        if (rst) begin
            enable_pipe[1] <= 1'b0;
            q_pipe[1] <= {WIDTH{1'b1}};
        end else begin
            enable_pipe[1] <= enable_pipe[0];
            // Combined conditional assignment for better timing
            q_pipe[1] <= enable_pipe[0] ? (q_pipe[0] - 1'b1) : q_pipe[0];
        end
    end
    
    // Optimized output stage with simplified logic path
    always @(posedge clk) begin
        if (rst)
            q_out <= {WIDTH{1'b1}};
        else if (enable_pipe[1])
            q_out <= q_pipe[1];
        // Implicit else: maintain current value
    end
endmodule