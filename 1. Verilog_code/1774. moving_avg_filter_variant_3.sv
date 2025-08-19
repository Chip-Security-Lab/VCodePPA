//SystemVerilog
module moving_avg_filter #(
    parameter DATA_W = 8,
    parameter DEPTH = 4,
    parameter LOG2_DEPTH = 2  // log2(DEPTH)
)(
    input wire clk, reset_n, enable,
    input wire [DATA_W-1:0] data_i,
    output reg [DATA_W-1:0] data_o
);
    reg [DATA_W-1:0] samples [DEPTH-1:0];
    reg [DATA_W+LOG2_DEPTH-1:0] sum;
    integer i;
    
    always @(posedge clk) begin
        case ({reset_n, enable})
            2'b00, 2'b01: begin  // !reset_n (reset active)
                for (i = 0; i < DEPTH; i = i + 1)
                    samples[i] <= 0;
                sum <= 0;
                data_o <= 0;
            end
            
            2'b10: begin  // reset_n && !enable (idle)
                // Hold current state
            end
            
            2'b11: begin  // reset_n && enable (processing)
                // Shift in new sample, update sum
                sum <= sum - samples[DEPTH-1] + data_i;
                for (i = DEPTH-1; i > 0; i = i - 1)
                    samples[i] <= samples[i-1];
                samples[0] <= data_i;
                data_o <= sum >> LOG2_DEPTH;
            end
            
            default: begin  // Required for synthesis tools
                // Hold current state
            end
        endcase
    end
endmodule