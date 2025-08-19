//SystemVerilog
/////////////////////////////////////////////////////////////////////////////
// Module:      shift_chain_buf
// Description: Pipelined shift register chain with parallel load capability
//              Optimized with critical path splitting for improved timing
// Standard:    IEEE 1364-2005
/////////////////////////////////////////////////////////////////////////////

module shift_chain_buf #(
    parameter DW    = 8,    // Data width
    parameter DEPTH = 4     // Pipeline depth
)(
    // Clock and control signals
    input                     clk,         // System clock
    input                     rst,         // Synchronous reset
    input                     en,          // Enable signal
    
    // Data input interface
    input                     serial_in,   // Serial data input
    input      [DW-1:0]       parallel_in, // Parallel data input
    input                     load,        // Load control signal
    
    // Data output interface
    output                    serial_out,  // Serial data output
    output reg [DW*DEPTH-1:0] parallel_out // Parallel data output (registered)
);

    // Pipeline stage registers with clear structure
    reg [DW-1:0] stage_reg [0:DEPTH-1];
    
    // Registered control signals to improve timing
    reg load_r;
    reg en_r;
    
    // Input selection logic pipeline
    reg [DW-1:0] input_data_stage1;
    reg [DW-1:0] input_data_stage2;
    reg serial_in_r;
    
    // Serial output register for timing improvement
    reg serial_out_reg;
    
    // Register control signals to break control path
    always @(posedge clk) begin
        if (rst) begin
            load_r <= 1'b0;
            en_r <= 1'b0;
            serial_in_r <= 1'b0;
        end
        else begin
            load_r <= load;
            en_r <= en;
            serial_in_r <= serial_in;
        end
    end
    
    // First stage of input path pipeline
    always @(posedge clk) begin
        if (rst) begin
            input_data_stage1 <= {DW{1'b0}};
        end
        else begin
            // Register parallel input to break input path
            input_data_stage1 <= parallel_in;
        end
    end
    
    // Second stage of input path pipeline
    always @(posedge clk) begin
        if (rst) begin
            input_data_stage2 <= {DW{1'b0}};
        end
        else begin
            // Input selection logic pipelined
            if (load_r)
                input_data_stage2 <= input_data_stage1;
            else
                input_data_stage2 <= {{(DW-1){1'b0}}, serial_in_r};
        end
    end
    
    // Main pipeline registers with pipelined control
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                stage_reg[i] <= {DW{1'b0}};
            serial_out_reg <= 1'b0;
        end 
        else if (en_r) begin
            // Shift operation with clear data flow
            for (i = DEPTH-1; i > 0; i = i - 1)
                stage_reg[i] <= stage_reg[i-1];
                
            // Input stage with pipelined data
            stage_reg[0] <= input_data_stage2;
            
            // Register serial output for better timing
            serial_out_reg <= stage_reg[DEPTH-1][0];
        end
    end
    
    // Split parallel output generation into two stages
    reg [DW*DEPTH-1:0] parallel_out_stage1;
    
    // First stage of parallel output generation
    always @(posedge clk) begin
        if (rst) begin
            parallel_out_stage1 <= {(DW*DEPTH){1'b0}};
        end
        else if (en_r) begin
            for (i = 0; i < DEPTH; i = i + 1)
                parallel_out_stage1[i*DW +: DW] <= stage_reg[i];
        end
    end
    
    // Second stage of parallel output generation
    always @(posedge clk) begin
        if (rst) begin
            parallel_out <= {(DW*DEPTH){1'b0}};
        end
        else begin
            parallel_out <= parallel_out_stage1;
        end
    end
    
    // Assign registered serial output
    assign serial_out = serial_out_reg;

endmodule