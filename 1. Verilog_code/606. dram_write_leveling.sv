module dram_write_leveling #(
    parameter DQ_BITS = 8
)(
    input clk,
    input training_en,
    output reg [DQ_BITS-1:0] dqs_pattern
);
    reg [7:0] phase_counter;
    
    always @(posedge clk) begin
        if(training_en) begin
            phase_counter <= phase_counter + 1;
            dqs_pattern <= {8{phase_counter[3]}};
        end else begin
            dqs_pattern <= {DQ_BITS{1'b0}};
        end
    end
endmodule
