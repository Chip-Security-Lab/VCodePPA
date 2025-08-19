//SystemVerilog
module ArithEncoder #(parameter PREC=8) (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data,
    input wire valid_in,
    output wire ready_out,
    output wire [PREC-1:0] code,
    output wire valid_out
);

    // Input stage processing
    wire [PREC-1:0] initial_range = 8'hFF; // Initial range is 255
    
    // Stage 1 - Pre-compute division without waiting for the register
    wire [PREC-1:0] range_div = initial_range / 256;
    
    // Stage 1 registers - moved after initial computation
    reg [PREC-1:0] range_stage1;
    reg [PREC-1:0] low_stage1;
    reg [7:0] data_stage1;
    reg valid_stage1;
    
    // Stage 2 - Multiplication calculation
    reg [PREC-1:0] range_div_stage2;
    reg [PREC-1:0] low_stage2;
    reg [7:0] data_stage2;
    reg valid_stage2;
    
    // Stage 3 - Final calculation
    reg [PREC-1:0] range_stage3;
    reg [PREC-1:0] low_stage3;
    reg [PREC-1:0] range_div_stage3; // Added to store range_div for final calculation
    reg valid_stage3;
    
    // Output stage
    reg [PREC-1:0] code_reg;
    reg valid_out_reg;
    
    // Control signals
    assign ready_out = 1'b1; // Always ready to accept new data in this implementation
    assign valid_out = valid_out_reg;
    assign code = code_reg;
    
    // Pipeline stage 1 - Modified to include pre-computed division
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_stage1 <= {PREC{1'b0}};
            low_stage1 <= {PREC{1'b0}};
            data_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (valid_in && ready_out) begin
                range_stage1 <= initial_range;
                low_stage1 <= {PREC{1'b0}}; // Initialize low to 0
                data_stage1 <= data;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 2 - Store division results (moved forward)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_div_stage2 <= {PREC{1'b0}};
            low_stage2 <= {PREC{1'b0}};
            data_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                // Division is pre-computed
                range_div_stage2 <= range_div;
                low_stage2 <= low_stage1;
                data_stage2 <= data_stage1;
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 3 - Calculate multiplication results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_stage3 <= {PREC{1'b0}};
            low_stage3 <= {PREC{1'b0}};
            range_div_stage3 <= {PREC{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                range_stage3 <= range_div_stage2 * data_stage2;
                low_stage3 <= low_stage2;
                range_div_stage3 <= range_div_stage2; // Store for final calculation
                valid_stage3 <= valid_stage2;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Output stage - Final calculations and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_reg <= {PREC{1'b0}};
            valid_out_reg <= 1'b0;
        end else begin
            if (valid_stage3) begin
                code_reg <= low_stage3 + (range_div_stage3 * 256 - range_stage3);
                valid_out_reg <= valid_stage3;
            end else begin
                valid_out_reg <= 1'b0;
            end
        end
    end

endmodule