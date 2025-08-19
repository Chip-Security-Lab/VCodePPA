//SystemVerilog
module boundary_check_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] upper_bound, lower_bound,
    output reg [$clog2(WIDTH)-1:0] priority_pos,
    output reg in_bounds, valid
);
    wire [WIDTH-1:0] masked_data;
    wire bounds_check;
    wire [$clog2(WIDTH)-1:0] encoded_priority;
    wire has_priority;
    
    // Optimize bounds checking logic - compute combinationally
    assign bounds_check = (data >= lower_bound) && (data <= upper_bound);
    
    // Apply mask based on bounds check
    assign masked_data = bounds_check ? data : {WIDTH{1'b0}};
    
    // Optimize priority encoding using parallel logic
    generate
        if (WIDTH <= 2) begin: small_width
            assign encoded_priority = masked_data[1] ? 1'b1 : 1'b0;
            assign has_priority = |masked_data;
        end
        else begin: priority_encode
            reg [$clog2(WIDTH)-1:0] pos;
            reg valid_bit;
            
            always @(*) begin
                pos = {$clog2(WIDTH){1'b0}};
                valid_bit = 1'b0;
                
                // Using casez for efficient priority encoding
                casez (masked_data)
                    // Pattern matching for most significant bit
                    {1'b1, {(WIDTH-1){1'b?}}}: begin 
                        pos = WIDTH-1; 
                        valid_bit = 1'b1; 
                    end
                    
                    // Generate efficient patterns for remaining bits
                    // Only checking certain positions improves timing
                    {1'b0, 1'b1, {(WIDTH-2){1'b?}}}: begin 
                        pos = WIDTH-2; 
                        valid_bit = 1'b1; 
                    end
                    
                    default: begin
                        // For remaining positions, check in groups
                        if (|masked_data[WIDTH/2-1:0]) begin
                            // Lower half has priority bits
                            integer i;
                            for (i = WIDTH/2-1; i >= 0; i = i - 1)
                                if (masked_data[i]) begin
                                    pos = i[$clog2(WIDTH)-1:0];
                                    valid_bit = 1'b1;
                                end
                        end else if (|masked_data[WIDTH-1:WIDTH/2]) begin
                            // Upper half (except already checked positions)
                            integer i;
                            for (i = WIDTH-3; i >= WIDTH/2; i = i - 1)
                                if (masked_data[i]) begin
                                    pos = i[$clog2(WIDTH)-1:0];
                                    valid_bit = 1'b1;
                                end
                        end
                    end
                endcase
            end
            
            assign encoded_priority = pos;
            assign has_priority = valid_bit;
        end
    endgenerate
    
    // Register outputs for timing closure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_pos <= {$clog2(WIDTH){1'b0}};
            in_bounds <= 1'b0;
            valid <= 1'b0;
        end else begin
            in_bounds <= bounds_check;
            priority_pos <= encoded_priority;
            valid <= has_priority;
        end
    end
endmodule