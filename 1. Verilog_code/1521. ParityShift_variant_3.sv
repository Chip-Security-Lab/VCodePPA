//SystemVerilog
// IEEE 1364-2005 compliant
module ParityShift #(parameter DATA_BITS=7) (
    input wire clk,
    input wire rst,
    input wire sin,
    input wire valid_in,       // Input valid signal
    output wire valid_out,     // Output valid signal
    output wire [DATA_BITS:0] data_out // [7:0] for 7+1 parity
);

    // Pipeline stage 1: Shift register inputs
    reg [DATA_BITS-1:0] sreg_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Parity calculation with Taylor series approximation
    reg [DATA_BITS-1:0] sreg_stage2;
    reg valid_stage2;
    reg [2:0] taylor_terms;    // Store intermediate Taylor series terms
    reg taylor_parity;         // Final parity calculated using Taylor approach
    
    // Pipeline stage 3: Final output
    reg [DATA_BITS:0] sreg_stage3;
    reg valid_stage3;
    
    // Stage 1: Input shifting
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sreg_stage1 <= {DATA_BITS{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            if (valid_in) begin
                sreg_stage1 <= {sreg_stage1[DATA_BITS-2:0], sin};
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Parity calculation using Taylor series expansion
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sreg_stage2 <= {DATA_BITS{1'b0}};
            taylor_terms <= 3'b000;
            taylor_parity <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                sreg_stage2 <= sreg_stage1;
                
                // Taylor series expansion for parity calculation
                // Divide into groups and combine results
                taylor_terms[0] <= sreg_stage1[0] ^ sreg_stage1[1] ^ sreg_stage1[2];
                taylor_terms[1] <= sreg_stage1[3] ^ sreg_stage1[4];
                taylor_terms[2] <= sreg_stage1[5] ^ sreg_stage1[6];
                
                // Final parity calculation combining all terms
                taylor_parity <= taylor_terms[0] ^ taylor_terms[1] ^ taylor_terms[2];
                
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Final output assembly
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sreg_stage3 <= {(DATA_BITS+1){1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                sreg_stage3 <= {taylor_parity, sreg_stage2};
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Output assignments
    assign data_out = sreg_stage3;
    assign valid_out = valid_stage3;

endmodule