//SystemVerilog
module biphase_mark_enc (
    input wire clk,
    input wire rst_n,
    input wire data_in,
    output reg encoded
);

    // Phase and data pipeline registers packed for efficient logic and routing
    reg [3:0] phase_pipeline;
    reg [3:0] data_pipeline;

    // Toggle phase and pipeline both phase and data in a single always block for optimal resource usage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_pipeline <= 4'b0000;
            data_pipeline  <= 4'b0000;
        end else begin
            phase_pipeline[0] <= ~phase_pipeline[0];
            phase_pipeline[3:1] <= phase_pipeline[2:0];
            data_pipeline[0] <= data_in;
            data_pipeline[3:1] <= data_pipeline[2:0];
        end
    end

    // Output logic with optimized conditional operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            encoded <= 1'b0;
        else
            encoded <= (data_pipeline[3] ^ ~phase_pipeline[3]);
    end

endmodule