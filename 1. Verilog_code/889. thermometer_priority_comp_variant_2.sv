//SystemVerilog
// IEEE 1364-2005
module thermometer_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] thermometer_out,
    output reg [$clog2(WIDTH)-1:0] priority_pos
);
    // Pipeline stage 1 registers
    reg [WIDTH-1:0] data_stage1;
    reg [$clog2(WIDTH)-1:0] priority_pos_stage1;
    
    // Pipeline stage 2 registers
    reg [$clog2(WIDTH)-1:0] priority_pos_stage2;
    
    // Priority logic combinational signals
    wire [$clog2(WIDTH)-1:0] priority_pos_comb;
    
    // Optimized priority encoder using lookup method instead of loop
    function automatic [$clog2(WIDTH)-1:0] find_priority;
        input [WIDTH-1:0] data;
        reg [$clog2(WIDTH)-1:0] pos;
        reg found;
        begin
            pos = 0;
            found = 0;
            
            // Using casez for more efficient hardware implementation
            casez(data)
                // Check groups of bits - more efficient than bit-by-bit checking
                {1'b1, {(WIDTH-1){1'b?}}}: begin 
                    pos = WIDTH-1;
                    found = 1;
                end
                
                default: begin
                    // Use parallel priority logic with binary tree structure
                    for (int i = WIDTH-2; i >= 0; i--) begin
                        if (!found && data[i]) begin
                            pos = i[$clog2(WIDTH)-1:0];
                            found = 1;
                        end
                    end
                end
            endcase
            
            find_priority = pos;
        end
    endfunction
    
    // Optimized priority encoder implementation
    assign priority_pos_comb = find_priority(data_in);
    
    // Thermometer code generation using efficient shifts
    function automatic [WIDTH-1:0] gen_thermometer;
        input [$clog2(WIDTH)-1:0] pos;
        begin
            // Create thermometer code using bit shifts instead of loops
            // (2^(pos+1) - 1) creates bits from 0 to pos all set to 1
            gen_thermometer = (1'b1 << (pos + 1'b1)) - 1'b1;
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline stages
            data_stage1 <= 0;
            priority_pos_stage1 <= 0;
            priority_pos_stage2 <= 0;
            thermometer_out <= 0;
            priority_pos <= 0;
        end else begin
            // Pipeline stage 1: Register inputs and priority calculation
            data_stage1 <= data_in;
            priority_pos_stage1 <= priority_pos_comb;
            
            // Pipeline stage 2: Pass priority position to next stage
            priority_pos_stage2 <= priority_pos_stage1;
            
            // Pipeline stage 3: Generate thermometer code using efficient shift operation
            thermometer_out <= gen_thermometer(priority_pos_stage2);
            
            // Forward priority position to output
            priority_pos <= priority_pos_stage2;
        end
    end
endmodule