//SystemVerilog
module dram_burst_length #(
    parameter MAX_BURST = 8
)(
    input clk,
    input rst_n,
    input [2:0] burst_cfg,
    output reg burst_end
);

    // Stage 1 registers
    reg [3:0] burst_counter;
    reg [3:0] burst_max;
    reg valid;
    
    // Stage 1: Configuration and counter update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_max <= 0;
            burst_counter <= 0;
            valid <= 0;
            burst_end <= 0;
        end else begin
            if (!valid) begin
                burst_max <= {1'b0, burst_cfg} << 1;
                burst_counter <= 0;
                valid <= 1'b1;
                burst_end <= 0;
            end else begin
                if (burst_counter == burst_max) begin
                    burst_end <= 1'b1;
                    burst_counter <= 0;
                end else begin
                    burst_counter <= burst_counter + 1;
                    burst_end <= 0;
                end
            end
        end
    end

endmodule