//SystemVerilog
module sync_left_logical_shifter #(
    parameter DATA_WIDTH = 8,
    parameter SHIFT_WIDTH = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [SHIFT_WIDTH-1:0] shift_amount,
    output reg [DATA_WIDTH-1:0] data_out
);
    // Internal signals for barrel shifter stages
    wire [DATA_WIDTH-1:0] stage_out [SHIFT_WIDTH:0];
    
    // Input to first stage
    assign stage_out[0] = data_in;
    
    // Barrel shifter implementation
    genvar i;
    generate
        for (i = 0; i < SHIFT_WIDTH; i = i + 1) begin : shift_stage
            // For each bit position in shift_amount
            assign stage_out[i+1] = shift_amount[i] ? 
                                    {stage_out[i][DATA_WIDTH-1-(2**i):0], {(2**i){1'b0}}} : 
                                    stage_out[i];
        end
    endgenerate
    
    // Synchronous operation with active-low reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {DATA_WIDTH{1'b0}}; // Clear output on reset
        else
            data_out <= stage_out[SHIFT_WIDTH]; // Output from final stage
    end
endmodule