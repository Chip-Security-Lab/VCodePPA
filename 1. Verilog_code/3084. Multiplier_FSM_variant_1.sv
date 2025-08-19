//SystemVerilog
module Multiplier_Pipeline #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input start,
    input [WIDTH-1:0] multiplicand,
    input [WIDTH-1:0] multiplier,
    output reg [2*WIDTH-1:0] product,
    output reg done
);

    // Pipeline stages
    localparam STAGES = 4;
    
    // Pipeline registers
    reg [WIDTH-1:0] mcand_pipe [0:STAGES-1];
    reg [WIDTH-1:0] mplier_pipe [0:STAGES-1];
    reg [2*WIDTH-1:0] accum_pipe [0:STAGES-1];
    reg [3:0] counter_pipe [0:STAGES-1];
    reg valid_pipe [0:STAGES-1];
    
    // Pipeline control
    wire pipeline_ready;
    reg pipeline_start;
    
    // Pipeline ready logic
    assign pipeline_ready = !valid_pipe[STAGES-1] || done;
    
    // Pipeline start logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pipeline_start <= 1'b0;
        else
            pipeline_start <= start && pipeline_ready;
    end
    
    // Pipeline stage 0 - Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe[0] <= 1'b0;
            mcand_pipe[0] <= 0;
            mplier_pipe[0] <= 0;
            accum_pipe[0] <= 0;
            counter_pipe[0] <= 0;
        end else if (pipeline_start) begin
            valid_pipe[0] <= 1'b1;
            mcand_pipe[0] <= multiplicand;
            mplier_pipe[0] <= multiplier;
            accum_pipe[0] <= 0;
            counter_pipe[0] <= 0;
        end else if (pipeline_ready) begin
            valid_pipe[0] <= 1'b0;
        end
    end
    
    // Pipeline stages 1-3
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : pipeline_stages
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    valid_pipe[i] <= 1'b0;
                    mcand_pipe[i] <= 0;
                    mplier_pipe[i] <= 0;
                    accum_pipe[i] <= 0;
                    counter_pipe[i] <= 0;
                end else if (pipeline_ready) begin
                    valid_pipe[i] <= valid_pipe[i-1];
                    mcand_pipe[i] <= mcand_pipe[i-1];
                    mplier_pipe[i] <= mplier_pipe[i-1];
                    
                    // Stage-specific operations
                    if (i == 1) begin // ADD stage
                        if (mplier_pipe[i-1][0])
                            accum_pipe[i] <= accum_pipe[i-1] + {mcand_pipe[i-1], {WIDTH{1'b0}}};
                        else
                            accum_pipe[i] <= accum_pipe[i-1];
                        counter_pipe[i] <= counter_pipe[i-1];
                    end else if (i == 2) begin // SHIFT stage
                        accum_pipe[i] <= {1'b0, accum_pipe[i-1][2*WIDTH-1:1]};
                        mplier_pipe[i] <= {1'b0, mplier_pipe[i-1][WIDTH-1:1]};
                        counter_pipe[i] <= counter_pipe[i-1] + 1;
                    end else if (i == 3) begin // DONE stage
                        if (counter_pipe[i-1] == WIDTH-1) begin
                            product <= accum_pipe[i-1];
                            done <= 1'b1;
                        end else begin
                            done <= 1'b0;
                        end
                    end
                end
            end
        end
    endgenerate
    
    // Done signal control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            done <= 1'b0;
        else if (done)
            done <= 1'b0;
    end

endmodule