//SystemVerilog
module tunstall_encoder #(
    parameter CODEWORD_WIDTH = 4
)(
    input                             clk_i,
    input                             enable_i,
    input                             rst_i,
    input      [7:0]                  data_i,
    input                             data_valid_i,
    output reg [CODEWORD_WIDTH-1:0]   code_o,
    output reg                        code_valid_o
);
    // Pipeline stage registers
    reg [7:0]  buffer_stage1;
    reg        buffer_valid_stage1;
    reg [7:0]  data_stage1;
    reg        data_valid_stage1;
    reg        enable_stage1;
    
    // Stage 2 registers
    reg [7:0]  buffer_stage2;
    reg        buffer_valid_stage2;
    reg [7:0]  data_stage2;
    reg        enable_stage2;
    reg        process_data_stage2;
    
    // Pre-computed mapping values to reduce critical path
    reg [3:0]  mapping_result;
    wire [3:0] input_key;
    
    // Stage 3 registers
    reg [3:0]  code_stage3;
    reg        code_valid_stage3;
    
    // Assign key for mapping lookup - reduces logic depth
    assign input_key = {buffer_stage2[1:0], data_stage2[1:0]};
    
    // Stage 1: Input capturing and state tracking
    always @(posedge clk_i) begin
        if (rst_i) begin
            buffer_stage1 <= 8'h0;
            buffer_valid_stage1 <= 1'b0;
            data_stage1 <= 8'h0;
            data_valid_stage1 <= 1'b0;
            enable_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_i;
            data_valid_stage1 <= data_valid_i;
            enable_stage1 <= enable_i;
            
            // Simplify buffer logic condition
            buffer_valid_stage1 <= (enable_i && data_valid_i) ? 
                                   !buffer_valid_stage1 : 
                                   buffer_valid_stage1;
                                   
            if (enable_i && data_valid_i && !buffer_valid_stage1) begin
                buffer_stage1 <= data_i;
            end
        end
    end

    // Stage 2: Data preparation and processing decision
    always @(posedge clk_i) begin
        if (rst_i) begin
            buffer_stage2 <= 8'h0;
            buffer_valid_stage2 <= 1'b0;
            data_stage2 <= 8'h0;
            enable_stage2 <= 1'b0;
            process_data_stage2 <= 1'b0;
        end else begin
            buffer_stage2 <= buffer_stage1;
            buffer_valid_stage2 <= buffer_valid_stage1;
            data_stage2 <= data_stage1;
            enable_stage2 <= enable_stage1;
            
            // Pre-compute processing flag
            process_data_stage2 <= enable_stage1 && data_valid_stage1 && buffer_valid_stage1;
        end
    end

    // Mapping logic separated to reduce critical path - runs in parallel with stage 2
    always @(*) begin
        case (input_key)
            4'b0000: mapping_result = 4'h0;
            4'b0001: mapping_result = 4'h1;
            4'b0010: mapping_result = 4'h2;
            4'b0011: mapping_result = 4'h3;
            4'b0100: mapping_result = 4'h4;
            4'b0101: mapping_result = 4'h5;
            4'b0110: mapping_result = 4'h6;
            4'b0111: mapping_result = 4'h7;
            4'b1000: mapping_result = 4'h8;
            4'b1001: mapping_result = 4'h9;
            4'b1010: mapping_result = 4'hA;
            4'b1011: mapping_result = 4'hB;
            4'b1100: mapping_result = 4'hC;
            4'b1101: mapping_result = 4'hD;
            4'b1110: mapping_result = 4'hE;
            4'b1111: mapping_result = 4'hF;
        endcase
    end

    // Stage 3: Codeword calculation - simplified to only update valid flag
    always @(posedge clk_i) begin
        if (rst_i) begin
            code_stage3 <= {CODEWORD_WIDTH{1'b0}};
            code_valid_stage3 <= 1'b0;
        end else begin
            // Use pre-computed mapping result
            code_stage3 <= process_data_stage2 ? mapping_result : code_stage3;
            code_valid_stage3 <= process_data_stage2 && enable_stage2;
        end
    end

    // Output stage
    always @(posedge clk_i) begin
        if (rst_i) begin
            code_o <= {CODEWORD_WIDTH{1'b0}};
            code_valid_o <= 1'b0;
        end else begin
            code_o <= code_stage3;
            code_valid_o <= code_valid_stage3;
        end
    end

endmodule