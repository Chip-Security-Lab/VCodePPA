module low_power_bridge #(parameter DWIDTH=32) (
    input clk, rst_n, clk_en,
    input [DWIDTH-1:0] in_data,
    input in_valid, power_save,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready
);
    reg active;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active <= 1;
            out_valid <= 0;
            in_ready <= 1;
        end else if (power_save && out_valid && out_ready) begin
            active <= 0;  // Enter low power when transaction completes
        end else if (!power_save) begin
            active <= 1;  // Exit low power mode
        end
    end
    
    // Clock-gated logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 0;
        end else if (active && clk_en) begin
            if (in_valid && in_ready) begin
                out_data <= in_data;
                out_valid <= 1;
                in_ready <= 0;
            end else if (out_valid && out_ready) begin
                out_valid <= 0;
                in_ready <= 1;
            end
        end
    end
endmodule