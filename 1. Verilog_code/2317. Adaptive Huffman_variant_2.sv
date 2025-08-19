//SystemVerilog
module adaptive_huffman #(
    parameter MAX_SYMBOLS = 16,
    parameter SYMBOL_WIDTH = 8
)(
    input                      clock,
    input                      reset,
    input [SYMBOL_WIDTH-1:0]   symbol_in,
    input                      symbol_valid,
    output reg [31:0]          code_out,
    output reg [5:0]           length_out,
    output reg                 code_valid
);
    // Symbol frequency counters
    reg [7:0] symbol_count [0:MAX_SYMBOLS-1];
    
    // Pipeline stage registers for symbol data
    reg [SYMBOL_WIDTH-1:0] symbol_stage1, symbol_stage2, symbol_stage3;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Frequency counter buffer
    reg [7:0] symbol_count_buf [0:MAX_SYMBOLS-1];
    
    // Partition the MAX_SYMBOLS into groups for load balancing
    localparam GROUP1_END = MAX_SYMBOLS/4 - 1;
    localparam GROUP2_END = MAX_SYMBOLS/2 - 1;
    localparam GROUP3_END = 3*MAX_SYMBOLS/4 - 1;
    
    // Register to store current symbol count for processing
    reg [7:0] current_symbol_count_stage2;
    reg [7:0] updated_symbol_count_stage2;
    
    // Temporary signals for code generation
    reg [31:0] code_stage3;
    reg [5:0] length_stage3;
    
    integer i;
    
    // Stage 1: Input buffering and initial processing
    always @(posedge clock) begin
        if (reset) begin
            symbol_stage1 <= {SYMBOL_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            symbol_stage1 <= symbol_in;
            valid_stage1 <= symbol_valid;
        end
    end
    
    // Stage 2: Frequency counter access and update preparation
    always @(posedge clock) begin
        if (reset) begin
            symbol_stage2 <= {SYMBOL_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            current_symbol_count_stage2 <= 8'd0;
            updated_symbol_count_stage2 <= 8'd0;
        end else begin
            symbol_stage2 <= symbol_stage1;
            valid_stage2 <= valid_stage1;
            
            // Fetch the current count for the symbol
            if (valid_stage1) begin
                current_symbol_count_stage2 <= symbol_count[symbol_stage1[3:0]];
                updated_symbol_count_stage2 <= symbol_count[symbol_stage1[3:0]] + 8'd1;
            end
        end
    end
    
    // Stage 3: Update frequency counter and generate codes
    always @(posedge clock) begin
        if (reset) begin
            symbol_stage3 <= {SYMBOL_WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
            code_stage3 <= 32'd0;
            length_stage3 <= 6'd0;
            
            // Reset all counters
            for (i = 0; i < MAX_SYMBOLS; i = i + 1)
                symbol_count[i] <= 8'd0;
        end else begin
            symbol_stage3 <= symbol_stage2;
            valid_stage3 <= valid_stage2;
            
            // Update frequency counter for the symbol
            if (valid_stage2) begin
                symbol_count[symbol_stage2[3:0]] <= updated_symbol_count_stage2;
                
                // Generate Huffman code based on symbol
                case (symbol_stage2[3:0])
                    4'h0: begin code_stage3 <= 32'h0; length_stage3 <= 6'd1; end
                    4'h1: begin code_stage3 <= 32'h2; length_stage3 <= 6'd2; end
                    4'h2: begin code_stage3 <= 32'h6; length_stage3 <= 6'd3; end
                    4'h3: begin code_stage3 <= 32'h7; length_stage3 <= 6'd3; end
                    4'h4: begin code_stage3 <= 32'h8; length_stage3 <= 6'd4; end
                    4'h5: begin code_stage3 <= 32'h9; length_stage3 <= 6'd4; end
                    4'h6: begin code_stage3 <= 32'hA; length_stage3 <= 6'd4; end
                    4'h7: begin code_stage3 <= 32'hB; length_stage3 <= 6'd4; end
                    4'h8: begin code_stage3 <= 32'hC; length_stage3 <= 6'd4; end
                    4'h9: begin code_stage3 <= 32'hD; length_stage3 <= 6'd4; end
                    4'hA: begin code_stage3 <= 32'hE; length_stage3 <= 6'd4; end
                    4'hB: begin code_stage3 <= 32'hF; length_stage3 <= 6'd4; end
                    4'hC: begin code_stage3 <= 32'h10; length_stage3 <= 6'd5; end
                    4'hD: begin code_stage3 <= 32'h11; length_stage3 <= 6'd5; end
                    4'hE: begin code_stage3 <= 32'h12; length_stage3 <= 6'd5; end
                    4'hF: begin code_stage3 <= 32'h13; length_stage3 <= 6'd5; end
                    default: begin code_stage3 <= 32'h3; length_stage3 <= 6'd2; end
                endcase
            end
        end
    end
    
    // Stage 4: Output stage
    always @(posedge clock) begin
        if (reset) begin
            code_out <= 32'd0;
            length_out <= 6'd0;
            code_valid <= 1'b0;
        end else begin
            code_valid <= valid_stage3;
            if (valid_stage3) begin
                code_out <= code_stage3;
                length_out <= length_stage3;
            end
        end
    end
    
    // Buffer the symbol count array for read operations (in parallel with main pipeline)
    always @(posedge clock) begin
        for (i = 0; i < MAX_SYMBOLS; i = i + 1)
            symbol_count_buf[i] <= symbol_count[i];
    end
    
endmodule