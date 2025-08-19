//SystemVerilog
module and_gate_4param #(
    parameter WIDTH = 4,             // Data width
    parameter PIPELINE_STAGES = 2    // Number of pipeline stages
) (
    input wire clk,                  // Clock signal
    input wire rst_n,                // Active-low reset
    input wire [WIDTH-1:0] a,        // Input A
    input wire [WIDTH-1:0] b,        // Input B
    input wire [WIDTH-1:0] c,        // Input C
    input wire [WIDTH-1:0] d,        // Input D
    output reg [WIDTH-1:0] y         // Output Y - changed to reg for better timing
);

    // Optimized pipeline structure with reduced register count
    reg [WIDTH-1:0] ab_stage;        // AB partial product
    reg [WIDTH-1:0] cd_stage;        // CD partial product
    
    // Generate attribute for synthesis optimization
    (* keep = "true" *)
    (* shreg_extract = "no" *)
    
    // First pipeline stage - compute and register partial products
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_stage <= {WIDTH{1'b0}};
            cd_stage <= {WIDTH{1'b0}};
        end else begin
            // Optimized computation with direct bitwise operations
            ab_stage <= a & b;
            cd_stage <= c & d;
        end
    end

    // Second pipeline stage - compute final result
    // Direct output assignment eliminates one level of registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= {WIDTH{1'b0}};
        end else begin
            // Optimized comparison chain using direct bitwise AND
            y <= ab_stage & cd_stage;
        end
    end

    // Synthesis directives for improved PPA
    /* synthesis extract_enable = "yes" */
    /* synthesis max_fanout = 10 */
    /* synthesis resource_sharing = on */
    /* synthesis area_optimize = on */

endmodule