//SystemVerilog
// Wallace tree multiplier submodule
module wallace_multiplier #(parameter OPERAND_WIDTH = 8) (
    input [OPERAND_WIDTH-1:0] multiplicand,
    input [OPERAND_WIDTH-1:0] multiplier,
    output reg [OPERAND_WIDTH-1:0] result
);
    wire [OPERAND_WIDTH-1:0] pp [0:OPERAND_WIDTH-1];
    wire [OPERAND_WIDTH*2-1:0] sum1, sum2, sum3;
    wire [OPERAND_WIDTH*2-1:0] carry1, carry2, carry3;
    
    // Generate partial products
    genvar i;
    generate
        for (i = 0; i < OPERAND_WIDTH; i = i + 1) begin : pp_gen
            assign pp[i] = multiplier[i] ? multiplicand : 8'h00;
        end
    endgenerate
    
    // First stage of Wallace tree
    assign sum1 = pp[0] + (pp[1] << 1);
    assign carry1 = (pp[0] & (pp[1] << 1)) << 1;
    
    // Second stage
    assign sum2 = sum1 + (pp[2] << 2) + carry1;
    assign carry2 = ((sum1 & (pp[2] << 2)) | (sum1 & carry1) | ((pp[2] << 2) & carry1)) << 1;
    
    // Third stage
    assign sum3 = sum2 + (pp[3] << 3) + carry2;
    assign carry3 = ((sum2 & (pp[3] << 3)) | (sum2 & carry2) | ((pp[3] << 3) & carry2)) << 1;
    
    // Final addition
    always @* begin
        result = sum3[OPERAND_WIDTH-1:0] + carry3[OPERAND_WIDTH-1:0];
    end
endmodule

// Range checker submodule
module range_checker #(parameter MIN = 8'h20, MAX = 8'h3F) (
    input [7:0] value,
    output reg in_range
);
    always @* begin
        in_range = (value >= MIN) && (value <= MAX);
    end
endmodule

// Top-level decoder module
module decoder_range #(parameter MIN = 8'h20, MAX = 8'h3F) (
    input [7:0] addr,
    output active
);
    wire [7:0] wallace_result;
    
    // Instantiate Wallace multiplier
    wallace_multiplier #(.OPERAND_WIDTH(8)) wallace_inst (
        .multiplicand(MIN),
        .multiplier(addr),
        .result(wallace_result)
    );
    
    // Instantiate range checker
    range_checker #(.MIN(MIN), .MAX(MAX)) range_inst (
        .value(wallace_result),
        .in_range(active)
    );
endmodule