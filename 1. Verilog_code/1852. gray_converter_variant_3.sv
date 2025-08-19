//SystemVerilog
module gray_converter #(parameter WIDTH=4) (
    input clk,
    input rst_n,
    input [WIDTH-1:0] bin_in,
    input bin_to_gray,
    output reg [WIDTH-1:0] result
);

    // Pipeline stage 1: Input register
    reg [WIDTH-1:0] bin_in_reg;
    reg bin_to_gray_reg;
    
    // Pipeline stage 2: Conversion results
    reg [WIDTH-1:0] bin_to_gray_result_reg;
    reg [WIDTH-1:0] gray_to_bin_result_reg;
    
    // Pipeline stage 3: Output register
    reg [WIDTH-1:0] result_reg;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_in_reg <= {WIDTH{1'b0}};
            bin_to_gray_reg <= 1'b0;
        end else begin
            bin_in_reg <= bin_in;
            bin_to_gray_reg <= bin_to_gray;
        end
    end

    // Stage 2: Conversion logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_to_gray_result_reg <= {WIDTH{1'b0}};
            gray_to_bin_result_reg <= {WIDTH{1'b0}};
        end else begin
            // Binary to Gray conversion
            bin_to_gray_result_reg[0] <= bin_in_reg[0];
            for (int i = 1; i < WIDTH; i = i + 1) begin
                bin_to_gray_result_reg[i] <= bin_in_reg[i] ^ bin_in_reg[i-1];
            end

            // Gray to Binary conversion
            gray_to_bin_result_reg[WIDTH-1] <= bin_in_reg[WIDTH-1];
            for (int i = WIDTH-2; i >= 0; i = i - 1) begin
                gray_to_bin_result_reg[i] <= bin_in_reg[i] ^ gray_to_bin_result_reg[i+1];
            end
        end
    end

    // Stage 3: Output selection and registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= {WIDTH{1'b0}};
        end else begin
            result_reg <= bin_to_gray_reg ? bin_to_gray_result_reg : gray_to_bin_result_reg;
        end
    end

    // Output assignment
    assign result = result_reg;

endmodule