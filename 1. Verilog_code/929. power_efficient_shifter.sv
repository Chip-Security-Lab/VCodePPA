module power_efficient_shifter(
    input clk,
    input en,
    input [7:0] data_in,
    input [2:0] shift,
    output reg [7:0] data_out
);
    // Power gating signals
    wire active_stage0, active_stage1, active_stage2;
    
    // Enable signals for power efficiency
    assign active_stage0 = en & |shift;
    assign active_stage1 = en & |shift[2:1];
    assign active_stage2 = en & shift[2];
    
    // Power-efficient staged shift
    always @(posedge clk) begin
        if (en) begin
            // Only perform shift if non-zero shift amount
            if (active_stage0) begin
                if (shift[0])
                    data_out <= {data_in[6:0], 1'b0};
                else
                    data_out <= data_in;
                    
                // Additional shifting stages are only active when needed
                if (active_stage1) begin
                    if (shift[1])
                        data_out <= {data_out[5:0], 2'b0};
                    
                    if (active_stage2) begin
                        if (shift[2])
                            data_out <= {data_out[3:0], 4'b0};
                    end
                end
            end else
                data_out <= data_in; // No shift needed
        end
    end
endmodule