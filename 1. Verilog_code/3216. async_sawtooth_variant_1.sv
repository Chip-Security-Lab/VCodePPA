//SystemVerilog
module async_sawtooth(
    input clock,
    input arst,
    input [7:0] increment,
    output reg [9:0] sawtooth_out
);

    // Reduced pipeline - only one intermediate stage
    reg [9:0] sum_stage;
    
    // Combined stage: Addition with direct feed to output register
    always @(posedge clock or posedge arst) begin
        if (arst)
            sum_stage <= 10'h000;
        else
            sum_stage <= sawtooth_out + {2'b00, increment};
    end
    
    // Output assignment
    always @(posedge clock or posedge arst) begin
        if (arst)
            sawtooth_out <= 10'h000;
        else
            sawtooth_out <= sum_stage;
    end

endmodule