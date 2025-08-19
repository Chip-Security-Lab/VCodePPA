//SystemVerilog
module priority_bridge #(parameter DWIDTH=32) (
    input clk, rst_n,
    input [DWIDTH-1:0] high_data, low_data,
    input high_valid, low_valid,
    output reg high_ready, low_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 0; 
            high_ready <= 1; 
            low_ready <= 1;
        end else begin
            // Check if output is ready to be updated
            if (out_valid && out_ready) begin
                out_valid <= 0;
                high_ready <= 1;
                low_ready <= 1;
            end else if (!out_valid) begin
                // Prioritize high_data if valid
                if (high_valid) begin
                    out_data <= high_data;
                    out_valid <= 1;
                    high_ready <= 0;
                    low_ready <= 0;
                end else if (low_valid) begin
                    out_data <= low_data;
                    out_valid <= 1;
                    low_ready <= 0;
                    high_ready <= 0;
                end
            end
        end
    end
endmodule