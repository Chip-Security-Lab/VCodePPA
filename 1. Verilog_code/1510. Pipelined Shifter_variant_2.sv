//SystemVerilog
// IEEE 1364-2005 Verilog
module pipelined_shifter #(parameter STAGES = 4, WIDTH = 8) (
    input wire clk, rst_n,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Distributed pipeline registers instead of array to reduce fan-out and improve timing
    reg [WIDTH-1:0] pipe_stage1;
    reg [WIDTH-1:0] pipe_stage2;
    reg [WIDTH-1:0] pipe_stage3;
    
    // Splitting reset logic from data path to reduce critical path
    reg reset_pipe;
    
    // Reset synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_pipe <= 1'b1;
        end else begin
            reset_pipe <= 1'b0;
        end
    end
    
    // First pipeline stage
    always @(posedge clk) begin
        if (reset_pipe) begin
            pipe_stage1 <= {WIDTH{1'b0}};
        end else begin
            pipe_stage1 <= data_in;
        end
    end
    
    // Middle pipeline stages
    always @(posedge clk) begin
        if (reset_pipe) begin
            pipe_stage2 <= {WIDTH{1'b0}};
        end else begin
            pipe_stage2 <= pipe_stage1;
        end
    end
    
    // Additional pipeline stage for STAGES > 3
    generate
        if (STAGES > 3) begin
            always @(posedge clk) begin
                if (reset_pipe) begin
                    pipe_stage3 <= {WIDTH{1'b0}};
                end else begin
                    pipe_stage3 <= pipe_stage2;
                end
            end
        end
    endgenerate
    
    // Output stage
    always @(posedge clk) begin
        if (reset_pipe) begin
            data_out <= {WIDTH{1'b0}};
        end else begin
            if (STAGES > 3)
                data_out <= pipe_stage3;
            else
                data_out <= pipe_stage2;
        end
    end
endmodule