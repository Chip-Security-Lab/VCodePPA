//SystemVerilog
module async_delay_buf #(
    parameter DW    = 8,    // Data width
    parameter DEPTH = 3     // Pipeline depth
) (
    input              clk,      // Clock signal
    input              en,       // Enable signal
    input  [DW-1:0]    data_in,  // Input data
    output [DW-1:0]    data_out  // Output data after delay
);
    // Delay pipeline registers with clear naming
    reg [DW-1:0] pipe_stage [0:DEPTH];
    
    // Buffered enable signals to reduce fan-out
    reg en_buf1, en_buf2;
    
    // Enable signal buffering registers for stage control
    reg [DEPTH-1:0] stage_enables;
    
    // Output register to buffer the final stage
    reg [DW-1:0] data_out_reg;
    
    // Intermediate buffer registers for pipe_stage to reduce fan-out
    reg [DW-1:0] pipe_buf [0:DEPTH-1];
    
    //-----------------------------------------------------------
    // Primary enable signal buffering to improve timing
    //-----------------------------------------------------------
    always @(posedge clk) begin
        en_buf1 <= en;
    end
    
    always @(posedge clk) begin
        en_buf2 <= en_buf1;
    end
    
    //-----------------------------------------------------------
    // Stage enable signal generation for load balancing
    //-----------------------------------------------------------
    genvar j;
    generate
        for (j = 0; j < DEPTH; j = j + 1) begin : enable_buffers
            always @(posedge clk) begin
                stage_enables[j] <= (j < DEPTH/2) ? en_buf1 : en_buf2;
            end
        end
    endgenerate
    
    //-----------------------------------------------------------
    // First pipeline stage with dedicated enable
    //-----------------------------------------------------------
    always @(posedge clk) begin
        if (en_buf1) begin
            pipe_stage[0] <= data_in;
        end
    end
    
    //-----------------------------------------------------------
    // Pipeline stages buffer generation to reduce critical paths
    //-----------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : delay_pipe
            // Buffer the current stage value (separate from updating)
            always @(posedge clk) begin
                pipe_buf[i] <= pipe_stage[i];
            end
            
            // Update the next stage using the buffered value
            always @(posedge clk) begin
                if (stage_enables[i]) begin
                    pipe_stage[i+1] <= pipe_buf[i];
                end
            end
        end
    endgenerate
    
    //-----------------------------------------------------------
    // Output buffering for improved timing and load isolation
    //-----------------------------------------------------------
    always @(posedge clk) begin
        data_out_reg <= pipe_stage[DEPTH];
    end
    
    //-----------------------------------------------------------
    // Output assignment - continuous assignment for clarity
    //-----------------------------------------------------------
    assign data_out = data_out_reg;

endmodule