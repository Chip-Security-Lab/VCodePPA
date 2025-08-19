//SystemVerilog
module async_right_shifter (
    input            data_in,
    input      [3:0] control,
    output reg       data_out
);
    // Pipeline registers to break down the long combinational path
    reg [3:0] shift_stages;
    
    // Control signals registered to improve timing
    reg [3:0] control_r;
    
    // First pipeline stage
    always @(*) begin
        // Register control signals to reduce fanout
        control_r = control;
        
        // Stage 1: Process first shift operation
        shift_stages[3] = control_r[3] ? data_in : 1'b0;
        
        // Stage 2: Process second shift operation
        shift_stages[2] = control_r[2] ? shift_stages[3] : 1'b0;
        
        // Stage 3: Process third shift operation
        shift_stages[1] = control_r[1] ? shift_stages[2] : 1'b0;
        
        // Stage 4: Process fourth shift operation
        shift_stages[0] = control_r[0] ? shift_stages[1] : 1'b0;
        
        // Final output assignment
        data_out = shift_stages[0];
    end
endmodule