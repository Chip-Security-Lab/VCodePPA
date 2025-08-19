//SystemVerilog
///////////////////////////////////////////////////////////
// File: prio_encoder_top.v
// Top level priority encoder module
///////////////////////////////////////////////////////////
module prio_encoder_top (
    input [7:0] req,
    output [2:0] code
);
    // Direct priority encoding logic
    // Optimized to reduce hierarchy and improve timing
    reg [2:0] code_reg;
    
    always @(*) begin
        if (req[7])
            code_reg = 3'h7;
        else if (req[6])
            code_reg = 3'h6;
        else if (req[5])
            code_reg = 3'h5;
        else if (req[4])
            code_reg = 3'h4;
        else if (req[3])
            code_reg = 3'h3;
        else if (req[2])
            code_reg = 3'h2;
        else if (req[1])
            code_reg = 3'h1;
        else if (req[0])
            code_reg = 3'h0;
        else
            code_reg = 3'h0;
    end
    
    assign code = code_reg;
    
endmodule

///////////////////////////////////////////////////////////
// 4-bit priority encoder submodule
///////////////////////////////////////////////////////////
module prio_encoder_4bit (
    input [3:0] req,
    output valid,
    output [1:0] code
);
    // Simplified valid logic
    assign valid = req[3] | req[2] | req[1] | req[0];
    
    // Optimized priority encoding using direct boolean expressions
    // Reduced logic depth and improved timing
    assign code[1] = req[3] | req[2];
    assign code[0] = req[3] | (~req[2] & req[1]);
    
endmodule

///////////////////////////////////////////////////////////
// Output selector submodule
///////////////////////////////////////////////////////////
module prio_output_selector (
    input upper_valid,
    input [1:0] upper_code,
    input lower_valid,
    input [1:0] lower_code,
    output [2:0] code
);
    // Simplified boolean expressions for code assignment
    // Eliminates if-else branch and improves timing
    assign code[2] = upper_valid;
    assign code[1] = upper_valid ? upper_code[1] : lower_code[1];
    assign code[0] = upper_valid ? upper_code[0] : lower_code[0];
    
endmodule