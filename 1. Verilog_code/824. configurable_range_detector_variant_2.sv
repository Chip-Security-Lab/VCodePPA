//SystemVerilog
module configurable_range_detector(
    input wire clock, resetn,
    input wire [15:0] data,
    input wire [15:0] bound_a, bound_b,
    input wire [1:0] mode,
    output reg detect_flag
);
    reg [15:0] data_reg;
    reg [15:0] bound_a_reg;
    reg [15:0] bound_b_reg;
    reg [1:0] mode_reg;
    wire [1:0] comp_result;
    wire [3:0] mode_decode;
    
    // Register data input
    always @(posedge clock or negedge resetn) begin
        if (!resetn) 
            data_reg <= 16'b0;
        else 
            data_reg <= data;
    end
    
    // Register bound_a input
    always @(posedge clock or negedge resetn) begin
        if (!resetn) 
            bound_a_reg <= 16'b0;
        else 
            bound_a_reg <= bound_a;
    end
    
    // Register bound_b input
    always @(posedge clock or negedge resetn) begin
        if (!resetn) 
            bound_b_reg <= 16'b0;
        else 
            bound_b_reg <= bound_b;
    end
    
    // Register mode input
    always @(posedge clock or negedge resetn) begin
        if (!resetn) 
            mode_reg <= 2'b0;
        else 
            mode_reg <= mode;
    end
    
    // Parallel comparison with balanced paths
    assign comp_result[0] = (data_reg >= bound_a_reg);
    assign comp_result[1] = (data_reg <= bound_b_reg);
    
    // Pre-compute mode combinations
    assign mode_decode[0] = comp_result[0] & comp_result[1];  // in_range
    assign mode_decode[1] = ~(comp_result[0] & comp_result[1]); // out_range
    assign mode_decode[2] = comp_result[0];  // above_only
    assign mode_decode[3] = comp_result[1];  // below_only
    
    // Output stage with balanced selection logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn) 
            detect_flag <= 1'b0;
        else 
            detect_flag <= mode_decode[mode_reg];
    end
endmodule