//SystemVerilog
module and_xor_xnor_gate (
    input wire clk,       // Clock input
    input wire rst_n,     // Active-low reset
    input wire A, B, C,   // Input signals A, B, C
    output wire Y         // Registered output Y
);
    // Internal signals for module connections
    wire stage0_A, stage0_B, stage0_C;
    wire stage1_A, stage1_B, stage1_C;
    wire stage2_and_partial, stage2_xor_partial;
    wire stage3_and_result, stage3_xnor_result;
    wire stage4_and_prepared, stage4_xnor_prepared;
    wire stage5_xor_result;
    
    // Instantiate input registration module
    input_register input_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .A_in(A),
        .B_in(B),
        .C_in(C),
        .A_out(stage0_A),
        .B_out(stage0_B),
        .C_out(stage0_C)
    );
    
    // Instantiate input preparation module
    input_preparation prep_inst (
        .clk(clk),
        .rst_n(rst_n),
        .A_in(stage0_A),
        .B_in(stage0_B),
        .C_in(stage0_C),
        .A_out(stage1_A),
        .B_out(stage1_B),
        .C_out(stage1_C)
    );
    
    // Instantiate partial operation module
    partial_operations partial_ops_inst (
        .clk(clk),
        .rst_n(rst_n),
        .A_in(stage1_A),
        .B_in(stage1_B),
        .C_in(stage1_C),
        .and_result(stage2_and_partial),
        .xor_result(stage2_xor_partial)
    );
    
    // Instantiate complete operations module
    complete_operations complete_ops_inst (
        .clk(clk),
        .rst_n(rst_n),
        .and_partial(stage2_and_partial),
        .xor_partial(stage2_xor_partial),
        .and_result(stage3_and_result),
        .xnor_result(stage3_xnor_result)
    );
    
    // Instantiate operation preparation module
    operation_preparation op_prep_inst (
        .clk(clk),
        .rst_n(rst_n),
        .and_in(stage3_and_result),
        .xnor_in(stage3_xnor_result),
        .and_out(stage4_and_prepared),
        .xnor_out(stage4_xnor_prepared)
    );
    
    // Instantiate final XOR module
    final_xor_operation final_xor_inst (
        .clk(clk),
        .rst_n(rst_n),
        .and_in(stage4_and_prepared),
        .xnor_in(stage4_xnor_prepared),
        .xor_result(stage5_xor_result)
    );
    
    // Instantiate output registration module
    output_register output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(stage5_xor_result),
        .data_out(Y)
    );
    
endmodule

// Input registration module
module input_register (
    input wire clk,
    input wire rst_n,
    input wire A_in, B_in, C_in,
    output reg A_out, B_out, C_out
);
    // Input registration - Stage 0
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_out <= 1'b0;
            B_out <= 1'b0;
            C_out <= 1'b0;
        end else begin
            A_out <= A_in;
            B_out <= B_in;
            C_out <= C_in;
        end
    end
endmodule

// Input preparation module
module input_preparation (
    input wire clk,
    input wire rst_n,
    input wire A_in, B_in, C_in,
    output reg A_out, B_out, C_out
);
    // Stage 1: Input preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_out <= 1'b0;
            B_out <= 1'b0;
            C_out <= 1'b0;
        end else begin
            A_out <= A_in;
            B_out <= B_in;
            C_out <= C_in;
        end
    end
endmodule

// Partial operations module
module partial_operations (
    input wire clk,
    input wire rst_n,
    input wire A_in, B_in, C_in,
    output reg and_result, xor_result
);
    // Stage 2: Calculate partial operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 1'b0;
            xor_result <= 1'b0;
        end else begin
            and_result <= A_in & B_in;     // AND operation
            xor_result <= C_in ^ A_in;     // XOR part of XNOR
        end
    end
endmodule

// Complete operations module
module complete_operations (
    input wire clk,
    input wire rst_n,
    input wire and_partial, xor_partial,
    output reg and_result, xnor_result
);
    // Stage 3: Complete basic operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 1'b0;
            xnor_result <= 1'b0;
        end else begin
            and_result <= and_partial;
            xnor_result <= ~xor_partial;   // Complete XNOR
        end
    end
endmodule

// Operation preparation module
module operation_preparation (
    input wire clk,
    input wire rst_n,
    input wire and_in, xnor_in,
    output reg and_out, xnor_out
);
    // Stage 4: Prepare for XOR
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_out <= 1'b0;
            xnor_out <= 1'b0;
        end else begin
            and_out <= and_in;
            xnor_out <= xnor_in;
        end
    end
endmodule

// Final XOR operation module
module final_xor_operation (
    input wire clk,
    input wire rst_n,
    input wire and_in, xnor_in,
    output reg xor_result
);
    // Stage 5: Calculate XOR of results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_result <= 1'b0;
        end else begin
            xor_result <= and_in ^ xnor_in;
        end
    end
endmodule

// Output registration module
module output_register (
    input wire clk,
    input wire rst_n,
    input wire data_in,
    output reg data_out
);
    // Final output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
        end else begin
            data_out <= data_in;
        end
    end
endmodule