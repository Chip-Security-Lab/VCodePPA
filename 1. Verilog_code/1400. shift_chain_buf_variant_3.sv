//SystemVerilog
module shift_chain_buf #(parameter DW=8, DEPTH=4) (
    input clk, en,
    input serial_in,
    input [DW-1:0] parallel_in,
    input load,
    input rst,
    output serial_out,
    output [DW*DEPTH-1:0] parallel_out
);
    // Optimized shift register implementation with single register array
    reg [DW-1:0] shift_reg [0:DEPTH-1];
    
    // Control signals with reduced pipeline stages
    reg valid_r, load_r;
    reg [DW-1:0] parallel_data_r;
    reg serial_data_r;
    
    // Input capture and control logic - single stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_r <= 1'b0;
            load_r <= 1'b0;
            parallel_data_r <= {DW{1'b0}};
            serial_data_r <= 1'b0;
            
            // Reset all shift registers in one loop
            for(integer i=0; i<DEPTH; i=i+1)
                shift_reg[i] <= {DW{1'b0}};
        end 
        else begin
            // Register control signals
            valid_r <= en;
            load_r <= load;
            parallel_data_r <= parallel_in;
            serial_data_r <= serial_in;
            
            // Perform shift operation when enabled
            if (en) begin
                if (load) begin
                    // Parallel load handling with direct assignments
                    shift_reg[0] <= parallel_in;
                    
                    // Cascade the shift operations
                    for(integer i=1; i<DEPTH; i=i+1)
                        shift_reg[i] <= shift_reg[i-1];
                end
                else begin
                    // Serial input with optimized bit handling
                    shift_reg[0] <= {{(DW-1){1'b0}}, serial_in};
                    
                    // Cascade the shift operations
                    for(integer i=1; i<DEPTH; i=i+1)
                        shift_reg[i] <= shift_reg[i-1];
                end
            end
        end
    end
    
    // Direct output assignments with no additional register stage
    assign serial_out = shift_reg[DEPTH-1][0];
    
    // Optimized parallel output generation
    genvar g;
    generate
        for(g=0; g<DEPTH; g=g+1)
            assign parallel_out[g*DW +: DW] = shift_reg[g];
    endgenerate
endmodule